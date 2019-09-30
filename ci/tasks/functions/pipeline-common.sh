#!/bin/bash +x

set -o errexit
set -o errtrace
set -o pipefail

# FUNCTION: fnGenerateVersion {{{
# Generates version
# Returns version number.
function fnGenerateVersion() {
  local version="${GENERATED_VERSION:-${PIPELINE_VERSION:-}}"
	if [[ ! -z "${version}" ]]; then
	  echo "${version}"
	else
	  local version="$(fnExtractMavenProperty "project.version")"
		local commitTime="$(git show --no-patch --no-notes --pretty='%ct')"
		commitTime="$(date -d @${commitTime} +'%Y%m%d.%H%M%SZ')"
		local commitIdShort="$(git rev-parse --short HEAD)"
		#local version="${version}+${commitTime}.${commitIdShort}"
		local version="${version}-${commitTime}.${commitIdShort}"
		echo "${version}"
	fi
} # }}}

export -f fnGenerateVersion

# FUNCTION: fnExecuteDatabaseCompatibilityCheck {{{
# Java implementation of executing database compatibility check
function fnExecuteDatabaseCompatibilityCheck() {
	local prodSHA="${1}"
  echo -e "\n\n##### Testing code from prod_commit=[${prodSHA}] against current DB schema [current git_commit=${GIT_COMMIT_SHA}]\n\n\n";
  cd "${WORKSPACE}"
  git clone code-repo temp-code-repo
  cd temp-code-repo
  git checkout "${PROD_SHA_FOR_DB_TEST}"
  # Copy db/migrations scripts from code-repo
  rm -r src/main/resources/db/migration
  mkdir -p src/main/resources/db
  cp -r "${WORKSPACE}/code-repo/src/main/resources/db/migration" src/main/resources/db/migration
  fnRunDefaultTests
  cd ${WORKSPACE}/code-repo
  rm -rf ${WORKSPACE}/temp-code-repo
  # Can also try using:
  #BUILD_OPTIONS="${BUILD_OPTIONS} -Dspring.flyway.locations=filesystem:${WORKSPACE}/code-repo/src/main/resources/db/migration"
} # }}}

# FUNCTION: fnStageStubCompatibilityCheck {{{
# Staging stub compatibility check
# Requires separate function to execute
function fnStageStubompatibilityCheck() {
	export STUBS="${1}"
	echo -e "\n\n##### Staging for test with stub: ${STUBS}\n";
  # Copy stubs to local maven repo
	IFS=":"
  stubCoordinates=($STUBS)
  groupDir=`echo "${stubCoordinates[0]}" | sed "s/\./\//g"`
  artifactDir="${stubCoordinates[1]}"
  versionDir="${stubCoordinates[2]}"
  mkdir -p "~/.m2/repository/${groupDir}/${artifactDir}/${versionDir}"
  cp "${WORKSPACE}/maven-repo/${groupDir}/${artifactDir}/maven-metadata-*" "~/.m2/repository/${groupDir}/${artifactDir}"
  cp "${WORKSPACE}/maven-repo/${groupDir}/${artifactDir}/${versionDir}/*" "~/.m2/repository/${groupDir}/${artifactDir}/${versionDir}"
  unset IFS
	echo "Test will run on next package/build"
	# Test will be executed during package or build
	# fnRunDefaultTests
} # }}}
