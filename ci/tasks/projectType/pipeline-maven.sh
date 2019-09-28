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

# FUNCTION: build {{{
# Maven implementation of build. Sets version, passes build options and distribution management properties.
# Uses [PIPELINE_VERSION], [PASSED_PIPELINE_VERSION] and [M2_SETTINGS...], [REPO_WITH_BINARIES...] related env vars
function build() {
  	echo "Running build (extensions)."
	local pipelineVersion="${PASSED_PIPELINE_VERSION:-${PIPELINE_VERSION:-}}"
	# Required by settings.xml
	#BUILD_OPTIONS="${BUILD_OPTIONS} -DM2_SETTINGS_REPO_ID=${M2_SETTINGS_REPO_ID} -DM2_SETTINGS_REPO_USERNAME=${M2_SETTINGS_REPO_USERNAME} -DM2_SETTINGS_REPO_PASSWORD=${M2_SETTINGS_REPO_PASSWORD}"
	# shellcheck disable=SC2086
	"${MAVENW_BIN}" versions:set -DnewVersion="${pipelineVersion}" -DprocessAllModules ${BUILD_OPTIONS} || (echo "Build failed!!!" && return 1)
	if [[ "${CI}" == "CONCOURSE" ]]; then
		# shellcheck disable=SC2086
		"${MAVENW_BIN}" clean package || (printTestResults && return 1)
		cd "$WORKSPACE/maven-repo"
    "${MAVENW_BIN}" install:install-file -DgroupId="${PROJECT_GROUP}" -DartifactId="${PROJECT_NAME}" -Dversion="${pipelineVersion}" -Dfile="${WORKSPACE}/code-repo/target/${PROJECT_NAME}-${pipelineVersion}-stubs.jar" -Dpackaging=jar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true -Dclassifier=stubs
    "${GIT_BIN}" add .
    "${GIT_BIN}" commit -m "stubs for version $VERSION"
    cd cd "$WORKSPACE/code-repo"
  # git push is done through Concourse resource
	else
		# shellcheck disable=SC2086
		"${MAVENW_BIN}" clean verify deploy -Ddistribution.management.release.id="${M2_SETTINGS_REPO_ID}" -Ddistribution.management.release.url="${REPO_WITH_BINARIES_FOR_UPLOAD}" -Drepo.with.binaries="${REPO_WITH_BINARIES}" ${BUILD_OPTIONS}
	fi
} # }}}

export -f runDefaultTests
export -f build



