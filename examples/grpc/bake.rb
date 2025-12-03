# frozen_string_literal: true

def build
	system("grpc_tools_ruby_protoc", "--ruby_out=.", "--grpc_out=.", "--proto_path=.", "my_service.proto")
end