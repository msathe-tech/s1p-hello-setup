#!/bin/bash

set -o errexit

# This script prepares the k8s yaml files for deployment
# It expects BASELINE_VERSION_FOR_CANARY_DEPLOY and BASELINE_SHA_FOR_CANARY_DEPLOY
# to have been set in order to set tag for current prod image
# See ci/config/config-template.sh for suggestions on providing variable value

cd "${WORKSPACE}"
echo "Cloning devops-repo"
git clone devops-repo devops-repo-modified
cd devops-repo-modified

echo "Setting baseline, canary, and prod tags"
#baselineTag="${BASELINE_SHA_FOR_CANARY_DEPLOY}"
#canaryTag="${GIT_COMMIT_SHA}"
baselineTag="${BASELINE_VERSION_FOR_CANARY_DEPLOY}"
canaryTag="${GENERATED_VERSION}"

# Replace placeholders in templates to produce deployment yamls
cat templates/spinnaker-prod-baseline-template.yaml \
  | sed "s/BASELINE-TAG/${baselineTag}/g" \
  | sed "s/BASELINE-SHA/${BASELINE_SHA_FOR_CANARY_DEPLOY}/g" \
  | sed "s/BASELINE-VERSION/${BASELINE_VERSION_FOR_CANARY_DEPLOY}/g" \
  > spinnaker-prod-baseline.yaml

cat templates/spinnaker-prod-canary-template.yaml \
  | sed "s/CANARY-TAG/${canaryTag}/g" \
  | sed "s/CANARY-SHA/${GIT_COMMIT_SHA}/g" \
  | sed "s/CANARY-VERSION/${GENERATED_VERSION}/g" \
  > spinnaker-prod-canary.yaml

cat templates/spinnaker-prod-template.yaml \
  | sed "s/PROD-TAG/${canaryTag}/g" \
  | sed "s/PROD-SHA/${GIT_COMMIT_SHA}/g" \
  | sed "s/PROD-VERSION/${GENERATED_VERSION}/g" \
  > spinnaker-prod.yaml

echo "$(date) BASELINE=${baselineTag} CANARY/PROD=${canaryTag}" >> bump
git add .
git commit -m "Updated tags for baseline, canary, and prod"

echo -e "\n\n########## Summary ##########"
echo "source=${GIT_URL}" > ci-summary.properties
echo "project_name=${PROJECT_NAME}" >> ci-summary.properties
echo "commit_id=${GIT_COMMIT_SHA}" >> ci-summary.properties
echo "build_version=${GENERATED_VERSION}" >> ci-summary.properties
echo "canary_tag=${canaryTag}" >> ci-summary.properties
echo "baseline_tag=${baselineTag}" >> ci-summary.properties

cat ci-summary.properties
