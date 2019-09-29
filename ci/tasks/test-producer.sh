#!/bin/bash

set -o errexit

echo -e "\n\n########## Run job script ##########"
cd "${WORKSPACE}/code-repo"
export GIT_URL=`"${GIT_BIN}" config --get remote.origin.url`
export GIT_COMMIT="$(${GIT_BIN} rev-parse HEAD)"

echo -e "\n\n########## Generate version for this build ##########"
echo "Project Name [${PROJECT_NAME}]"
echo "Project Version [${PROJECT_VERSION}]"
export GENERATED_VERSION=$(fnGenerateVersion)
echo "Generated Version [${GENERATED_VERSION}]"

#echo -e "\n\n########## Get release tags ##########"
#if $SKIP_BACK_COMPATIBILITY_CHECKS ; then
#    echo "Skipping [SKIP_BACK_COMPATIBILITY_CHECKS=${SKIP_BACK_COMPATIBILITY_CHECKS}]"
#elif [[ ! -z "${RELEASE_TAGS}" ]]; then
#   echo "Using release list from input parameter:"
#   echo "${RELEASE_TAGS}"
#else
#  echo "Using release list published by last release:"
#  echo "---- Raw file contents ----"
#  cat "${WORKSPACE}"/.git/tools-releases/fortune-service/ci-releases.properties
#  echo "---- Raw file contents (end) ----"
#  # File format is [tag=coordinates\n]. Convert to comma-separated list of coordinates.
#  separator="" # Blank until first run through loop
#  while read line; do
#    tag=$(echo ${line} | cut -d "=" -f1)
#  	#echo "Adding tag [${tag}]"
#	RELEASE_TAGS="${RELEASE_TAGS}${separator}${tag}"
#    separator="," # will be populated after first coordinates are set
#  done < "${WORKSPACE}"/.git/tools-releases/fortune-service/ci-releases.properties
#  echo "Extracted tags:"
#  echo "${RELEASE_TAGS}"
#fi

# Expecting RELEASE_TAGS to contain a comman-delimited list of coordinates. For example:
# io.pivotal:greeting-ui:1.0.0-20190510.205150Z.0638cc,io.pivotal:greeting-ui:1.0.0-20190428.172355Z.bcd72b4
RELEASE_TAGS=spring.k8s:s1p-hello-service:0.0.1-SNAPSHOT-20190928.135943Z.bd26e35

echo -e "\n\n########## Test API back compatibility ##########"
if $SKIP_BACK_COMPATIBILITY_CHECKS ; then
    echo "Skipping [SKIP_BACK_COMPATIBILITY_CHECKS=${SKIP_BACK_COMPATIBILITY_CHECKS}]"
elif [[ -z "${RELEASE_TAGS}" ]]; then
    echo "Skipping [RELEASE_TAGS=${RELEASE_TAGS}]"
else
    IFS=","
    releaseTagsArray=($RELEASE_TAGS)
    for ((i=0; i<${#releaseTagsArray[@]}; ++i)); do
        version=${releaseTagsArray[$i]#"prod/${PROJECT_NAME}/"}
        echo -e "\n\n##### Testing with API client from version [${version}]\n\n\n";
        fnExecuteApiCompatibilityCheck "${version}"
    done
    unset IFS
fi

#echo -e "\n\n########## Run database schema back compatibility tests ##########"
#if $SKIP_BACK_COMPATIBILITY_CHECKS ; then
#    echo "Skipping [SKIP_BACK_COMPATIBILITY_CHECKS=${SKIP_BACK_COMPATIBILITY_CHECKS}]"
#elif [[ -z "${RELEASE_TAGS}" ]]; then
#    echo "Skipping [RELEASE_TAGS=${RELEASE_TAGS}]"
#else
#    # Copy current db/migrations scripts
#    # default flyway.locations=filesystem:src/main/resources/db/migration
#    # instead, will use flyway.locations=filesystem:.git/db-${current_git_commit}/db/migration
#    mkdir -p .git/db-${GIT_COMMIT}
#    cp -r src/main/resources/db/migration .git/db-${GIT_COMMIT}/migration
#    #BUILD_OPTIONS="${BUILD_OPTIONS} -Dspring.flyway.locations=filesystem:.git/db-${GIT_COMMIT}/migration"
#
#    # Loop through previous release and check each one against the current db schema
#    IFS=","
#    releaseTagsArray=($RELEASE_TAGS)
#    for ((i=0; i<${#releaseTagsArray[@]}; ++i)); do
#        tag="${releaseTagsArray[$i]}"
#        "${GIT_BIN}" checkout ${tag}
#        echo -e "\n\n##### Testing [${tag}] against current DB schema [current git_commit=${GIT_COMMIT}]\n\n\n";
#        rm -r src/main/resources/db/migration
#        mkdir -p src/main/resources/db
#        cp -r .git/db-${GIT_COMMIT}/migration src/main/resources/db/migration
#        # fnRunDefaultTests will use BUILD_OPTIONS to use new migration scripts (saved to .git folder above)
#        fnRunDefaultTests
#    done
#    "${GIT_BIN}" reset --hard "${GIT_COMMIT}"
#    "${GIT_BIN}" clean -f -d
#    unset IFS
#fi

echo -e "\n\n########## Build and upload ##########"
#"${GIT_BIN}" checkout "${GIT_COMMIT}"
fnBuild

#echo -e "\n\n########## Publish uploaded files ##########"
#api=${REPO_WITH_BINARIES_FOR_UPLOAD/maven/content}
#curl -X POST ${api}/${GENERATED_VERSION}/publish

echo -e "\n\n########## Build info summary (to archive) ##########"
echo "source=${GIT_URL}" > ci-build.properties
echo "project_name=${PROJECT_NAME}" >> ci-build.properties
echo "commit_id=${GIT_COMMIT}" >> ci-build.properties
echo "build_version=${GENERATED_VERSION}" >> ci-build.properties
echo "skip_back_compat_checks=${SKIP_BACK_COMPATIBILITY_CHECKS}" >> ci-build.properties
echo "api_back_compat=${RELEASE_TAGS}" >> ci-build.properties
echo "db_back_compat=${RELEASE_TAGS}" >> ci-build.properties

cat ci-build.properties