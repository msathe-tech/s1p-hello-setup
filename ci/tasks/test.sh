#!/bin/bash

set -o errexit

# This script contains tests for:
#     - apps that are API producers
#     - apps that are API consumers
#     - apps that manage database schemas
#
# The execution of specific tests is toggled via configuration
# See ci/config/config-template.sh for suggestions on configuring CI tests for a given app
# Sample settings:
# PROD_VERSION_FOR_API_PRODUCER_TEST=1.1.0
# PROD_SHA_FOR_DB_TEST=1234567
# STUB_FOR_API_CONSUMER_TEST=com.sample:otherProducerApp:1.0.0

echo -e "\n\n########## API PRODUCER TEST: Test API back compatibility ##########"
echo "Got PROD_VERSION_FOR_API_PRODUCER_TEST=[${PROD_VERSION_FOR_API_PRODUCER_TEST}]"
if [[ -z "${PROD_VERSION_FOR_API_PRODUCER_TEST}" ]]; then
  echo "Skipping test"
else
  fnExecuteApiCompatibilityCheck "${PROD_VERSION_FOR_API_PRODUCER_TEST}"
fi

echo -e "\n\n########## DATABASE TEST: Test database schema back compatibility ##########"
echo "Got PROD_SHA_FOR_DB_TEST=[${PROD_SHA_FOR_DB_TEST}]"
if [[ -z "${PROD_SHA_FOR_DB_TEST}" ]]; then
  echo "Skipping test"
else
  fnExecuteDatabaseCompatibilityCheck "${PROD_SHA_FOR_DB_TEST}"
fi

echo -e "\n\n########## API CONSUMER TEST: Test API compatibility with stubs ##########"
echo "Got STUB_FOR_API_CONSUMER_TEST=[${STUB_FOR_API_CONSUMER_TEST}]"
if [[ -z "${STUB_FOR_API_CONSUMER_TEST}" ]]; then
  echo "Skipping test"
else
  fnStageStubCompatibilityCheck "${STUB_FOR_API_CONSUMER_TEST}"
fi

echo -e "\n\n########## Package ##########"
git reset --hard "${GIT_COMMIT_SHA}"
git clean -f -d
git checkout "${GIT_COMMIT_SHA}"
fnPackage

echo -e "\n\n########## Set image tags ##########"
echo "${GIT_COMMIT_SHA}" > DockerTagfile
echo "${GENERATED_VERSION}" > DockerAdditionalTagsfile

echo -e "\n\n########## Summary ##########"
echo "source=${GIT_URL}" > ci-summary.properties
echo "project_name=${PROJECT_NAME}" >> ci-summary.properties
echo "commit_id=${GIT_COMMIT_SHA}" >> ci-summary.properties
echo "build_version=${GENERATED_VERSION}" >> ci-summary.properties
echo "api_back_compat=${PROD_VERSION_FOR_API_PRODUCER_TEST}" >> ci-summary.properties
echo "db_back_compat=${PROD_SHA_FOR_DB_TEST}" >> ci-summary.properties
echo "api_compat=${STUB_FOR_API_CONSUMER_TEST}" >> ci-summary.properties

cat ci-summary.properties
