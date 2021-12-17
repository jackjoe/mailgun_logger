TIMESTAMP               =`date +%s`
BRANCH                  =$(shell git rev-parse --abbrev-ref HEAD)
GIT_SHA                 =$(shell git rev-parse HEAD)
GIT_SHA_SHORT           =$(shell git rev-parse --short=7 HEAD)
BASE_DIR 								=$(shell pwd)
CURR_USER 							=$(shell whoami)

APP_NAME 								?=`grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN 								?=`grep 'version:' mix.exs | cut -d '"' -f2`
BUILD 									?=`git rev-parse --short HEAD`
DOCKER_IMAGE           	="jackjoe/mailgun_logger"

.SILENT: ;               		# no need for @
.ONESHELL: ;             		# recipes execute in same shell
.NOTPARALLEL: ;          		# wait for this target to finish
.EXPORT_ALL_VARIABLES: ; 		# send all vars to shell
.SHELLFLAGS = -c
.DEFAULT_GOAL := build_and_run
Makefile: ;              		# skip prerequisite discovery

.PHONY: run test

install:
	./script/setup

run:
	./script/run

test: test_coverage

test_elixir:
	echo "export ML_DB_USER=user && MIX_ENV=test mix test"
	export ML_DB_USER=user && MIX_ENV=test mix test

test_coverage:
	echo "export ML_DB_USER=user && MIX_ENV=test mix coveralls"
	export ML_DB_USER=user && MIX_ENV=test mix coveralls

#######################################
# Docker

docker_build_prod:
	docker build --compress \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg BUILD_ENV=prod \
		-t $(DOCKER_IMAGE):$(APP_VSN)-$(BUILD) \
		-t $(DOCKER_IMAGE):latest \
		-t $(DOCKER_IMAGE):prod-latest .

_docker_push_version:
	docker push $(DOCKER_IMAGE):$(APP_VSN)-$(BUILD)

docker_push_prod: _docker_push_version
	docker push $(DOCKER_IMAGE):prod-latest

docker_run_local:
	docker run \
		-p 5050:5050 \
		--rm \
		-it $(DOCKER_IMAGE):latest
