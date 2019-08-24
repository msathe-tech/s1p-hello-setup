#!/usr/bin/env bash

echo "Enter project name [s1p-hello-service]: "
read project_name
project_name=${project_name:-s1p-hello-service}

fly -t w sp -p ${project_name} \
	--config ci/s1p-pipeline.yml \
	-l ci/config/s1p-common-config.yml \
	-l ci/creds/s1p-common-creds.yml \
	-l ci/config/${project_name}-config.yml