.PHONY:	image publish

STAGE?=dev
NAME?=$(shell awk -F: '$$1=="name" {print $$2}' deployment.yaml | sed -e 's/\s//g')
ECR?=018852084843.dkr.ecr.eu-west-1.amazonaws.com
TAG?=$(shell if git describe > /dev/null 2>&1 ; then   git describe; else   git rev-parse --short HEAD; fi)

IMAGE?=${NAME}/${STAGE}
REPO?=${ECR}/${IMAGE}

all: publish

image: assets
	@echo Building ${REPO}:${TAG} ...
	@docker build --tag ${REPO}:${TAG} .
	@echo Done.

publish: image
	@echo Publishing image: ${REPO}:${TAG} ...
	@docker push ${REPO}:${TAG} 2>&1
	@echo Done.

assets:
	@bundler exec bundle config set --local without 'development'
	@bundler exec bundle install
	@bundler exec ./bin/rails assets:clean assets:precompile

run:
	@-docker stop ppd_explorer
	@-docker rm ppd_explorer && sleep 20
	@docker run -p 3000:3000 --rm --name ppd_explorer -e RAILS_RELATIVE_URL_ROOT='' ${REPO}:${TAG}

tag:
	@echo ${TAG}

test: assets
	@bundler exec ./bin/rake test

clean:
	@bundler exec ./bin/rails assets:clobber

vars:
	@echo "Docker: ${REPO}:${TAG}"
