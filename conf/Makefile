.PHONY: all

all: proto-go proto-swift proto-js

proto-go:
	protoc $< \
		--proto_path=${PWD}/apis \
		--plugin=/usr/local/bin/protoc-gen-gogo \
		--plugin=/usr/local/bin/protoc-gen-go-grpc \
		--go_opt=paths=source_relative \
		--go-grpc_opt=paths=source_relative \
		--go_out=${PWD}/apis/go \
		--go-grpc_out=${PWD}/apis/go \
		${PWD}/apis/*.proto

proto-swift:
	protoc $< \
		--proto_path=${PWD}/apis \
		--plugin=/usr/local/bin/protoc-gen-swift \
		--plugin=/usr/local/bin/protoc-gen-grpc-swift \
		--swift_opt=Visibility=Public \
		--grpc-swift_opt=Visibility=Public \
		--swift_out=${PWD}/apis/swift \
		--grpc-swift_out=${PWD}/apis/swift \
		${PWD}/apis/*.proto

proto-js:
	protoc $< \
		--proto_path=${PWD}/apis \
		--plugin=/usr/local/bin/protoc-gen-grpc-web \
		--js_out=import_style=commonjs:${PWD}/apis/js \
		--grpc-web_out=import_style=commonjs,mode=grpcwebtext:${PWD}/apis/js \
		${PWD}/apis/*.proto
