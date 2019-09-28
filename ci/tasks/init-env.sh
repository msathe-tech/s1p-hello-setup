#!/bin/bash

echo -e "\n\n########## ---------- Cloud Pipelines and Extensions Environment Setup [START] ---------- ##########"

echo -e "\n\n########## Set up Cloud Pipelines ##########"
export WORKSPACE=`pwd`

cd "${WORKSPACE}/ci-cloud-pipelines"
tar xf scripts.tar.gz --strip-components 1
cd "${WORKSPACE}"

export ENVIRONMENT=BUILD
export CI=CONCOURSE
export PAAS_TYPE=k8s
export BUILD_OPTIONS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"

cd "${WORKSPACE}/code-repo"
source "${WORKSPACE}"/ci-cloud-pipelines/src/main/bash/pipeline.sh

echo -e "\n\n########## Set up Cloud Pipelines extensions ##########"
export WORKSPACE_EXT="${WORKSPACE}/${TASKS}"
echo "WORKSPACE_EXT=${WORKSPACE_EXT}"
export NUM_SOURCED_EXT_FILES=0
source "${WORKSPACE_EXT}"/pipeline.sh
source "${WORKSPACE_EXT}"/projectType/pipeline-maven.sh
echo "NUM_SOURCED_EXT_FILES=${NUM_SOURCED_EXT_FILES}"

echo -e "\n\n########## Set up common project environment ##########"
cd "${WORKSPACE}/code-repo"
export PROJECT_GROUP="$(extractMavenProperty "project.groupId")"
export PROJECT_NAME="$(extractMavenProperty "project.artifactId")"
export PROJECT_VERSION="$(extractMavenProperty "project.version")"
echo "PROJECT_GROUP=[${PROJECT_GROUP}]"
echo "PROJECT_NAME=[${PROJECT_NAME}]"
echo "PROJECT_VERSION=[${PROJECT_VERSION}]"
export STUBRUNNER_SNAPSHOT_CHECK_SKIP=true

"${GIT_BIN}" config --global user.email "s1p-concourse@no.op"
"${GIT_BIN}" config --global user.name "S1P Concourse"

cd "${WORKSPACE}"

echo -e "\n\n########## ---------- Cloud Pipelines and Extensions Environment Setup [END] ---------- ##########"
