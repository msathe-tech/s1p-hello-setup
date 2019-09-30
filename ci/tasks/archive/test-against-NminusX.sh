#!/bin/bash

set -o errexit

# This script contains tests for:
#     - apps that are API producers
#     - apps that are API consumers
#     - apps that manage database schemas
#
# The execution of specific tests is toggled via configuration
# See ci/config/config-template.sh for instructions on configuring CI tests for a given app
# Sample settings:
# PROD_VERSIONS_FOR_API_PRODUCER_TEST=1.1.0,1.2.0
# PROD_SHAS_FOR_DB_TEST=1234567,9876543
# STUBS_FOR_API_CONSUMER_TEST=com.sample:otherProducerApp:1.0.0,com.sample:otherProducer:2.0.0

echo -e "\n\n########## API PRODUCER TEST: Test API back compatibility ##########"
if [[ -z "${PROD_VERSIONS_FOR_API_PRODUCER_TEST}" ]]; then
  echo "Skipping test (PROD_VERSIONS_FOR_API_PRODUCER_TEST=[${PROD_VERSIONS_FOR_API_PRODUCER_TEST}])"
else
  echo "Got PROD_VERSIONS_FOR_API_PRODUCER_TEST=[${PROD_VERSIONS_FOR_API_PRODUCER_TEST}]"
  IFS=","
  prodVersionsArray=($PROD_VERSIONS_FOR_API_PRODUCER_TEST)
  for version in "${prodVersionsArray[@]}"
  do
    echo -e "\n\n##### Testing API contracts from version [${version}]\n\n\n";
    fnExecuteApiCompatibilityCheck "${version}"
  done
  unset IFS
fi

echo -e "\n\n########## DATABASE TEST: Test database schema back compatibility ##########"
if [[ -z "${PROD_SHAS_FOR_DB_TEST}" ]]; then
  echo "Skipping test (PROD_SHAS_FOR_DB_TEST=[${PROD_SHAS_FOR_DB_TEST}])"
else
  echo "Got PROD_SHAS_FOR_DB_TEST=[${PROD_SHAS_FOR_DB_TEST}]"
  cd "${WORKSPACE}"
  git clone code-repo temp-code-repo
  cd temp-code-repo
  # Copy current db/migrations scripts
  # Can also try using:
  #BUILD_OPTIONS="${BUILD_OPTIONS} -Dspring.flyway.locations=filesystem:${WORKSPACE}/code-repo/src/main/resources/db/migration"
  currentMigrations="${WORKSPACE}/code-repo/src/main/resources/db/migration"
  # Loop through previous release and check each one against the current db schema
  IFS=","
  prodShasArray=($PROD_SHAS_FOR_DB_TEST)
  for ((i=0; i<${#prodShasArray[@]}; ++i)); do
    prodSHA="${prodShasArray[$i]}"
    git checkout "${prodSHA}"
    echo -e "\n\n##### Testing code from prod_commit=[${prodSHA}] against current DB schema [current git_commit=${GIT_COMMIT_SHA}]\n\n\n";
    rm -r src/main/resources/db/migration
    mkdir -p src/main/resources/db
    cp -r ${currentMigrations} src/main/resources/db/migration
    fnRunDefaultTests
  done
  unset IFS
  cd ${WORKSPACE}/code-repo
  rm -rf ${WORKSPACE}/temp-code-repo
fi

echo -e "\n\n########## API CONSUMER TEST: Test API compatibility with stubs ##########"
if [[ -z "${STUBS_FOR_API_CONSUMER_TEST}" ]]; then
  echo "Skipping test (STUBS_FOR_API_CONSUMER_TEST=[${STUBS_FOR_API_CONSUMER_TEST}])"
else
  echo "Got STUBS_FOR_API_CONSUMER_TEST=[${STUBS_FOR_API_CONSUMER_TEST}]"

  # Need to test one at a time for now due to a port binding error
  STUBS=${STUBS_FOR_API_CONSUMER_TEST}
  IFS=","
  stubrunnerIDsArray=($STUBS)
  length=${#stubrunnerIDsArray[@]}
  #savedBuildOptions="${BUILD_OPTIONS}"
  for ((i=0; i<${#stubrunnerIDsArray[@]}; ++i)); do
      echo -e "\n\n##### Testing with stubs[$i]: ${stubrunnerIDsArray[$i]}\n";
      export STUBS="${stubrunnerIDsArray[$i]}"
      #export BUILD_OPTIONS="${savedBuildOptions} -Dstubrunner.ids=${stubrunnerIDsArray[$i]}"
      if (( $i < ${#stubrunnerIDsArray[@]}-1 )); then
        # TODO: Make sure stub is accessible
        # TODO: separate default tests command for no stubs?
        fnRunDefaultTests
      else
          echo -e "\Skipping stubs[$i]: ${stubrunnerIDsArray[$i]} for now (will be tested in Package phase)\n";
      fi
  done
  unset IFS
fi

echo -e "\n\n########## Package ##########"
#git reset --hard "${GIT_COMMIT_SHA}"
#git clean -f -d
#git checkout "${GIT_COMMIT_SHA}"
fnPackage
#BUILD_OPTIONS="${savedBuildOptions}"

echo -e "\n\n########## Build info summary (to archive) ##########"
echo "source=${GIT_URL}" > ci-build.properties
echo "project_name=${PROJECT_NAME}" >> ci-build.properties
echo "commit_id=${GIT_COMMIT_SHA}" >> ci-build.properties
echo "build_version=${GENERATED_VERSION}" >> ci-build.properties
echo "api_back_compat=${PROD_VERSIONS_FOR_API_PRODUCER_TEST}" >> ci-build.properties
echo "db_back_compat=${PROD_SHAS_FOR_DB_TEST}" >> ci-build.properties
echo "api_compat=${STUBS_FOR_API_CONSUMER_TEST}" >> ci-build.properties

cat ci-build.properties
