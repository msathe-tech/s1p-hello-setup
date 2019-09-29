#!/bin/bash

echo -e "\n\n########## Set Up Environment ##########"
export WORKSPACE=`pwd`
export BUILD_OPTIONS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
cd "${WORKSPACE}/code-repo"

source "${WORKSPACE}"/ci-repo/tasks/functions/pipeline-common.sh
source "${WORKSPACE}"/ci-repo/tasks/functions/pipeline-maven.sh

echo -e "\n\n########## Get Project Info ##########"
export PROJECT_GROUP="$(extractMavenProperty "project.groupId")"
export PROJECT_NAME="$(extractMavenProperty "project.artifactId")"
export PROJECT_VERSION="$(extractMavenProperty "project.version")"
echo "PROJECT_GROUP=[${PROJECT_GROUP}]"
echo "PROJECT_NAME=[${PROJECT_NAME}]"
echo "PROJECT_VERSION=[${PROJECT_VERSION}]"
export STUBRUNNER_SNAPSHOT_CHECK_SKIP=true

git config --global user.email "s1p-concourse@no.op"
git config --global user.name "S1P Concourse"

echo -e "\n\n########## Run job script ##########"
jobScript=$1
echo "Executing script: [${jobScript}]"
source "${WORKSPACE}"/"${jobScript}"