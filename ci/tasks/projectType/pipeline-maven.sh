#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains customized Maven related build functions
# }}}

NUM_SOURCED_EXT_FILES=$((NUM_SOURCED_EXT_FILES + 1))

# FUNCTION: runDefaultTests {{{
# Will run the tests with [default] profile. Will not build or upload artifacts.
function runDefaultTests() {
	echo "Running default tests."

	if [[ "${CI}" == "CONCOURSE" ]]; then
		# shellcheck disable=SC2086
		"${MAVENW_BIN}" clean test -Pdefault -Drepo.with.binaries="${REPO_WITH_BINARIES}" ${BUILD_OPTIONS} || (printTestResults && return 1)
	else
		# shellcheck disable=SC2086
		"${MAVENW_BIN}" clean test -Pdefault -Drepo.with.binaries="${REPO_WITH_BINARIES}" ${BUILD_OPTIONS}
	fi
} # }}}

export -f runDefaultTests

# FUNCTION: deployLocal {{{
# Will deploy main and stubs jars locally. Upload to a maven-repo must be done separately
function deployLocal() {
  echo ${WORKSPACE}
  echo ${GIT_REPO}
  echo ${REPO_NAME}
  echo ${GROUP_ID}
  echo ${ARTIFACT_ID}
  echo ${VERSION}

#  cd $WORKSPACE
#  git clone $GIT_REPO $REPO_NAME
#  cd $REPO_NAME
#  ./mvnw clean package
#
#  cd $WORKSPACE
#  git clone $GIT_REPO $REPO_NAME-repository
#  cd $REPO_NAME-repository
#  git checkout repository
#  ./mvnw install:install-file -DgroupId=$GROUP_ID -DartifactId=$ARTIFACT_ID -Dversion=$VERSION -Dfile=$WORKSPACE/$REPO_NAME/target/$ARTIFACT_ID-$VERSION-stubs.jar -Dpackaging=jar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true -Dclassifier=stubs
#  git add .
#  git commit -m "stubs for version $VERSION"
#  git push
} # }}}
