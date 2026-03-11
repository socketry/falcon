# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

def build
	system("grpc_tools_ruby_protoc", "--ruby_out=.", "--grpc_out=.", "--proto_path=.", "my_service.proto")
end
