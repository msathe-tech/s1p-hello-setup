#!/bin/bash +x

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains interfaces for all essential functions for different
# steps of CI pipeline.
#
# Sources:
#
#  - projectType/pipeline-projectType.sh
#
# The build related scripts need to define how to build an application.
# E.g. for Java we're using Maven or Gradle to build a project. For other
# languages other frameworks and approaches would be applicable. You can
# arbitrarily chose the language type via the LANGUAGE_TYPE env variable
# or via the language_type pipeline descriptor entry. That value, via convention,
# gets applied to the string [projectType/pipeline-${languageType}.sh] that
# represents a file that we will source in order to apply all the build functions.
# }}}

IFS=$' \n\t'

__ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ================================================================
#                      INTERFACES - START
# ================================================================

# ---- BUILD PHASE ----

# FUNCTION: fnBuild {{{
# Build the application and produce a binary. Most likely you'll upload that binary somewhere
function fnBuild() {
	echo "Build the application and produce a binary. Most likely you'll
		upload that binary somewhere"
	exit 1
} # }}}

# FUNCTION: apiCompatibilityCheck {{{
# Execute api compatibility check step. Uses the LATEST_PROD_TAG or PASSED_LATEST_PROD_TAG
# env vars if latest production tag has already been retrieved. If not will call the
# [findLatestProdTag] function to retrieve the latest production tag.
#
# Requires the [PROJECT_NAME] env variable to be set. Otherwise will not be able to
# parse the latest production tag. As a reminder, latest production tag should be of
# structure [dev/appName/version] or [prod/appName/version].
function apiCompatibilityCheck() {
	# Find latest prod version
	local prodTag="${PASSED_LATEST_PROD_TAG:-${LATEST_PROD_TAG:-}}"
	[[ -z "${prodTag}" ]] && prodTag="$(findLatestProdTag)"
	echo "Last prod tag equals [${prodTag}]"
	if [[ -z "${prodTag}" ]]; then
		echo "No prod release took place - skipping this step"
	else
		export LATEST_PROD_TAG PASSED_LATEST_PROD_TAG
		LATEST_PROD_TAG="${prodTag}"
		PASSED_LATEST_PROD_TAG="${prodTag}"
		PROJECT_NAME=${PROJECT_NAME?PROJECT_NAME must be set!}
		LATEST_PROD_VERSION=${prodTag#"prod/${PROJECT_NAME}/"}
		echo "Last prod version equals [${LATEST_PROD_VERSION}]"
		fnExecuteApiCompatibilityCheck "${LATEST_PROD_VERSION}"
		mkdir -p "${OUTPUT_FOLDER}"
		{
			echo "LATEST_PROD_VERSION=${LATEST_PROD_VERSION}";
			echo "LATEST_PROD_TAG=${prodTag}";
			echo "PASSED_LATEST_PROD_TAG=${prodTag}";
		} >> "${OUTPUT_FOLDER}/trigger.properties"
	fi
} # }}}

# FUNCTION: fnExecuteApiCompatibilityCheck {{{
# Execute api compatibility check step for the given latest production version $1
#
# $1 - retrieved latest production version
function fnExecuteApiCompatibilityCheck() {
	# shellcheck disable=SC2034
	local latestProdVersion="${1}"
	echo "Execute api compatibility check step"
	exit 1
} # }}}

# FUNCTION: retrieveGroupId {{{
# Echos the namespace that corresponds to the given application. In the
# JVM world corresponds to a group id of a project
function retrieveGroupId() {
	echo "Echos the namespace that corresponds to the given application. In the
	JVM world corresponds to a group id of a project"
	exit 1
} # }}}

# FUNCTION: retrieveAppName {{{
# Echos the name of the application
# JVM world corresponds to a group id of a project
function retrieveAppName() {
	echo "Echos the name of the application"
	exit 1
} # }}}

# FUNCTION: retrieveStubRunnerIds {{{
# Retrieves the ids for Spring Cloud Contract Stub Runner. If you don't use
# Stub Runner, overriding this method is not mandatory. The format of the IDS is
# [groupId:artifactId:version:classifier:port]. E.g. [com.example:foo:1.0.0.RELEASE:stubs:1234]
function retrieveStubRunnerIds() {
	echo "Retrieves the ids for Spring Cloud Contract Stub Runner. If you don't use
	Stub Runner, overriding this method is not mandatory"
	exit 1
}
# }}}

# ---- TEST PHASE ----

# FUNCTION: prepareForSmokeTests {{{
# Prepares environment for smoke tests. Retrieves the latest production
# tags, exports all URLs required for smoke tests, etc.
function prepareForSmokeTests() {
	echo "Prepares environment for smoke tests. Retrieves the latest production
	tags, exports all URLs required for smoke tests, etc."
	exit 1
} # }}}

# FUNCTION: runSmokeTests {{{
# Executes smoke tests. Profits from env vars set by 'prepareForSmokeTests'
function runSmokeTests() {
	echo "Executes smoke tests. Profits from env vars set by 'prepareForSmokeTests'"
	exit 1
} # }}}

# ---- STAGE PHASE ----

# FUNCTION: prepareForE2eTests {{{
# Prepares environment for smoke tests. Logs in to PAAS etc.
function prepareForE2eTests() {
	echo "Prepares environment for smoke tests. Logs in to PAAS etc."
	exit 1
} # }}}

# FUNCTION: runE2eTests {{{
# Executes end to end tests. Profits from env vars set by 'prepareForE2eTests'
function runE2eTests() {
	echo "Executes end to end tests. Profits from env vars set by 'prepareForE2eTests'"
	exit 1
} # }}}

# ---- COMMON ----

# FUNCTION: projectType {{{
# Returns the type of the project basing on the cloned sources.
# Example: MAVEN, GRADLE etc
function projectType() {
	echo "Returns the type of the project basing on the cloned sources.
	Example: MAVEN, GRADLE etc."
	exit 1
} # }}}

# FUNCTION: outputFolder {{{
# Returns the folder where the built binary will be stored.
# Example: 'target/' - for Maven, 'build/' - for Gradle etc.
function outputFolder() {
	echo "Returns the folder where the built binary will be stored.
	Example: 'target/' - for Maven, 'build/' - for Gradle etc."
	exit 1
} # }}}

# FUNCTION: testResultsAntPattern {{{
# Returns the ant pattern for the test results.
# Example: '**/test-results/*.xml' - for Maven, '**/surefire-reports/*' - for Gradle etc.
function testResultsAntPattern() {
	echo "Returns the ant pattern for the test results.
	Example: '**/test-results/*.xml' - for Maven, '**/surefire-reports/*' - for Gradle etc."
	exit 1
} # }}}

# ================================================================
#                      INTERFACES - END
# ================================================================


# ================================================================
#                  COMMON FUNCTIONS - START
# ================================================================

# FUNCTION: findLatestProdTag {{{
# Echoes the latest prod tag from git with trimmed refs part. Uses the
# LATEST_PROD_TAG and PASSED_LATEST_PROD_TAG env vars if latest production tag
# was already found. If not, retrieves the latest prod tag via [latestProdTagFromGit]
# function and sets the [PASSED_LATEST_PROD_TAG] and [LATEST_PROD_TAG] env vars with
# the trimmed prod tag. Trimming occurs via the [trimRefsTag] function
function findLatestProdTag() {
	local prodTag="${PASSED_LATEST_PROD_TAG:-${LATEST_PROD_TAG:-}}"
	if [[ ! -z "${prodTag}" ]]; then
		echo "${prodTag}"
	else
		local latestProdTag
		latestProdTag="$(latestProdTagFromGit)"
		export LATEST_PROD_TAG PASSED_LATEST_PROD_TAG
		LATEST_PROD_TAG="$(trimRefsTag "${latestProdTag}")"
		PASSED_LATEST_PROD_TAG="${LATEST_PROD_TAG}"
		echo "${LATEST_PROD_TAG}"
	fi
} # }}}


# FUNCTION: latestProdTagFromGit {{{
# Echos latest productino tag from git
function latestProdTagFromGit() {
	local latestProdTag
	latestProdTag=$("${GIT_BIN}" for-each-ref --sort=taggerdate --format '%(refname)' "refs/tags/prod/${PROJECT_NAME}" | tail -1)
	echo "${latestProdTag}"
} # }}}

# FUNCTION: trimRefsTag {{{
# Extracts latest prod tag
function trimRefsTag() {
	local latestProdTag="${1}"
	echo "${latestProdTag#refs/tags/}"
} # }}}

# FUNCTION: extractVersionFromProdTag {{{
# Extracts the version from the production tag
function extractVersionFromProdTag() {
	local tag="${1}"
	echo "${tag#prod/}"
} # }}}

# FUNCTION: removeProdTag {{{
# Removes production tag.
# Uses [PROJECT_NAME] and [PIPELINE_VERSION]
function removeProdTag() {
	local tagName
	tagName="${1:-prod/${PROJECT_NAME}/${PIPELINE_VERSION}}"
	echo "Deleting production tag [${tagName}]"
	"${GIT_BIN}" push --delete origin "${tagName}"
} # }}}

# FUNCTION: parsePipelineDescriptor {{{
# Sets the [PARSED_YAML] environment variable with contents of the parsed pipeline
# descriptor assuming that the file described by the [PIPELINE_DESCRIPTOR] env variable
# is present. If it's not present, will fallback to finding the descriptor
# under [LEGACY_PIPELINE_DESCRIPTOR] env var name.
# If either of the files exists, the [PIPELINE_DESCRIPTOR_PRESENT] env var is set to [true]
# shellcheck disable=SC2120
function parsePipelineDescriptor() {
	if [[ "${PARSED_YAML}" != "" ]]; then
		echo "Pipeline descriptor already parsed - will not parse it again"
	else
		export PIPELINE_DESCRIPTOR_PRESENT
		local pipelineDescriptorName="${PIPELINE_DESCRIPTOR}"
		if [[ ! -f "${PIPELINE_DESCRIPTOR}" ]]; then
			echo "No pipeline descriptor [${PIPELINE_DESCRIPTOR}] found. Will fallback to [${LEGACY_PIPELINE_DESCRIPTOR}]"
			PIPELINE_DESCRIPTOR_PRESENT="false"
			pipelineDescriptorName="${LEGACY_PIPELINE_DESCRIPTOR}"
		fi
		if [[ ! -f "${LEGACY_PIPELINE_DESCRIPTOR}" && "${PIPELINE_DESCRIPTOR_PRESENT}" == "false" ]]; then
			echo "No legacy pipeline descriptor [${LEGACY_PIPELINE_DESCRIPTOR}] found - will not deploy any services"
			PIPELINE_DESCRIPTOR_PRESENT="false"
			return
		fi
		echo "Will parse a descriptor present at [${pipelineDescriptorName}]"
		PIPELINE_DESCRIPTOR_PRESENT="true"
		export PARSED_YAML
		PARSED_YAML=$(yaml2json "${pipelineDescriptorName}")
	fi
} # }}}

# FUNCTION: envNodeExists {{{
# Returns 0 if environment $1 node exists in the pipeline descriptor, 1 if it doesn't.
# Requires the [PARSED_YAML] env var to contain the parsed descriptor
#
# $1 - name of the environment (e.g. test)
function envNodeExists() {
	local environment="${1}"
	local services
	services="$(echo "${PARSED_YAML}" |  jq -r --arg x "${environment}" '.[$x]')"
	if [[ "${services}" == "null" || "${services}" == "" ]]; then
		return 1
	else
		return 0
	fi
} # }}}

# FUNCTION: yaml2json {{{
# Converts YAML to JSON - uses ruby
function yaml2json() {
	ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' "$@"
} # }}}

# FUNCTION: toLowerCase {{{
# Converts a string $1 to lower case
#
# $1 - string to convert
function toLowerCase() {
	echo "$1" | tr '[:upper:]' '[:lower:]'
} # }}}

# FUNCTION: getMainModulePath {{{
# Gets the build coordinates from descriptor. Requires the [PARSED_YAML] to parse
# otherwise returns empty main module
function getMainModulePath() {
	if [[ ! -z "${PARSED_YAML}" ]]; then
		local mainModule
		mainModule="$( echo "${PARSED_YAML}" | jq -r '.build.main_module' )"
		if [[ "${mainModule}" == "null" ]]; then
			mainModule=""
		fi
		echo "${mainModule}"
	else
		echo ""
	fi
} # }}}

# ================================================================
#                  COMMON FUNCTIONS - END
# ================================================================

# ================================================================
#           DEFINING PROJECT SETUP / LANGUAGE - START
# ================================================================


# FUNCTION: defineProjectSetup {{{
# Defines the project setup. Takes into consideration the location of the pipeline
# descriptor, project name, main module path etc.
# Sets the [PROJECT_SETUP], [ROOT_PROJECT_DIR] env vars.
# Uses [PROJECT_NAME] env var and [getMainModulePath] functions
function defineProjectSetup() {
	# if pipeline descriptor is in the provided folder that means that
	# we don't have a descriptor per application
	if [[ "${PIPELINE_DESCRIPTOR_PRESENT}" == "true" ]]; then
		echo "Pipeline descriptor found"
		mainModulePath="$( getMainModulePath )"
		if [[ "${mainModulePath}" != "" && "${mainModulePath}" != "null" ]]; then
			# multi module - has a coordinates section in the descriptor
			PROJECT_SETUP="MULTI_MODULE"
			echo "Build coordinates section found, project setup [${PROJECT_SETUP}], main module path [${mainModulePath}]"
		else
			# single repo - no coordinates
			PROJECT_SETUP="SINGLE_REPO"
			echo "No build coordinates section found, project setup [${PROJECT_SETUP}], main module path [${mainModulePath}]"
		fi
		ROOT_PROJECT_DIR="."
	else
		echo "Pipeline descriptor missing"
		# if pipeline descriptor is missing but a directory with name equal to PROJECT_NAME exists
		# that means that it's a multi-project and we need to cd to that folder
		if [[ -d "${PROJECT_NAME}" ]]; then
			echo "Project dir found [${PROJECT_NAME}]"
			cd "${PROJECT_NAME}"
			parsePipelineDescriptor
			mainModulePath="$( getMainModulePath )"
			if [[ "${mainModulePath}" != "" && "${mainModulePath}" != "null" ]]; then
				# multi project with module - has a coordinates section in the descriptor
				PROJECT_SETUP="MULTI_PROJECT_WITH_MODULES"
				echo "Build coordinates section found, project setup [${PROJECT_SETUP}], main module path [${mainModulePath}]"
			else
				# multi project without modules
				PROJECT_SETUP="MULTI_PROJECT"
				echo "No build coordinates section found, project setup [${PROJECT_SETUP}], main module path [${mainModulePath}]"
			fi
			ROOT_PROJECT_DIR="${PROJECT_NAME}"
		else
			# No descriptor and no module is present - will treat it as a single repo with no descriptor
			PROJECT_SETUP="SINGLE_REPO"
			echo "No descriptor or module found for project with name [${PROJECT_NAME}], project setup [${PROJECT_SETUP}]"
			ROOT_PROJECT_DIR="."
		fi
	fi
} # }}}

# ================================================================
#                      EXPORTS AND CONSTANTS
# ================================================================
export PIPELINE_DESCRIPTOR LOWERCASE_ENV GIT_BIN
export ROOT_PROJECT_DIR PROJECT_SETUP PROJECT_NAME DEFAULT_PROJECT_NAME
export LANGUAGE_TYPE SOURCE_ARTIFACT_TYPE_NAME BINARY_ARTIFACT_TYPE_NAME
export OUTPUT_FOLDER TEST_REPORTS_FOLDER DOWNLOADABLE_SOURCES
export CURL_BIN TAR_BIN ADDITIONAL_SCRIPTS_TARBALL_URL CUSTOM_SCRIPT_IDENTIFIER
export ADDITIONAL_SCRIPTS_REPO_USERNAME ADDITIONAL_SCRIPTS_REPO_PASSWORD

SOURCE_ARTIFACT_TYPE_NAME="source"
BINARY_ARTIFACT_TYPE_NAME="binary"

# ================================================================
#            DEFAULTS FOR PAAS, ENVIRONMENT, LANGUAGE
# ================================================================
# Not every linux distribution comes with installation of JQ that is new enough
# to have the asci_downcase method. That's why we're using the global env variable
# At some point we'll deprecate this and use what JQ provides
LOWERCASE_ENV="$(toLowerCase "${ENVIRONMENT}")"
PIPELINE_DESCRIPTOR="${PIPELINE_DESCRIPTOR:-cloud-pipelines.yml}"
LEGACY_PIPELINE_DESCRIPTOR="${LEGACY_PIPELINE_DESCRIPTOR:-sc-pipelines.yml}"
GIT_BIN="${GIT_BIN:-git}"
DEFAULT_PROJECT_NAME="$(basename "$(pwd)")"
echo "Current environment is [${ENVIRONMENT}]"
echo "Project name [${PROJECT_NAME}]"
parsePipelineDescriptor
defineProjectSetup

# ================================================================
#  [SOURCE] Sourcing a file that can pick proper build framework / language
# ================================================================
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
[[ -f "${__DIR}/projectType/pipeline-projectType.sh" ]] && source "${__DIR}/projectType/pipeline-projectType.sh" ||  \
 echo "No projectType/pipeline-projectType.sh found"

# ================================================================
#  With picked language type we can retrieve the project name
# ================================================================
# The result of sourcing project type will be the language type
LANGUAGE_TYPE="$(toLowerCase "${LANGUAGE_TYPE}")"
# Project name can be taken from env variable or from the project's app name
# We need it to tag the project somehow if the PROJECT_NAME var wasn't passed
if [[ "${PROJECT_NAME}" == "" || "${PROJECT_NAME}" == "null" ]]; then
	PROJECT_NAME="$(retrieveAppName)"
fi
echo "Project with name [${PROJECT_NAME}] is setup as [${PROJECT_SETUP}]. The project directory is present at [${ROOT_PROJECT_DIR}]"

# ================================================================
#  Fetching tarball with additional code
# ================================================================
TAR_BIN="${TAR_BIN:-tar}"
CURL_BIN="${CURL_BIN:-curl}"
ADDITIONAL_SCRIPTS_TARBALL_URL="${ADDITIONAL_SCRIPTS_TARBALL_URL:-}"
ADDITIONAL_SCRIPTS_REPO_USERNAME="${ADDITIONAL_SCRIPTS_REPO_USERNAME:-${M2_SETTINGS_REPO_USERNAME:-}}"
ADDITIONAL_SCRIPTS_REPO_PASSWORD="${ADDITIONAL_SCRIPTS_REPO_PASSWORD:-${M2_SETTINGS_REPO_PASSWORD:-}}"
TMP_DIR="$( mktemp -d )"
if [[ "${ADDITIONAL_SCRIPTS_TARBALL_URL}" != "" ]]; then
	echo "Will fetch additional scripts from [${ADDITIONAL_SCRIPTS_TARBALL_URL}] to [${TMP_DIR}]"
	success="false"
	destination="${TMP_DIR}/scripts.tar.gz"
	"${CURL_BIN}" -u "${M2_SETTINGS_REPO_USERNAME}:${M2_SETTINGS_REPO_PASSWORD}" "${ADDITIONAL_SCRIPTS_TARBALL_URL}" -o "${destination}" --fail && success="true"
	if [[ "${success}" == "true" ]]; then
		echo "File downloaded successfully to [${destination}]!"
		"${TAR_BIN}" -zxf "${destination}" -C "${__ROOT}"
		echo "Files unpacked successfully from [${destination}] to [${__ROOT}]"
	else
		echo "Failed to download file!"
	fi
else
	echo "No additional scripts will be downloaded"
fi

# ================================================================
#  Customizing via the folder "custom/script_name.sh"
# ================================================================
CUSTOM_SCRIPT_IDENTIFIER="${CUSTOM_SCRIPT_IDENTIFIER:-custom}"
echo "Custom script identifier is [${CUSTOM_SCRIPT_IDENTIFIER}]"
CUSTOM_SCRIPT_DIR="${__ROOT}/${CUSTOM_SCRIPT_IDENTIFIER}"
mkdir -p "${__ROOT}/${CUSTOM_SCRIPT_IDENTIFIER}"
# The check for null is used for tests
[[ -z "${CUSTOM_SCRIPT_NAME}" ]] && CUSTOM_SCRIPT_NAME="$(basename "${BASH_SOURCE[1]}")"
echo "Path to custom script for current step is [${CUSTOM_SCRIPT_DIR}/${CUSTOM_SCRIPT_NAME}]"

# ================================================================
#  [SOURCE] Sourcing a custom script if one is available
# ================================================================
# shellcheck source=/dev/null
[[ -f "${CUSTOM_SCRIPT_DIR}/${CUSTOM_SCRIPT_NAME}" ]] && source "${CUSTOM_SCRIPT_DIR}/${CUSTOM_SCRIPT_NAME}" ||  \
 echo "No ${CUSTOM_SCRIPT_DIR}/${CUSTOM_SCRIPT_NAME} found"
# shellcheck source=/dev/null
[[ -f "${CUSTOM_SCRIPT_DIR}/${CUSTOM_PAAS_SCRIPT_NAME}" ]] && source "${CUSTOM_SCRIPT_DIR}/${CUSTOM_PAAS_SCRIPT_NAME}" ||  \
 echo "No ${CUSTOM_SCRIPT_DIR}/${CUSTOM_PAAS_SCRIPT_NAME} found"

OUTPUT_FOLDER="$(outputFolder)"
TEST_REPORTS_FOLDER="$(testResultsAntPattern)"

echo "Output folder [${OUTPUT_FOLDER}]"
echo "Test reports folder [${TEST_REPORTS_FOLDER}]"

# ================================================================
#           DEFINING PROJECT SETUP / LANGUAGE - END
# ================================================================