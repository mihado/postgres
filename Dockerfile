# Accept PostgreSQL version as build argument
ARG POSTGRES_VERSION=17

FROM postgres:${POSTGRES_VERSION}

# Install dependencies for .deb packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install the appropriate extension based on architecture
RUN --mount=type=bind,source=tmp,target=/tmp/extensions \
    set -e; \
    ARCH=$(dpkg --print-architecture); \
    echo "Detected architecture: $ARCH"; \
    DEB_FILES=$(find /tmp/extensions -name "*-${ARCH}-*.deb" -o -name "*_${ARCH}.deb"); \
    if [ -z "$DEB_FILES" ]; then \
        echo "No .deb files found for architecture: $ARCH"; \
        exit 1; \
    fi; \
    echo "Installing .deb files for $ARCH:"; \
    echo "$DEB_FILES"; \
    dpkg -i $DEB_FILES || true; \
    apt-get update && apt-get install -f -y; \
    rm -rf /var/lib/apt/lists/*
