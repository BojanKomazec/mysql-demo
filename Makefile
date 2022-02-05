DOCKER_IMAGE_NAME := bojankomazec/mysqlsh
APP_NAME := mysqlsh-demo

build:
	docker image rm $(DOCKER_IMAGE_NAME) || (echo "Image $(DOCKER_IMAGE_NAME) didn't exist so not removed."; exit 0)
	docker build --build-arg APP_NAME=$(APP_NAME) -t $(DOCKER_IMAGE_NAME) .
run:
#   Usage: make run MYSQL_DB_HOST=127.0.0.1 MYSQL_DB_PORT=3307 SQL_FILE=Northwind.MySQL8-0-27.sql
	docker run \
		-e MYSQL_DB_HOST=$(MYSQL_DB_HOST) \
		-e MYSQL_DB_PORT=$(MYSQL_DB_PORT) \
		-e SQL_FILE=$(SQL_FILE) \
		-v "$(shell pwd)"/shared/out/:/usr/src/$(APP_NAME)/out/ \
		-v "$(shell pwd)"/shared/in/:/usr/src/$(APP_NAME)/in/ \
		--rm \
		--name $(APP_NAME) \
		$(DOCKER_IMAGE_NAME)
