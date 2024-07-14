# frozen_string_literal: true

# https://tmr08c.github.io/2020/05/concurrent-ruby-hello-async/
#
require 'async'

class Pool
  def initialize(size:, workers:)
    @size = size
    @workers = workers
    @running = []
    @waiting = []
    @mutex = Mutex.new
    watch
  end

  def push(path)
    body = Async::HTTP::Body::Writable.new
    if @waiting.size >= @size
      puts "pushback"
      body.close
      [429, {}, body]
    else
      Async do |a_task|
        task = Task.new(a_task, body, annotation: path)
        @mutex.synchronize do
          @waiting << task
          puts "Pushed: waiting: #{@waiting.size} running: #{@running.size}"
        end
        task.wait_for_worker # after this call we're in a yield loop until we're contined by the scheduler
      end
      [200, {}, body]
    end
  end

  private

  def schedule
    @mutex.synchronize do
      @running = @running.reject(&:finished?)
      available = (@workers - @running.size)
      waiting = @waiting.size
      fill = [waiting, available].min
      if fill.positive?
        puts "Filling: #{waiting} available: #{available} fill: #{fill}"
        fill.times do
          task = @waiting.shift
          @running << task
          task.continue
        end
      end
    end
  end

  def watch
    Thread.new do
      loop do
        sleep 0.1
        #        puts "Pool: #{@running.size} #{@waiting.size}"
        schedule
      end
    end
  end
end

class Task
  def initialize(task, body, annotation:)
    @task = task
    @body = body
    @fiber = Fiber.current
    @annotation = annotation
    @wait = true
    @timings = {}
  end

  def step(comment)
    @timings[comment] = Time.now
    puts "#{comment}: #{@annotation}"
  end

  def work
    step 'working'
    sleep 5
    @body.write "(#{Time.now}) Hello World #{Process.pid} #{@task}\n"
  ensure
    finish
  end

  def finished?
    @task.finished?
  end

  def wait_for_worker
    step('waiting')
    Fiber.scheduler.yield while @wait
    work
    #    @fiber.yield
    #    @task.yield
  end

  def continue
    step('continue')
    @wait = false
  end

  def finish
    step('finish')
    @body.close
    print_timings
  end

  def pushback
    step('finish')
    @body.close
  end

  def print_timings
    puts "Timings: Queued for #{timings_diff('waiting', 'working')}, Running: #{timings_diff('working', 'finish')}"
  end

  def timings_diff(start, stop)
    @timings[stop] - @timings[start]
  end
end

pool = Pool.new(size: 15, workers: 10)

run do |env|
  request = env['protocol.http.request']
  path = request.path
  pool.push(path) # returns [code, {}, body]
end
