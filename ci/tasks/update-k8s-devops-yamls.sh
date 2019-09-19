##!/usr/bin/env bash
#export ROOT_FOLDER
#ROOT_FOLDER="$( pwd )"
#
#source "${ROOT_FOLDER}/ci/tasks/resource-utils.sh"
#echo "Loading git key to enable push"
#export TMPDIR=/tmp
#echo "${GIT_PRIVATE_KEY}" > "${TMPDIR}/git-resource-private-key"
#load_pubkey

# For now, hard-coding baseline sha as 64414b
# In the future, cd to code-repo, get the sha or tag of last prod deployment, and use that in the replacement below
cat devops-repo/spinnaker-prod-baseline-template.yaml | sed 's/BASELINE-SHA/64414b/g' > devops-repo/spinnaker-prod-baseline.yaml
echo "" >> devops-repo/spinnaker-prod-baseline.yaml
