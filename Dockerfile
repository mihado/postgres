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
  echo "ARCH: $ARCH"; \
  DEB_FILES=$(find /tmp/extensions -name "*-${ARCH}-*.deb" -o -name "*_${ARCH}.deb"); \
  if [ -z "$DEB_FILES" ]; then \
    echo "ERROR: No .deb files found for architecture: $ARCH"; \
    exit 1; \
  fi; \
  echo "$DEB_FILES"; \
  apt-get install $DEB_FILES -y
