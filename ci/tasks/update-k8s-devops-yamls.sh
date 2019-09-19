#!/usr/bin/env bash
# For now, hard-coding baseline sha as 64414b
# In the future, cd to code-repo, get the sha or tag of last prod deployment, and use that in the replacement below
cd devops-repo
cat spinnaker-prod-baseline-template.yaml | sed 's/BASELINE-SHA/64414b/g' > spinnaker-prod-baseline.yaml
echo "" >> spinnaker-prod-baseline.yaml
