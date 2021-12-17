.PHONY:	all clean image publish tag test vars

ACCOUNT?=$(shell aws sts get-caller-identity | jq -r .Account)
STAGE?=dev
NAME?=$(shell awk -F: '$$1=="name" {print $$2}' deployment.yaml | sed -e 's/\s//g')
ECR?=${ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com
TAG?=$(shell if git describe > /dev/null 2>&1 ; then   git describe; else   git rev-parse --short HEAD; fi)

IMAGE?=${NAME}/${STAGE}
REPO?=${ECR}/${IMAGE}

all: publish

image:
	@echo Building ${REPO}:${TAG} ...
	@docker build --tag ${REPO}:${TAG} .
	@echo Done.

publish: test image
	@echo Publishing image: ${REPO}:${TAG} ...
	@docker push ${REPO}:${TAG} 2>&1
	@echo Done.

assets:
	@./bin/bundle install

run:
	@-docker stop ppd_explorer
	@-docker rm ppd_explorer && sleep 20
	@docker run -p 3000:3000 --rm --name ppd_explorer ${REPO}:${TAG}

tag:
	@echo ${TAG}

test: assets
	@./bin/bundle exec rubocop
	@./bin/bundle exec rails test

clean:
	@[ -d public/assets ] && ./bin/rails assets:clobber || :

vars:
	@echo "Docker: ${REPO}:${TAG}"
