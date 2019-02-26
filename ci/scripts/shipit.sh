#!/bin/bash
#
# ci/scripts/shipit
#
# Script for generating Github release / tag assets
# and managing release notes for a BOSH Release pipeline
#
# author:  James Hunt <james@niftylogic.com>

set -eu

header() {
  echo
  echo "###############################################"
  echo
  echo $*
  echo
}

######
######
######
header "Checking the Concourse Pipeline Environment"
envok=0
checkenv() {
  local name=$1
  local val=$2

  if [[ -z "$val" ]]; then
    echo >&2 "The $name variable must be set."
    envok=1
  fi
}
checkenv REPO_ROOT      "${REPO_ROOT:-}"
checkenv REPO_OUT       "${REPO_OUT:-}"
checkenv BRANCH         "${BRANCH:-}"
checkenv GITHUB_OWNER   "${GITHUB_OWNER:-}"
checkenv VERSION_FROM   "${VERSION_FROM:-}"
checkenv AWS_ACCESS_KEY "${AWS_ACCESS_KEY:-}"
checkenv AWS_SECRET_KEY "${AWS_SECRET_KEY:-}"
checkenv GIT_EMAIL      "${GIT_EMAIL:-}"
checkenv GIT_NAME       "${GIT_NAME:-}"
if [[ $envok != 0 ]]; then
  echo >&2 "Is your Concourse Pipeline misconfigured?"
  exit 1
fi

VERSION=$(cat ${VERSION_FROM})
if [[ -z "${VERSION}" ]]; then
  echo >&2 "Version file (${VERSION_FROM}) was empty."
  exit 1
fi

###############################################################

cd ${REPO_ROOT}

######
######
######
header "Configuring blobstore (AWS)"
cat > config/private.yml <<YAML
---
blobstore:
  provider: s3
  options:
    access_key_id: ${AWS_ACCESS_KEY}
    secret_access_key: ${AWS_SECRET_KEY}
YAML

######
######
######
header "Creating final release..."
bosh -n create-release --final --version "${VERSION}"

sed "s/##VERSION##/${VERSION}/g" ci/README_template.md > README.md
cd ..

echo "v${VERSION}" > gh/tag
echo "Filesystem BBR v${VERSION}" > gh/name

######
######
######
header "Updating git repo with final release..."
if [[ -z $(git config --global user.email) ]]; then
  git config --global user.email "${GIT_EMAIL}"
fi
if [[ -z $(git config --global user.name) ]]; then
  git config --global user.name "${GIT_NAME}"
fi

(cd ${REPO_ROOT}
 git merge --no-edit ${BRANCH}
 git add -A
 git status
 git commit -m "Release v${VERSION}")

# so that future steps in the pipeline can push our changes
cp -a ${REPO_ROOT} ${REPO_OUT}

echo
echo
echo
echo "SUCCESS"
exit 0