# Multi-stage build for OCTALUM-PULSE
# Build stage
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG VERSION=v2.0.0
ARG BUILD_TIME
ARG GIT_COMMIT

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w -X github.com/Harery/OCTALUM-PULSE/internal/version.Version=${VERSION} \
    -X github.com/Harery/OCTALUM-PULSE/internal/version.BuildTime=${BUILD_TIME} \
    -X github.com/Harery/OCTALUM-PULSE/internal/version.GitCommit=${GIT_COMMIT}" \
    -o pulse ./cmd/pulse

# Runtime stage
FROM alpine:3.20

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1000 pulse && \
    adduser -u 1000 -G pulse -s /bin/bash -D pulse

WORKDIR /app

COPY --from=builder /build/pulse /usr/local/bin/pulse
COPY --from=builder /build/deployments/docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/pulse

RUN mkdir -p /var/lib/pulse /var/log/pulse /var/cache/pulse && \
    chown -R pulse:pulse /var/lib/pulse /var/log/pulse /var/cache/pulse

USER pulse

ENV PULSE_LOG_LEVEL=info
ENV PULSE_CONFIG_DIR=/home/pulse/.config/pulse

ENTRYPOINT ["/entrypoint.sh"]
CMD ["doctor"]
