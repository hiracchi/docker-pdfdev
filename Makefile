PACKAGE=hiracchi/pdf-builder
TAG=2020.6
CONTAINER_NAME=pdf-builder
PDF_BRANCH=develop

.PHONY: build start stop restart term logs

build:
	docker build -t "${PACKAGE}:${TAG}" . 2>&1 | tee docker-build.log


start:
	docker run -d \
		--rm \
		--name ${CONTAINER_NAME} \
		--publish "8888:8888" \
		--volume "${PWD}/work:/work" \
		"${PACKAGE}:${TAG}"


stop:
	docker rm -f ${CONTAINER_NAME}


restart: stop start


term:
	docker exec -it ${CONTAINER_NAME} /bin/bash


logs:
	docker logs ${CONTAINER_NAME}


pdf-check:
	docker exec -it ${CONTAINER_NAME} pdf-install.sh --branch master ProteinDF_bridge ProteinDF_pytools  QCLObot
	docker exec -it ${CONTAINER_NAME} pdf-install.sh --branch ${PDF_BRANCH} ProteinDF
	docker exec -it ${CONTAINER_NAME} pdf-check.sh --branch develop serial_dev
