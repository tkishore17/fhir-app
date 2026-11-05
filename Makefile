# ========================================================================================
# CONFIGURATION VARIABLES
# ================================================================================
PROJECT_NAME		:= fhir-gateway
LOCAL_PORT			:- 8000
DOCKER_FILE_PATH	:= build-config/Dockerfile

# ========================================================================================
# GOOGLE PLATFORM CONFIGURATIONS
# ================================================================================
GCP_REGION			:= us-central1
GCP_PROJECT_ID		:= $(shell gcloud config get-value project 2>/dev/null)
GAR_REPO_NAME		:= image-registry

# ========================================================================================
# DERIVED IMAGE TAGS
# ================================================================================
IMAGE_NAME			:= $(PROJECT_NAME)
GAR_IMAGE_TAG		:= $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/$(GAR_REPO_NAME)/$(IMAGE_NAME)
VERSION				:= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")

# ========================================================================================
# COLORS FOR TERMINAL STYLING
# ================================================================================
COLOR_RESET			:= \033[0m
COLOR_GREEN			:= \033[32m
COLOR_YELLOW		:= \033[33m

.PHONY:	help build build-dev run run-dev auth push all

help:
	@echo "${COLOR_YELLOW}FHIR Service Container Pipeline Automation${COLOR_RESET}"
	@echo "Available Commands:"
	@echo "	make build              - Compiles hardened production image (Distroless)"
	@echo "	make build-dev          - Build local development image(with bash shell)"
	@echo "	make run                - Run the production image locally on port ${LOCAL_PORT}"
	@echo "	make run-dev            - Run the  dev image with an interactive shell entry"
	@echo "	make auth               - Authenticate local Docker with GCP Artiface Registry"
	@echo "	make push               - Tag and push the production image to GCP"
	@echo "	make all                - Run auth, build,  and push in sequence"

# 1. Hardened Production Image (Defaults to Distroless)
build:
	@echo "${COLOR_GREEN}Building production image (Distroless)...$(COLOR_RESET)"
	docker build \
		-f $(DOCKER_FILE_PATH) \
		-t $(IMAGE_NAME):latest \
		-t $(IMAGE_NAME):$(VERSION) .

# 2. Debuggable Development Image (Overwriting to python:3.11-slim)
build-dev:
	@echo "${COLOR_GREEN}Building development image (with bash shell)...${COLOR_RESET}"
	docker build \
		--build-arg RUNTIME_BASE="python:3.11-slim" \
		-f $(DOCKER_FILE_PATH) \
		-t $(IMAGE_NAME):dev .

run: build
	@echo "${COLOR_GREEN}Rundding production container on port ${LOCAL_PORT}...${COLOR_RESET}"
	docker run -rm -p $(LOCAL_PORT):$(LOCAL_PORT) $(IMAGE_NAME):latest

run-dev: build-dev
	@echo "$(COLOR_GREEN)Dropping into development container shell...$(COLOR_RESET)"
	docker run --rm -it -p $(LOCAL_PORT):$(LOCAL_PORT) $(IMAGE_NAME):dev /bin/bash


# ========================================================================================================
# GOOOGLE ARTIFACE REGISTRY PIPELINE
# ========================================================================================================

# Authenticate local docker daemon against your specific GCP region
auth:
	@echo "${COLOR_GREEN}Authenticating DOcker with GCP Artifcat Registry....${COLOR_RESET}"
	gcloud auth configure-docker $(GCP_REGION)-docker.pkg.dev


# Tage the local 'latest' build with ful GAR remote URI and pushes it
push: build
	@echo "${COLOR_GREEN} Tagging and pushing image to Google Artifact Registry...${COLOR_RESET}"
	docker tag $(IMAGE_NAME):latest $(GAR_IMAGE_TAG):latest
	docker tag $(IMAGE_NAME):latest $(GAR_IMAGE_TAG):$(VERSION)
	docker push $(GAR_IMAGE_TAG):latest
	docker push $(GAR_IMAGE_TAG):$(VERSION)
	@echo "${COLOR_YELLOW}Image is ready for GKE! Image URI: ${GAR_IMAGE_TAG}:${VERSION}${COLOR_RESET}"

push-dev: build-dev
	@echo "${COLOR_GREEN} Tagging and pushing dev image to Google Artifact Registry...${COLOR_RESET}"
	docker tag $(IMAGE_NAME):dev $(GAR_IMAGE_TAG):latest
	#docker tag $(IMAGE_NAME):latest $(GAR_IMAGE_TAG):$(VERSION)
	docker push $(GAR_IMAGE_TAG):latest
	#docker push $(GAR_IMAGE_TAG):$(VERSION)
	@echo "${COLOR_YELLOW}Image is ready for GKE! Image URI: ${GAR_IMAGE_TAG}:latest${COLOR_RESET}"

all: auth push
