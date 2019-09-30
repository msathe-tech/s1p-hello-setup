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
	local stub="${PROJECT_GROUP}:${PROJECT_NAME}:${prodVersion}"
	fnInstallStubToLocalMavenRepo "${stub}"
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
    cd "${WORKSPACE}"
    git clone stubs-repo stubs-repo-modified
    cd stubs-repo-modified
    ./mvnw install:install-file -DgroupId="${PROJECT_GROUP}" -DartifactId="${PROJECT_NAME}" -Dversion="${GENERATED_VERSION}" -Dfile="${stubsJar}" -Dpackaging=jar -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true -Dclassifier=stubs || (echo "Install failed!!!" && return 1)
    git add .
    git commit -m "stubs for version ${GENERATED_VERSION}"
    # git push of stub jar is done through Concourse resource
    cd "$WORKSPACE/code-repo"
  fi
} # }}}

# FUNCTION: fnSetLocalMavenRepoHome {{{
# Set maven repo home to ${WORKSPACE} to enable caching
function fnSetLocalMavenRepoHome() {
  M2_DEFAULT_HOME="${HOME}"/.m2
  M2_CACHEABLE_HOME="${WORKSPACE}"/.m2
  mkdir -p "${M2_DEFAULT_HOME}"
  mkdir -p "${M2_CACHEABLE_HOME}/repository"

  # Create custom settings.xml
  echo '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
    <localRepository>${M2_CACHEABLE_HOME}/repository</localRepository>
</settings>' > "${M2_DEFAULT_HOME}"/settings.xml

  cat ${M2_HOME}/settings.xml
  export MAVEN_CONFIG="-s ${M2_DEFAULT_HOME}/settings.xml ${MAVEN_CONFIG}"

  echo "Local maven repo set to: ${M2_CACHEABLE_HOME}/repository"
  echo "Enable caching using 'caches: {path: .m2/}' in task config"
} # }}}
