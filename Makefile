GIT_HEAD = $(shell git rev-parse HEAD | head -c8)

build:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -gcflags "all=-trimpath=$(pwd)" -o build/wings_linux_amd64 -v turbowings.go
	GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -gcflags "all=-trimpath=$(pwd)" -o build/wings_linux_arm64 -v turbowings.go

test:
	go test -race ./...

debug:
	go build -ldflags="-X github.com/IvanX77/turbowings/system.Version=$(GIT_HEAD)"
	sudo ./turbowings --debug --ignore-certificate-errors --config config.yml --pprof --pprof-block-rate 1

# Runs a remotly debuggable session for TurboWings allowing an IDE to connect and target
# different breakpoints.
rmdebug:
	go build -gcflags "all=-N -l" -ldflags="-X github.com/IvanX77/turbowings/system.Version=$(GIT_HEAD)" -race
	sudo dlv --listen=:2345 --headless=true --api-version=2 --accept-multiclient exec ./turbowings -- --debug --ignore-certificate-errors --config config.yml

cross-build: clean build compress

clean:
	rm -rf build/wings_*

.PHONY: all build compress clean