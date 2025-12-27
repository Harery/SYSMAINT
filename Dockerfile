# SYSMAINT - Enterprise System Maintenance Toolkit
# Multi-distribution Linux container image
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# Official Images: ghcr.io/harery/sysmaint:latest
# Documentation: https://github.com/Harery/SYSMAINT/wiki

# Build Arguments
ARG BASE_IMAGE=ubuntu:24.04
ARG SYSMAINT_VERSION=1.0.0

FROM ${BASE_IMAGE}

# Metadata Labels (OCI-compliant)
LABEL org.opencontainers.image.title="SYSMAINT"
LABEL org.opencontainers.image.description="Enterprise-grade automated system maintenance toolkit for Linux"
LABEL org.opencontainers.image.version="${SYSMAINT_VERSION}"
LABEL org.opencontainers.image.vendor="Harery"
LABEL org.opencontainers.image.authors="Mohamed Elharery <Mohamed@Harery.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/Harery/SYSMAINT"
LABEL org.opencontainers.image.source="https://github.com/Harery/SYSMAINT"
LABEL org.opencontainers.image.documentation="https://github.com/Harery/SYSMAINT/wiki"
LABEL org.opencontainers.image.revision="${VCS_REF:-main}"
LABEL org.opencontainers.image.created="${BUILD_DATE:-2025-12-27}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}"
LABEL org.opencontainers.image.base.digest="${BASE_IMAGE_DIGEST}"

# Custom Labels
LABEL maintainer="Mohamed@Harery.com"
LABEL version="${SYSMAINT_VERSION}"
LABEL description="SYSMAINT v${SYSMAINT_VERSION} - Linux System Maintenance Toolkit"

# Environment Variables
ENV SYSMAINT_VERSION="${SYSMAINT_VERSION}"
ENV SYSMAINT_HOME="/opt/sysmaint"
ENV SYSMAINT_LOG_LEVEL="info"
ENV PATH="${SYSMAINT_HOME}:${PATH}"
ENV DEBIAN_FRONTEND=noninteractive

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD command -v sysmaint && sysmaint --version || exit 1

# Install Runtime Dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        bc \
        coreutils \
        curl \
        jq \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create Application Directory
WORKDIR ${SYSMAINT_HOME}

# Copy Application Files
COPY sysmaint ${SYSMAINT_HOME}/sysmaint
COPY lib/ ${SYSMAINT_HOME}/lib/

# Set executable permissions
RUN chmod +x ${SYSMAINT_HOME}/sysmaint && \
    chmod -R 755 ${SYSMAINT_HOME}/lib/

# Create Non-Root User (Security Best Practice)
RUN groupadd -r sysmaint && \
    useradd -r -g sysmaint -s /bin/bash -d ${SYSMAINT_HOME} sysmaint && \
    chown -R sysmaint:sysmaint ${SYSMAINT_HOME}

# Switch to Non-Root User
USER sysmaint

# Verify Installation
RUN sysmaint --version && \
    sysmaint --help

# Expose Custom Ports (if applicable)
# EXPOSE 8080

# Set Default Command
ENTRYPOINT ["sysmaint"]
CMD ["--help"]

# Image Metadata
# Build: docker build -t ghcr.io/harery/sysmaint:latest .
# Run:   docker run --rm ghcr.io/harery/sysmaint:latest --help
# Push:  docker push ghcr.io/harery/sysmaint:latest
