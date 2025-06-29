# Stage 1 (Build)
FROM golang:1.23.7-alpine AS builder

ARG VERSION
RUN apk add --update --no-cache git make
WORKDIR /app/
COPY go.mod go.sum /app/
RUN go mod download
COPY . /app/
RUN CGO_ENABLED=0 go build \
    -ldflags="-s -w -X github.com/IvanX77/turbowings/system.Version=$VERSION" \
    -v \
    -trimpath \
    -o turbowings \
    turbowings.go
RUN echo "ID=\"distroless\"" > /etc/os-release

# Stage 2 (Final)
FROM gcr.io/distroless/static:latest
COPY --from=builder /etc/os-release /etc/os-release

COPY --from=builder /app/turbowings /usr/bin/
CMD [ "/usr/bin/turbowings", "--config", "/etc/turbowings/config.yml" ]

EXPOSE 8080
