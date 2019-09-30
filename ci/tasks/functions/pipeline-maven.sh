#!/bin/bash +x

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains customized Maven related build functions
# }}}

# FUNCTION: fnRetrieveGroupId {{{
function fnRetrieveGroupId() {
	echo "$(fnExtractMavenProperty "project.groupId")"
} # }}}

# FUNCTION: fnRetrieveAppName {{{
function fnRetrieveAppName() {
	echo "$(fnExtractMavenProperty "project.artifactId")"
} # }}}

# FUNCTION: fnRetrieveAppVersion {{{
function fnRetrieveAppVersion() {
	echo "$(fnExtractMavenProperty "project.version")"
} # }}}

# FUNCTION: fnExtractMavenProperty {{{
# The function uses Maven Wrapper to extract property with name $1
#
# $1 - name of the property to extract
function fnExtractMavenProperty() {
	local prop="${1}"
	MAVEN_PROPERTY=$(./mvnw -q  \
 -Dexec.executable="echo"  \
 -Dexec.args="\${${prop}}"  \
 --non-recursive  \
 org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)
	# In some spring cloud projects there is info about deactivating some stuff
	MAVEN_PROPERTY=$(echo "${MAVEN_PROPERTY}" | tail -1)
	# In Maven if there is no property it prints out ${propname}
	if [[ "${MAVEN_PROPERTY}" == "\${${prop}}" ]]; then
		echo ""
	else
		echo "${MAVEN_PROPERTY}"
	fi
} # }}}

# FUNCTION: fnExecuteApiCompatibilityCheck {{{
# Maven implementation of executing API compatibility check
function fnExecuteApiCompatibilityCheck() {
	local prodVersion="${1}"
	# shellcheck disable=SC2086
	./mvnw clean verify -Papicompatibility -Dprod.version="${prodVersion}" ${BUILD_OPTIONS} || (printTestResults && return 1)
} # }}}

# FUNCTION: fnRunDefaultTests {{{
# Will run the tests with [default] profile. Will not build or upload artifacts.
function fnRunDefaultTests() {
	echo "Running default tests."
	# shellcheck disable=SC2086
	./mvnw clean test -Pdefault ${BUILD_OPTIONS} || (printTestResults && return 1)
} # }}}

# FUNCTION: fnPackage {{{
# Maven implementation of fnPackage. Sets version, passes build options, runs default tests.
# Also stages stubs jar for upload (does not do upload).
function fnPackage() {
  echo "Running fnPackage."
	# shellcheck disable=SC2086
	./mvnw versions:set -DnewVersion="${GENERATED_VERSION}" -DprocessAllModules ${BUILD_OPTIONS} || (echo "Package failed!!!" && return 1)
  # shellcheck disable=SC2086
  ./mvnw clean package || (printTestResults && return 1)
  stubsJar="${WORKSPACE}/code-repo/target/${PROJECT_NAME}-${GENERATED_VERSION}-stubs.jar"
  if [[ -f "${stubsJar}" ]]; then
    cd "$WORKSPACE/stubs-repo"
    ./mvnw install:install-file -DgroupId="${PROJECT_GROUP}" -DartifactId="${PROJECT_NAME}" -Dversion="${GENERATED_VERSION}" -Dfile="${stubsJar}" -Dpackaging=jar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true -Dclassifier=stubs || (echo "Install failed!!!" && return 1)
    git add .
    git commit -m "stubs for version ${GENERATED_VERSION}"
    # git push of stub jar is done through Concourse resource
    cd "$WORKSPACE/code-repo"
  fi
} # }}}

export -f fnRunDefaultTests
export -f fnPackage
