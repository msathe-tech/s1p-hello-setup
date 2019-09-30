#!/bin/bash

echo -e "\n\n########## Set Up Environment ##########"
export WORKSPACE="$(pwd)"
export BUILD_OPTIONS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"

cd "${WORKSPACE}/code-repo"

source "${WORKSPACE}"/ci-repo/ci/tasks/functions/pipeline-common.sh
source "${WORKSPACE}"/ci-repo/ci/tasks/functions/pipeline-maven.sh
source "${WORKSPACE}"/code-repo/ci/config.sh

echo -e "\n\n########## Get Project Info ##########"
export PROJECT_GROUP="$(fnRetrieveGroupId)"
export PROJECT_NAME="$(fnRetrieveAppName)"
export PROJECT_VERSION="$(fnRetrieveAppVersion)"
export GIT_URL="$(git config --get remote.origin.url)"
gitCommitTime="$(git show --no-patch --no-notes --pretty='%ct')"
export GIT_COMMIT_TIME="$(date -d @${gitCommitTime} +'%Y%m%d.%H%M%SZ')"
export GIT_COMMIT_SHA="$(git rev-parse --short HEAD)"
echo "PROJECT_GROUP=[${PROJECT_GROUP}]"
echo "PROJECT_NAME=[${PROJECT_NAME}]"
echo "PROJECT_VERSION=[${PROJECT_VERSION}]"
echo "GIT_URL=[${GIT_URL}]"
echo "GIT_COMMIT_TIME=[${GIT_COMMIT_TIME}]"
echo "GIT_COMMIT_SHA=[${GIT_COMMIT_SHA}]"

echo -e "\n\n########## Get generated version for this build (generate if undefined) ##########"
export GENERATED_VERSION=$(fnGenerateVersion)
echo "GENERATED_VERSION=[${GENERATED_VERSION}]"

git config --global user.email "s1p-concourse@no.op"
git config --global user.name "S1P Concourse"

echo -e "\n\n########## Run job script ##########"
jobScript=$1
echo "Executing script: [${jobScript}]"
source "${WORKSPACE}"/"${jobScript}"