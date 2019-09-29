#!/bin/bash +x

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains customized Maven related build functions
# }}}

# FUNCTION: fnRunDefaultTests {{{
# Will run the tests with [default] profile. Will not build or upload artifacts.
function fnRunDefaultTests() {
	echo "Running default tests."
	# shellcheck disable=SC2086
	./mvnw clean test -Pdefault -Drepo.with.binaries="${REPO_WITH_BINARIES}" ${BUILD_OPTIONS} || (printTestResults && return 1)
} # }}}

# FUNCTION: fnBuild {{{
# Maven implementation of fnBuild. Sets version, passes build options and distribution management properties.
# Uses [PIPELINE_VERSION], [GENERATED_VERSION] and [M2_SETTINGS...], [REPO_WITH_BINARIES...] related env vars
function fnBuild() {
  echo "Running fnBuild (extensions)."
	local pipelineVersion="${GENERATED_VERSION:-${PIPELINE_VERSION:-}}"
	# shellcheck disable=SC2086
	./mvnw versions:set -DnewVersion="${pipelineVersion}" -DprocessAllModules ${BUILD_OPTIONS} || (echo "Build failed!!!" && return 1)
  # shellcheck disable=SC2086
  ./mvnw clean package || (printTestResults && return 1)
  cd "$WORKSPACE/maven-repo"
  ./mvnw install:install-file -DgroupId="${PROJECT_GROUP}" -DartifactId="${PROJECT_NAME}" -Dversion="${pipelineVersion}" -Dfile="${WORKSPACE}/code-repo/target/${PROJECT_NAME}-${pipelineVersion}-stubs.jar" -Dpackaging=jar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true -Dclassifier=stubs
  git add .
  git commit -m "stubs for version $VERSION"
  cd "$WORKSPACE/code-repo"
  # git push is done through Concourse resource
} # }}}

export -f fnRunDefaultTests
export -f fnBuild



