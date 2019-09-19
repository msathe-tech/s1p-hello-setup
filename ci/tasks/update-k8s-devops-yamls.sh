#!/usr/bin/env bash
#export ROOT_FOLDER
#ROOT_FOLDER="$( pwd )"
#
#source "${ROOT_FOLDER}/ci/tasks/resource-utils.sh"
#echo "Loading git key to enable push"
#export TMPDIR=/tmp
#echo "${GIT_PRIVATE_KEY}" > "${TMPDIR}/git-resource-private-key"
#load_pubkey

echo "Current dir:"
pwd
git clone devops-repo devops-repo-modified
cd devops-repo-modified
cat spinnaker-prod-baseline-template.yaml | sed 's/BASELINE-SHA/64414b/g' > spinnaker-prod-baseline.yaml
echo "" >> spinnaker-prod-baseline.yaml
git add .
git config --global user.email "s1p-concourse@no.op"
git config --global user.name "S1P Concourse"
git commit -m "Updated baseline tag with SHA"


# For now, hard-coding baseline sha as 64414b
# In the future, cd to code-repo, get the sha or tag of last prod deployment, and use that in the replacement below
