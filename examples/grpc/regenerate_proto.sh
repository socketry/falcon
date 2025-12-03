#!/bin/bash
# Regenerate the Ruby protobuf and gRPC service files

grpc_tools_ruby_protoc \
  --ruby_out=. \
  --grpc_out=. \
  --plugin=protoc-gen-grpc=$(which grpc_tools_ruby_protoc_plugin) \
  my_service.proto

echo "Generated:"
echo "  - my_service_pb.rb"
echo "  - my_service_services_pb.rb"





