# Variables with defaults
VERSION ?= v0.2.0
POSTGRES ?= 17
IMAGE_NAME ?= mihado/postgres
IMAGE_TAG ?= $(POSTGRES)
CACHE ?= true

# Base URL for downloads
BASE_URL = https://github.com/pksunkara/pgx_ulid/releases/download/$(VERSION)

# Target directory
TMP_DIR = ./tmp

tmp:
	mkdir -p $(TMP_DIR)

clean:
	@rm -rf $(TMP_DIR)
	@echo "Cleaned $(TMP_DIR)/"

# Download both amd64 and arm64 extensions
deps: tmp
	@echo "Downloading pgx_ulid extensions..."
	@echo "Version: $(VERSION)"
	@echo "Postgres: $(POSTGRES)"
	@echo "Downloading amd64 extension..."
	@curl -L -o $(TMP_DIR)/pgx_ulid-$(VERSION)-pg$(POSTGRES)-amd64-linux-gnu.deb \
		$(BASE_URL)/pgx_ulid-$(VERSION)-pg$(POSTGRES)-amd64-linux-gnu.deb
	@echo "Downloading arm64 extension..."
	@curl -L -o $(TMP_DIR)/pgx_ulid-$(VERSION)-pg$(POSTGRES)-arm64-linux-gnu.deb \
		$(BASE_URL)/pgx_ulid-$(VERSION)-pg$(POSTGRES)-arm64-linux-gnu.deb
	@echo "Downloads completed to $(TMP_DIR)/"

# Build for local architecture (auto-detected)
build: setup-buildx deps
	@echo "Building Docker image for local architecture..."
	@echo "Image: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "PostgreSQL version: $(POSTGRES)"
	@ARCH=$$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/'); \
	if [ "$$ARCH" = "arm64" ]; then PLATFORM="linux/arm64/v8"; else PLATFORM="linux/$$ARCH"; fi; \
	echo "Detected platform: $$PLATFORM"; \
	CACHE_FLAG=""; \
	if [ "$(CACHE)" = "false" ]; then CACHE_FLAG="--no-cache"; fi; \
	docker buildx build --progress=plain $$CACHE_FLAG --platform $$PLATFORM \
		--build-arg POSTGRES_VERSION=$(POSTGRES) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(IMAGE_NAME):latest \
		--load .

# Build multiarch image then push to registry
push: setup-buildx deps
	@echo "Build & push multi-architecture image to registry..."
	@echo "Image: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "PostgreSQL version: $(POSTGRES)"
	@docker buildx build --platform linux/amd64,linux/arm64/v8 \
		--build-arg POSTGRES_VERSION=$(POSTGRES) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(IMAGE_NAME):latest \
		--push .

# Create and use buildx builder if not exists
setup-buildx:
	@echo "Setting up Docker buildx..."
	@docker buildx create --name multiarch --use --bootstrap 2>/dev/null || \
		docker buildx use multiarch 2>/dev/null || \
		echo "Buildx already configured"

config:
	@echo "Current configuration:"
	@echo "  VERSION: $(VERSION)"
	@echo "  POSTGRES: $(POSTGRES)"
	@echo "  IMAGE_NAME: $(IMAGE_NAME)"
	@echo "  IMAGE_TAG: $(IMAGE_TAG)"
	@echo "  CACHE: $(CACHE)"
	@echo "  TMP_DIR: $(TMP_DIR)"

.PHONY: deps clean build push setup-buildx config
