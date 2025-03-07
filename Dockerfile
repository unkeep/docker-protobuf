ARG ALPINE_VERSION
ARG GO_VERSION
ARG NODE_VERSION
ARG GOTEMPLATE_VERSION

FROM alpine:${ALPINE_VERSION} as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev linux-headers cmake ninja

RUN mkdir -p /out

ARG GRPC_VERSION
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf && \
    mkdir -p /grpc/cmake/build && \
    cd /grpc/cmake/build && \
    cmake \
        -GNinja \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        ../.. && \
    cmake --build . --target plugins && \
    cmake --build . --target install && \
    DESTDIR=/out cmake --build . --target install

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c && \
    curl -sSL https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xz --strip 1 -C /protobuf-c && \
    cd /protobuf-c && \
    export LD_LIBRARY_PATH=/usr/lib:/usr/lib64 && \
    export PKG_CONFIG_PATH=/usr/lib64/pkgconfig && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install DESTDIR=/out

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz --strip 1 -C /grpc-java && \
    cd /grpc-java && \
    g++ \
        -I. -I/usr/include \
        compiler/src/java_plugin/cpp/*.cpp \
        -L/usr/lib64 \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java && \
    install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java

ARG GRPC_WEB_VERSION
RUN mkdir -p /grpc-web && \
    curl -sSL https://api.github.com/repos/grpc/grpc-web/tarball/${GRPC_WEB_VERSION} | tar xz --strip 1 -C /grpc-web && \
    cd /grpc-web && \
    make install-plugin && \
    install -Ds /usr/local/bin/protoc-gen-grpc-web /out/usr/bin/protoc-gen-grpc-web


FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc && \
    install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go && \
    curl -sSL https://api.github.com/repos/grpc/grpc-go/tarball/v${PROTOC_GEN_GO_GRPC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go &&\
    cd ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go-grpc . && \
    install -Ds /golang-protobuf-out/protoc-gen-go-grpc /out/usr/bin/protoc-gen-go-grpc

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/google.golang.org/protobuf && \
    curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-go/tarball/v${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/google.golang.org/protobuf &&\
    cd ${GOPATH}/src/google.golang.org/protobuf && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./cmd/protoc-gen-go && \
    install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GOGO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/gogo/protobuf && \
    curl -sSL https://api.github.com/repos/gogo/protobuf/tarball/v${PROTOC_GEN_GOGO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/gogo/protobuf &&\
    cd ${GOPATH}/src/github.com/gogo/protobuf && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gofast ./protoc-gen-gofast && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogo ./protoc-gen-gogo && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofast ./protoc-gen-gogofast && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofaster ./protoc-gen-gogofaster && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogoslick ./protoc-gen-gogoslick && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogotypes ./protoc-gen-gogotypes && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gostring ./protoc-gen-gostring && \
    install -D $(find /gogo-protobuf-out -name 'protoc-gen-*') -t /out/usr/bin && \
    mkdir -p /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D $(find ./protobuf/google/protobuf -name '*.proto') -t /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D ./gogoproto/gogo.proto /out/usr/include/github.com/gogo/protobuf/gogoproto/gogo.proto

ARG PROTOC_GEN_GOVALIDATORS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    curl -sSL https://api.github.com/repos/mwitkow/go-proto-validators/tarball/v${PROTOC_GEN_GOVALIDATORS_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    cd ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    mkdir /go-proto-validators-out && \
    go build -ldflags '-w -s' -o /go-proto-validators-out ./... && \
    install -Ds /go-proto-validators-out/protoc-gen-govalidators /out/usr/bin/protoc-gen-govalidators && \
    install -D ./validator.proto /out/usr/include/github.com/mwitkow/go-proto-validators/validator.proto

ARG PROTOC_GEN_GQL_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/danielvladco/go-proto-gql && \
    curl -sSL https://api.github.com/repos/danielvladco/go-proto-gql/tarball/v${PROTOC_GEN_GQL_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/danielvladco/go-proto-gql && \
    cd ${GOPATH}/src/github.com/danielvladco/go-proto-gql && \
    go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gql ./protoc-gen-gql && \
    go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gogql ./protoc-gen-gogql && \
    install -Ds /go-proto-gql-out/protoc-gen-gql /out/usr/bin/protoc-gen-gql && \
    install -Ds /go-proto-gql-out/protoc-gen-gogql /out/usr/bin/protoc-gen-gogql

ARG PROTOC_GEN_LINT_VERSION
ARG ARCH
RUN cd / && \
    curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_${ARCH}.zip && \
    mkdir -p /protoc-gen-lint-out && \
    cd /protoc-gen-lint-out && \
    unzip -q /protoc-gen-lint_linux_${ARCH}.zip && \
install -D /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    curl -sSL https://api.github.com/repos/envoyproxy/protoc-gen-validate/tarball/v${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . && \
    install -Ds /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate && \
    install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-openapiv2 ./protoc-gen-openapiv2 && \
    install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway && \
    install -Ds /grpc-gateway-out/protoc-gen-openapiv2 /out/usr/bin/protoc-gen-openapiv2 && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options

ARG GOOGLE_API_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/googleapis/googleapis && \
    curl -sSL https://api.github.com/repos/googleapis/googleapis/tarball/${GOOGLE_API_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/googleapis/googleapis && \
    cd ${GOPATH}/src/github.com/googleapis/googleapis && \
    install -D ./google/api/annotations.proto /out/usr/include/google/api/annotations.proto && \
    install -D ./google/api/field_behavior.proto /out/usr/include/google/api/field_behavior.proto && \
    install -D ./google/api/http.proto /out/usr/include/google/api/http.proto && \
    install -D ./google/api/httpbody.proto /out/usr/include/google/api/httpbody.proto

ARG JSONSCHEMA_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema && \
    curl -sSL https://api.github.com/repos/chrusty/protoc-gen-jsonschema/tarball/${JSONSCHEMA_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema && \
    cd ${GOPATH}/src/github.com/chrusty/protoc-gen-jsonschema && \
    pwd && ls -la && \
    go build -ldflags '-w -s' -o /protoc-gen-jsonschema/protoc-gen-jsonschema ./cmd/protoc-gen-jsonschema && \
    install -Ds /protoc-gen-jsonschema/protoc-gen-jsonschema /out/usr/bin/protoc-gen-jsonschema && \
    install -D ./options.proto /out/usr/include/github.com/chrusty/protoc-gen-jsonschema/options.proto


RUN apk add --no-cache curl patchelf

# RUN apt-get update
# RUN apt-get install -y patchelf libnghttp2-dev libssl-dev zlib1g-dev

# RUN apt-get install -y musl-tools

FROM moul/protoc-gen-gotemplate:v${GOTEMPLATE_VERSION} as protoc_gotemplate

FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl

ARG UPX_VERSION
ARG ARCH
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${ARCH}_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

COPY --from=protoc_builder /out/ /out/
COPY --from=go_builder /out/ /out/
COPY --from=protoc_gotemplate /go/bin/protoc-gen-gotemplate /out/usr/bin/
RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'grpc_*' \
        -not -name 'grpc_csharp_plugin' \
        -not -name 'grpc_node_plugin' \
        -not -name 'grpc_php_plugin' \
        -not -name 'grpc_ruby_plugin' \
        -not -name 'grpc_python_plugin' \
        -or -name 'protoc-gen-*' \
    )
RUN find /out -name "*.a" -delete -or -name "*.la" -delete


FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}

ARG TS_PROTOC_GEN_VERSION
LABEL maintainer="Roman Volosatovs <rvolosatovs@riseup.net>"
COPY --from=packer /out/ /
RUN npm install -g ts-protoc-gen@${TS_PROTOC_GEN_VERSION} && npm cache clean --force
RUN apk add --no-cache bash libstdc++ && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
    apk add glibc-2.31-r0.apk && \
    ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp && \
    ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp && \
    ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/protoc-gen-grpc-objc && \
    ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js && \
    ln -s /usr/bin/grpc_php_plugin /usr/bin/protoc-gen-grpc-php && \
    ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python && \
    ln -s /usr/bin/grpc_ruby_plugin /usr/bin/protoc-gen-grpc-ruby && \
    ln -s /usr/local/lib/node_modules/ts-protoc-gen/bin/protoc-gen-ts /usr/bin/protoc-gen-ts
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENV LD_LIBRARY_PATH='/usr/lib:/usr/lib64:/usr/lib/local'
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
