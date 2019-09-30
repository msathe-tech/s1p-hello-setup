# How to use this template:
# Copy this template into your app's code repo as <ROOT>/ci/config.sh
# The file will be sourced by the pipeline and will control which tests are run.
# Set the exported variables below for any test you want to enable.
# Comment out exports to disable specific tests.
# You can obtain the necessary coordinates & shas any way that works - this example
# assumes ${prodUrl} and ${stubProviderProdUrl} provide the necessary info.
# Examples:
# prodUrl="http://my-app.example.com/actuator/info"
# stubProviderProdUrl="http://provider-app.example.com/actuator/info"

########## Configure CI pipeline options #####
prodUrl=
stubProviderProdUrl=

# Get info for compatibility testing
if [[ ! -z "${prodUrl}" ]]; then
  echo -e "\nGetting version from ${prodUrl}"
  prodVersion="$(curl ${prodUrl} | jq '.app["version"]')"
  echo "Getting git-sha from ${prodUrl}"
  prodSha="$(curl ${prodUrl} | jq '.app["git-sha"]')"
fi

if [[ ! -z "${stubProviderProdUrl}" ]]; then
  echo -e "\n\nGetting stub-coordinates from ${stubProviderProdUrl}"
  stubProviderProdCoordinates="$(curl ${stubProviderProdUrl} | jq '.app["stub-coordinates"]')"
fi

# Comment out variables to disable tests
export PROD_VERSION_FOR_API_PRODUCER_TEST=${prodVersion}
export PROD_SHA_FOR_DB_TEST=${prodSha}
export STUB_FOR_API_CONSUMER_TEST=${stubProviderProdCoordinates}

# Provide baseline info for canary deployment
BASELINE_VERSION_FOR_CANARY_DEPLOY=${prodVersion}
BASELINE_SHA_FOR_CANARY_DEPLOY=${prodSha}

echo -e "\nApp-driven configuration of CI:"
echo "PROD_VERSION_FOR_API_PRODUCER_TEST=${PROD_VERSION_FOR_API_PRODUCER_TEST}"
echo "PROD_SHA_FOR_DB_TEST=${PROD_SHA_FOR_DB_TEST}"
echo "STUB_FOR_API_CONSUMER_TEST=${STUB_FOR_API_CONSUMER_TEST}"
echo "BASELINE_VERSION_FOR_CANARY_DEPLOY=${BASELINE_VERSION_FOR_CANARY_DEPLOY}"
echo "BASELINE_SHA_FOR_CANARY_DEPLOY=${BASELINE_SHA_FOR_CANARY_DEPLOY}"
