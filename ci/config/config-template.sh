# How to use this template:
# Copy this template into your app's code repo as <ROOT>/ci/config.sh
# The file will be sourced by the pipeline and will control which tests are run.
# Set the exported variables below for any test you want to enable.
# Comment out exports to disable specific tests.
# You can obtain the necessary coordinates & shas any way that works - this example
# assumes ${prodUrl} and ${stubProviderProdUrl} provide the necessary info.

########## Configure CI pipeline options #####

# Get info for compatibility testing
prodUrl="http://my-app.example.com/actuator/info"
prodVersion=`curl ${prodUrl} | jq '.app["version"]'`
prodSha=`curl ${prodUrl} | jq '.app["git-sha"]'`
stubProviderProdUrl="http://provider-app.example.com/actuator/info"
stubProviderProdCoordinates=`curl ${stubProviderProdUrl} | jq '.app["stub-coordinates"]'`

# Comment out variables to disable tests
export PROD_VERSION_FOR_API_PRODUCER_TEST="${prodVersion}"
export PROD_SHA_FOR_DB_TEST="${prodSha}"
export STUB_FOR_API_CONSUMER_TEST="${stubProviderProdCoordinates}"

# Provide baseline info for canary deployment
BASELINE_VERSION_FOR_CANARY_DEPLOY="${prodVersion}"
BASELINE_SHA_FOR_CANARY_DEPLOY="${prodSha}"