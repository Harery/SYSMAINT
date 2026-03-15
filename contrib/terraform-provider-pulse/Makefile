.PHONY: build install test clean fmt lint docs

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BINARY := terraform-provider-pulse

build:
	go build -o $(BINARY) .

install: build
	mkdir -p ~/.terraform.d/plugins/registry.terraform.io/harery/pulse/$(VERSION)/$(shell go env GOOS)_$(shell go env GOARCH)
	mv $(BINARY) ~/.terraform.d/plugins/registry.terraform.io/harery/pulse/$(VERSION)/$(shell go env GOOS)_$(shell go env GOARCH)/

test:
	go test -v ./...

testacc:
	TF_ACC=1 go test -v ./...

clean:
	rm -f $(BINARY)

fmt:
	go fmt ./...

lint:
	golangci-lint run ./...

docs:
	go generate ./...

.PHONY: release
release: clean build
	GOOS=linux GOARCH=amd64 go build -o $(BINARY)_linux_amd64 .
	GOOS=linux GOARCH=arm64 go build -o $(BINARY)_linux_arm64 .
	GOOS=darwin GOARCH=amd64 go build -o $(BINARY)_darwin_amd64 .
	GOOS=darwin GOARCH=arm64 go build -o $(BINARY)_darwin_arm64 .
	GOOS=windows GOARCH=amd64 go build -o $(BINARY)_windows_amd64.exe .
