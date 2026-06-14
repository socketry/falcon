#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "process/metrics"

PRELOAD_SIZE = Integer(ENV.fetch("PRELOAD_MB", 256)) * 1024 * 1024
WORKER_COUNT = Integer(ENV.fetch("WORKERS", 3))
PRIVATE_SIZE = Integer(ENV.fetch("PRIVATE_MB", 0)) * 1024 * 1024
PAGE_SIZE = 4096

Child = Struct.new(:name, :process_id, keyword_init: true)

def allocate_preload(size)
	chunks = []
	remaining = size
	
	while remaining > 0
		chunk_size = [remaining, 1024 * 1024].min
		chunks << "x" * chunk_size
		remaining -= chunk_size
	end
	
	chunks
end

def dirty_pages(chunks, size)
	remaining = size
	
	chunks.each do |chunk|
		offset = 0
		
		while offset < chunk.bytesize && remaining > 0
			chunk.setbyte(offset, (chunk.getbyte(offset) + 1) & 0xff)
			offset += PAGE_SIZE
			remaining -= PAGE_SIZE
		end
		
		break if remaining <= 0
	end
end

def fork_child(name, preload, private_size: 0)
	read, write = IO.pipe
	
	process_id = fork do
		read.close
		dirty_pages(preload, private_size) if private_size > 0
		write.write("1")
		write.close
		
		sleep
	end
	
	write.close
	read.read(1)
	
	Child.new(name: name, process_id: process_id)
end

def format_size(value)
	return "-" unless value
	
	units = ["B", "KiB", "MiB", "GiB"]
	size = value.to_f
	unit = units.first
	
	units.each do |candidate|
		unit = candidate
		break if size < 1024 || candidate == units.last
		
		size /= 1024
	end
	
	"%0.1f%s" % [size, unit]
end

def memory_size(memory, *fields)
	return unless memory
	
	fields.sum do |field|
		memory.public_send(field) || 0
	end
end

def resident_size(general)
	general.memory&.resident_size || general.resident_size
end

def summarize(metrics)
	metrics.values.each_with_object({rss: 0, pss: 0, shared: 0, private: 0}) do |general, totals|
		memory = general.memory
		
		totals[:rss] += resident_size(general) || 0
		totals[:pss] += memory&.proportional_size || 0
		totals[:shared] += memory_size(memory, :shared_clean_size, :shared_dirty_size) || 0
		totals[:private] += memory_size(memory, :private_clean_size, :private_dirty_size) || 0
	end
end

def capture_processes(process_ids)
	process_ids.each_with_object({}) do |process_id, metrics|
		metrics.merge!(Process::Metrics::General.capture(pid: process_id))
	end
end

preload = allocate_preload(PRELOAD_SIZE)

children = [
	fork_child("supervisor", preload)
]

WORKER_COUNT.times do |index|
	children << fork_child("worker-#{index + 1}", preload, private_size: PRIVATE_SIZE)
end

begin
	process_ids = [Process.pid, *children.map(&:process_id)]
	metrics = capture_processes(process_ids)
	
	puts "preloaded: #{format_size(PRELOAD_SIZE)}, workers: #{WORKER_COUNT}, private per worker: #{format_size(PRIVATE_SIZE)}"
	puts
	
	printf("%-12s %8s %10s %10s %10s %10s %s\n", "role", "pid", "rss", "pss", "shared", "private", "command")
	
	[Child.new(name: "master", process_id: Process.pid), *children].each do |child|
		general = metrics.fetch(child.process_id)
		memory = general.memory
		
		printf(
			"%-12s %8d %10s %10s %10s %10s %s\n",
			child.name,
			child.process_id,
			format_size(resident_size(general)),
			format_size(memory&.proportional_size),
			format_size(memory_size(memory, :shared_clean_size, :shared_dirty_size)),
			format_size(memory_size(memory, :private_clean_size, :private_dirty_size)),
			general.command
		)
	end
	
	totals = summarize(metrics)
	
	puts
	puts "summed rss:     #{format_size(totals[:rss])}"
	puts "summed pss:     #{format_size(totals[:pss])}"
	puts "summed shared:  #{format_size(totals[:shared])}"
	puts "summed private: #{format_size(totals[:private])}"
ensure
	children.each do |child|
		Process.kill(:TERM, child.process_id)
	rescue Errno::ESRCH
	end
	
	children.each do |child|
		Process.wait(child.process_id)
	rescue Errno::ECHILD
	end
end
