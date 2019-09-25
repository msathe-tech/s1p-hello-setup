#!/usr/bin/env bash

echo "Cloning devops-repo"
git clone devops-repo devops-repo-modified
cd devops-repo-modified
# For now, hard-coding baseline sha as 64414b
# In the future, cd to code-repo, get the sha or tag of last prod deployment, and use that in the replacement below
cat spinnaker-prod-baseline-template.yaml | sed 's/BASELINE-SHA/64414bd/g' > spinnaker-prod-baseline.yaml
echo -e "\n#" >> spinnaker-prod-baseline.yaml
date > bump
git config --global user.email "s1p-concourse@no.op"
git config --global user.name "S1P Concourse"
git commit -m "Updated baseline tag with SHA"

