# sysmaint Docker Image
# Multi-distro Linux system maintenance
#
# Usage:
#   docker run --rm ghcr.io/harery/sysmaint --help
#   docker run --rm ghcr.io/harery/sysmaint --dry-run --json-summary
#
# For system maintenance (requires privileged access):
#   docker run --rm --privileged -v /:/host ghcr.io/harery/sysmaint --dry-run

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="sysmaint"
LABEL org.opencontainers.image.description="Multi-distro Linux system maintenance"
LABEL org.opencontainers.image.authors="Mohamed Elharery <Mohamed@Harery.com>"
LABEL org.opencontainers.image.url="https://github.com/Harery/SYSMAINT"
LABEL org.opencontainers.image.source="https://github.com/Harery/SYSMAINT"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="Harery"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bc \
    coreutils \
    apt-utils \
    systemd \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /opt/sysmaint

# Copy sysmaint and libraries
COPY sysmaint /opt/sysmaint/
COPY lib/ /opt/sysmaint/lib/

# Make executable
RUN chmod +x /opt/sysmaint/sysmaint

# Add to PATH
ENV PATH="/opt/sysmaint:${PATH}"

# Default to help
ENTRYPOINT ["sysmaint"]
CMD ["--help"]
