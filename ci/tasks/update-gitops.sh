#!/bin/bash

set -o errexit

echo -e "\n\n########## Run job script ##########"
cd "${WORKSPACE}/code-repo"
export GIT_URL=`"${GIT_BIN}" config --get remote.origin.url`
export GIT_COMMIT="$(${GIT_BIN} rev-parse HEAD)"

echo -e "\n\n########## Generate version for this build ##########"
echo "Project Name [${PROJECT_NAME}]"
echo "Project Version [${PROJECT_VERSION}]"
export GENERATED_VERSION=$(fnGenerateVersion)
echo "Generated Version [${GENERATED_VERSION}]"

cd "${WORKSPACE}"
echo "Cloning devops-repo"
git clone devops-repo devops-repo-modified
cd devops-repo-modified
# For now, hard-coding baseline sha as 64414b
# In the future, cd to code-repo, get the sha or tag of last prod deployment, and use that in the replacement below
cat templates/spinnaker-prod-baseline-template.yaml | sed 's/BASELINE-SHA/64414bd/g' > spinnaker-prod-baseline.yaml
echo -e "\n#" >> spinnaker-prod-baseline.yaml
cat templates/spinnaker-prod-canary-template.yaml | sed "s/GIT-SHA/${sha}/g" > spinnaker-prod-canary.yaml
cat templates/spinnaker-prod-template.yaml | sed "s/GIT-SHA/${sha}/g" > spinnaker-prod.yaml
date > bump
git add .
git config --global user.email "s1p-concourse@no.op"
git config --global user.name "S1P Concourse"
git commit -m "Updated baseline tag with SHA"

