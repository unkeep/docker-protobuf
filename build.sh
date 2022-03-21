#!/usr/bin/env bash
docker build \
--build-arg ARCH="${ARCH:-"amd64"}" \
--build-arg ALPINE_VERSION="${ALPINE_VERSION:-"3.15"}" \
--build-arg GO_VERSION="${GO_VERSION:-"1.17.8"}" \
--build-arg GOOGLE_API_VERSION="d9b32e92fa57c37e5af0dc03badfe741170c5849" \
--build-arg GOTEMPLATE_VERSION="${GOTEMPLATE_VERSION:-"1.11.2"}" \
--build-arg GRPC_GATEWAY_VERSION="${GRPC_GATEWAY_VERSION:-"2.9.0"}" \
--build-arg GRPC_JAVA_VERSION="${GRPC_JAVA_VERSION:-"1.43.1"}" \
--build-arg GRPC_VERSION="${GRPC_VERSION:-"1.45.0"}" \
--build-arg GRPC_WEB_VERSION="${GRPC_WEB_VERSION:-"1.3.0"}" \
--build-arg JSONSCHEMA_VERSION="${JSONSCHEMA_VERSION:-"1.3.6"}" \
--build-arg NODE_VERSION="${NODE_VERSION:-"17.3.0"}" \
--build-arg PROTOBUF_C_VERSION="${PROTOBUF_C_VERSION:-"1.4.0"}" \
--build-arg PROTOC_GEN_DOC_VERSION="${PROTOC_GEN_DOC_VERSION:-"1.5.0"}" \
--build-arg PROTOC_GEN_GO_GRPC_VERSION="${PROTOC_GEN_GO_GRPC_VERSION:-"1.43.0"}" \
--build-arg PROTOC_GEN_GO_VERSION="${PROTOC_GEN_GO_VERSION:-"1.27.1"}" \
--build-arg PROTOC_GEN_GOGO_VERSION="${PROTOC_GEN_GOGO_VERSION:-"1.3.2"}" \
--build-arg PROTOC_GEN_GOVALIDATORS_VERSION="${PROTOC_GEN_GOVALIDATORS_VERSION:-"0.3.2"}" \
--build-arg PROTOC_GEN_GQL_VERSION="${PROTOC_GEN_GQL_VERSION:-"0.8.0"}" \
--build-arg PROTOC_GEN_LINT_VERSION="${PROTOC_GEN_LINT_VERSION:-"0.2.4"}" \
--build-arg PROTOC_GEN_VALIDATE_VERSION="${PROTOC_GEN_VALIDATE_VERSION:-"0.6.2"}" \
--build-arg TS_PROTOC_GEN_VERSION="${TS_PROTOC_GEN_VERSION:-"0.15.0"}" \
--build-arg UPX_VERSION="${UPX_VERSION:-"3.96"}" \
${@} .
