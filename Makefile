.PHONY:	all assets auth bundles check checks clean compiled coverage forceclean help image lint name publish realclean rubocop run server start stop tag test update vars version

ALPINE_VERSION?=3.22
BUNDLER_VERSION?=$(shell tail -1 Gemfile.lock | tr -d ' ')
RUBY_VERSION?=$(shell cat .ruby-version)
ACCOUNT?=$(shell aws sts get-caller-identity | jq -r .Account)
AWS_REGION?=eu-west-1
ECR?=${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
GPR_OWNER?=epimorphics
NAME?=$(shell awk -F: '$$1=="name" {print $$2}' deployment.yaml | sed -e 's/[[:blank:]]//g')
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)
PORT?=3001

SHORTNAME?=$(shell echo ${NAME} | cut -f2 -d/)
STAGE?=dev
API_SERVICE_URL?=http://localhost:8888
RAILS_RELATIVE_URL_ROOT?=/app/ppd
RUN_VARS?=-p

BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT=$(shell git rev-parse --short HEAD)
VERSION?=$(shell /usr/bin/env ruby -e 'require "./app/lib/version" ; puts Version::VERSION')
TAG?=$(shell printf '%s_%s_%08d' ${VERSION} ${COMMIT} ${GITHUB_RUN_NUMBER})

IMAGE?=${NAME}/${STAGE}
REPO?=${ECR}/${IMAGE}

BUNDLE_CFG=.bundle/config
BUNDLE=./bin/bundle
GITHUB_TOKEN=.github-token
RAILS=./bin/rails

${BUNDLE_CFG}: ${GITHUB_TOKEN}
	@${BUNDLE} config set --local rubygems.pkg.github.com ${GPR_OWNER}:`cat ${GITHUB_TOKEN}`

${GITHUB_TOKEN}:
	@echo ${PAT} > ${GITHUB_TOKEN}

all: image ## Default target: build the Docker image

assets: bundles compiled ## Compile assets for serving
	@echo assets completed.

auth: ${GITHUB_TOKEN} ${BUNDLE_CFG} ## Set up authentication for GitHub and Bundler
	@echo "Authentication set up for GitHub and Bundler."

bundles: ## Install Ruby gems via Bundler
	@echo "Installing Ruby gems via Bundler..."
	@${BUNDLE} install

check: checks ## Alias for `checks` target
	@echo "All checks passed."

checks: lint test ## Run all checks: linting and tests
	@echo "All checks passed."

clean: ## Clean up temporary and compiled files
	@echo "Cleaning up ${SHORTNAME} files..."
# Clean up the project
	@[ -d public/assets ] && ${RAILS} assets:clobber || :
# Clear cache files from tmp/
	@${RAILS} tmp:cache:clear
# Remove temporary files and directories
	@@ rm -rf bundle coverage log node_modules tmp

compiled: ## Compile assets for production
	@echo "Cleaning and precompiling static assets ..."
	@${RAILS} assets:clobber assets:precompile

forceclean: realclean ## Remove all bundled files
	@${BUNDLE} clean --force || :

help: ## Display this message
	@echo "Available make targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment variables (optional: all variables have defaults):"
	@make vars

image: auth ## Build the Docker image
	@echo Building ${REPO}:${TAG} ...
	@docker build \
		--build-arg ALPINE_VERSION=${ALPINE_VERSION} \
		--build-arg RUBY_VERSION=${RUBY_VERSION} \
		--build-arg BUNDLER_VERSION=${BUNDLER_VERSION} \
		--build-arg RAILS_RELATIVE_URL_ROOT=${RAILS_RELATIVE_URL_ROOT} \
		--build-arg VERSION=${VERSION} \
		--build-arg git_branch=${BRANCH} \
		--build-arg git_commit_hash=${COMMIT} \
		--build-arg github_run_number=${GITHUB_RUN_NUMBER} \
		--build-arg image_name=${NAME} \
		--tag ${REPO}:${TAG} \
		.
	@echo Done.

lint: rubocop ## Run linting checks
	@echo "All linting complete."

name: ## Display the shortname of the application
	@echo ${SHORTNAME}

publish: image ## Publish the Docker image to the registry
	@echo Publishing image: ${REPO}:${TAG} ...
	@docker tag ${NAME}:${TAG} ${REPO}:${TAG} 2>&1
	@docker push ${REPO}:${TAG} 2>&1
	@echo Done.

realclean: clean ## Remove all generated files and authentication
	@echo "Removing authentication from ${SHORTNAME}..."
	@rm -f ${GITHUB_TOKEN} ${BUNDLE_CFG}

rubocop: ## Run RuboCop linting
	@echo "Running RuboCop linting for ${SHORTNAME} ..."
# Auto-correct offenses safely where possible with the `-a` flag
	@${BUNDLE} exec rubocop -a

run: start ## Run the Docker container locally
	@if docker network inspect dnet > /dev/null 2>&1; then echo "Using docker network dnet"; else echo "Create docker network dnet"; docker network create dnet; sleep 2; fi
	@docker run ${RUN_VARS} ${PORT}:3000 --env API_SERVICE_URL=${API_SERVICE_URL} --network dnet --rm --name ${SHORTNAME} ${REPO}:${TAG}

server: start ## Run the Rails server locally
	@API_SERVICE_URL=${API_SERVICE_URL} ${RAILS} server -p ${PORT}

start: stop ## Start the application
	@echo "Starting ${SHORTNAME} pointing to ${API_SERVICE_URL} API ..."

stop: ## Stop the application
	@echo "Stopping ${SHORTNAME} ..."
	@docker stop ${SHORTNAME} > /dev/null 2>&1 || :

tag: ## Display the Docker image tag
	@echo ${TAG}

test: ## Run unit tests
	@echo "Running unit tests ..."
# Run Rails tests
	@${RAILS} test

update: ## Review and update dependencies interactively
	@echo "Checking for outdated dependencies..."
	@if [ -f package.json ]; then \
		echo "Running yarn upgrade-interactive..."; \
		yarn upgrade-interactive; \
	fi
	@echo "Running bundle outdated to check Ruby gems..."
	@bundle outdated --only-explicit

vars: ## Display environment variables
	@echo "Docker: ${REPO}:${TAG}"
	@echo "ACCOUNT = ${ACCOUNT}"
	@echo "ALPINE_VERSION = ${ALPINE_VERSION}"
	@echo "AWS_REGION = ${AWS_REGION}"
	@echo "BUNDLER_VERSION = ${BUNDLER_VERSION}"
	@echo "ECR = ${ECR}"
	@echo "GPR_OWNER = ${GPR_OWNER}"
	@echo "NAME = ${NAME}"
	@echo "RAILS_RELATIVE_URL_ROOT = ${RAILS_RELATIVE_URL_ROOT}"
	@echo "RUBY_VERSION = ${RUBY_VERSION}"
	@echo "SHORTNAME = ${SHORTNAME}"
	@echo "STAGE = ${STAGE}"
	@echo "COMMIT = ${COMMIT}"
	@echo "TAG = ${TAG}"
	@echo "VERSION = ${VERSION}"

version: ## Display the application version
	@echo ${VERSION}
