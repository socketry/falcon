# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/middleware"
require "protocol/http/body/file"
require "mime/types"
require "cgi"

module Falcon
	module Middleware
		# A HTTP middleware for serving static files and directory listings.
		class Static < Protocol::HTTP::Middleware
			# Default MIME types for common file extensions
			MIME_TYPES = {
				'.html' => 'text/html; charset=utf-8',
				'.htm' => 'text/html; charset=utf-8',
				'.css' => 'text/css',
				'.js' => 'application/javascript',
				'.json' => 'application/json',
				'.xml' => 'application/xml',
				'.txt' => 'text/plain',
				'.md' => 'text/markdown',
				'.png' => 'image/png',
				'.jpg' => 'image/jpeg',
				'.jpeg' => 'image/jpeg',
				'.gif' => 'image/gif',
				'.svg' => 'image/svg+xml',
				'.ico' => 'image/x-icon',
				'.pdf' => 'application/pdf',
				'.zip' => 'application/zip',
			}.freeze
			
			# Initialize the static file middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @parameter root [String] The root directory to serve files from.
			# @parameter index [String] The default index file for directories.
			# @parameter directory_listing [Boolean] Whether to show directory listings.
			def initialize(app, root: Dir.pwd, index: 'index.html', directory_listing: true)
				super(app)
				
				@root = File.expand_path(root)
				@index = index
				@directory_listing = directory_listing
			end
			
			# The root directory being served.
			# @attribute [String]
			attr :root
			
			# The default index file.
			# @attribute [String] 
			attr :index
			
			# Whether directory listings are enabled.
			# @attribute [Boolean]
			attr :directory_listing
			
			# Get the MIME type for a file extension.
			# @parameter extension [String] The file extension (including the dot).
			# @returns [String] The MIME type.
			def mime_type_for_extension(extension)
				MIME_TYPES[extension.downcase] || 'application/octet-stream'
			end
			
			# Resolve the file system path for a request path.
			# @parameter request_path [String] The HTTP request path.
			# @returns [String, nil] The file system path, or nil if invalid.
			def resolve_path(request_path)
				# Normalize the path and prevent directory traversal
				path = File.join(@root, request_path)
				real_path = File.realpath(path) rescue nil
				
				# Ensure the resolved path is within the root directory
				return nil unless real_path&.start_with?(@root)
				
				real_path
			end
			
			# Generate an HTML directory listing.
			# @parameter directory_path [String] The directory path.
			# @parameter request_path [String] The HTTP request path.
			# @returns [String] HTML content for the directory listing.
			def generate_directory_listing(directory_path, request_path)
				entries = Dir.entries(directory_path).sort
				
				# Remove current directory entry, but keep parent unless at root
				entries.reject! { |entry| entry == '.' }
				entries.reject! { |entry| entry == '..' } if request_path == '/'
				
				html = <<~HTML
					<!DOCTYPE html>
					<html lang="en">
					<head>
						<meta charset="UTF-8">
						<meta name="viewport" content="width=device-width, initial-scale=1.0">
						<title>Directory listing for #{CGI.escapeHTML(request_path)}</title>
						<style>
							body {
								font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
								max-width: 1000px;
								margin: 0 auto;
								padding: 20px;
								background-color: #f8f9fa;
								line-height: 1.6;
							}
							.container {
								background: white;
								border-radius: 8px;
								box-shadow: 0 2px 10px rgba(0,0,0,0.1);
								overflow: hidden;
							}
							.header {
								background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
								color: white;
								padding: 20px;
							}
							.header h1 {
								margin: 0;
								font-size: 24px;
							}
							.header .path {
								opacity: 0.9;
								font-size: 14px;
								margin-top: 5px;
							}
							.listing {
								padding: 0;
							}
							.entry {
								display: flex;
								align-items: center;
								padding: 12px 20px;
								border-bottom: 1px solid #eee;
								text-decoration: none;
								color: #333;
								transition: background-color 0.2s;
							}
							.entry:hover {
								background-color: #f8f9fa;
							}
							.entry:last-child {
								border-bottom: none;
							}
							.icon {
								margin-right: 12px;
								font-size: 18px;
								width: 20px;
								text-align: center;
							}
							.name {
								flex: 1;
								font-weight: 500;
							}
							.size {
								color: #666;
								font-size: 14px;
								min-width: 80px;
								text-align: right;
							}
							.footer {
								padding: 15px 20px;
								background: #f8f9fa;
								color: #666;
								font-size: 14px;
								text-align: center;
							}
						</style>
					</head>
					<body>
						<div class="container">
							<div class="header">
								<h1>📁 Directory Listing</h1>
								<div class="path">#{CGI.escapeHTML(request_path)}</div>
							</div>
							<div class="listing">
				HTML
				
				entries.each do |entry|
					entry_path = File.join(directory_path, entry)
					relative_path = File.join(request_path, entry)
					relative_path = relative_path[1..-1] if relative_path.start_with?('//')
					
					if File.directory?(entry_path)
						icon = entry == '..' ? '⬆️' : '📁'
						size = '-'
						href = entry == '..' ? File.dirname(request_path) : relative_path
						href += '/' unless href.end_with?('/')
					else
						icon = get_file_icon(entry)
						size = format_file_size(File.size(entry_path))
						href = relative_path
					end
					
					html += <<~HTML
						<a href="#{CGI.escapeHTML(href)}" class="entry">
							<span class="icon">#{icon}</span>
							<span class="name">#{CGI.escapeHTML(entry)}</span>
							<span class="size">#{size}</span>
						</a>
					HTML
				end
				
				html += <<~HTML
							</div>
							<div class="footer">
								Powered by Falcon Static Server
							</div>
						</div>
					</body>
					</html>
				HTML
				
				html
			end
			
			# Get an appropriate icon for a file based on its extension.
			# @parameter filename [String] The filename.
			# @returns [String] An emoji icon.
			def get_file_icon(filename)
				ext = File.extname(filename).downcase
				case ext
				when '.html', '.htm' then '🌐'
				when '.css' then '🎨'
				when '.js' then '⚡'
				when '.json' then '📋'
				when '.xml' then '📄'
				when '.txt', '.md' then '📝'
				when '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico' then '🖼️'
				when '.pdf' then '📕'
				when '.zip', '.tar', '.gz' then '📦'
				when '.rb' then '💎'
				when '.py' then '🐍'
				when '.java' then '☕'
				when '.cpp', '.c', '.h' then '⚙️'
				else '📄'
				end
			end
			
			# Format file size in human-readable format.
			# @parameter size [Integer] Size in bytes.
			# @returns [String] Formatted size string.
			def format_file_size(size)
				if size < 1024
					"#{size}B"
				elsif size < 1024 * 1024
					"#{(size / 1024.0).round(1)}KB"
				elsif size < 1024 * 1024 * 1024
					"#{(size / (1024.0 * 1024)).round(1)}MB"
				else
					"#{(size / (1024.0 * 1024 * 1024)).round(1)}GB"
				end
			end
			
			# Handle the HTTP request for static files.
			# @parameter request [Protocol::HTTP::Request]
			# @returns [Protocol::HTTP::Response]
			def call(request)
				# Only handle GET and HEAD requests
				return super unless request.method == 'GET' || request.method == 'HEAD'
				
				file_path = resolve_path(request.path)
				return super unless file_path
				
				if File.exist?(file_path)
					if File.directory?(file_path)
						# Try to serve index file first
						index_path = File.join(file_path, @index)
						if File.file?(index_path)
							return serve_file(index_path, request.method == 'HEAD')
						elsif @directory_listing
							return serve_directory_listing(file_path, request.path)
						else
							return super
						end
					elsif File.file?(file_path)
						return serve_file(file_path, request.method == 'HEAD')
					end
				end
				
				# File not found, pass to next middleware
				super
			end
			
			private
			
			# Serve a static file.
			# @parameter file_path [String] The file system path.
			# @parameter head_only [Boolean] Whether this is a HEAD request.
			# @returns [Protocol::HTTP::Response]
			def serve_file(file_path, head_only = false)
				stat = File.stat(file_path)
				extension = File.extname(file_path)
				content_type = mime_type_for_extension(extension)
				
				headers = [
					['content-type', content_type],
					['content-length', stat.size.to_s],
					['last-modified', stat.mtime.httpdate]
				]
				
				if head_only
					body = []
				else
					body = Protocol::HTTP::Body::File.open(file_path)
				end
				
				return Protocol::HTTP::Response[200, headers, body]
			end
			
			# Serve a directory listing.
			# @parameter directory_path [String] The directory path.
			# @parameter request_path [String] The HTTP request path.
			# @returns [Protocol::HTTP::Response]
			def serve_directory_listing(directory_path, request_path)
				html = generate_directory_listing(directory_path, request_path)
				
				headers = [
					['content-type', 'text/html; charset=utf-8'],
					['content-length', html.bytesize.to_s]
				]
				
				return Protocol::HTTP::Response[200, headers, [html]]
			end
		end
	end
end
