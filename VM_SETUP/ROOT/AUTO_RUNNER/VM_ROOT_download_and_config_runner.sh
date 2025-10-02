# Run by the start.actions.runner.plist daemon every time the VM is launched to create a new ephemeral runner and register it to the ROOT CI. This requires the PAT stored in ~/.PAT. 
# Please provide the PAT to the HOST_ROOT_activate_auto_runner_setup.sh during initial setup.

GH_OWNER="root-project"
GH_REPO="root"
RUNNER_NAME="$(scutil --get ComputerName)-$(date | tr ' :' '-')"
PRIMARY_MAC_OS_VERSION="$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')"
USER_DIR=/Users/sftnight
RUNNER_DIR="actions-runner"
WORK_DIR="_work"

# READ PERSONAL ACCESS TOKEN - DO NOT UPLOAD .PAT ANYWHERE
GH_PAT=$(cat ${USER_DIR}/.PAT)

# If the runner tarball on the VM differs from githubs latest version, update it
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')
CURRENT_RUNNER_VERSION=$(ls ${USER_DIR}/actions-runner-osx-arm64-*.tar.gz | sed -E 's/.*osx-arm64-([0-9.]+)\.tar\.gz/\1/')
if [[ "$RUNNER_VERSION" != "$CURRENT_RUNNER_VERSION" ]]; then
  curl -o ${USER_DIR}/actions-runner-osx-arm64-${RUNNER_VERSION#v}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-arm64-${RUNNER_VERSION#v}.tar.gz
fi

# At the time of writing, macos26 is the beta version of macos - keep this up to date when the next beta comes
if [[ ${PRIMARY_MAC_OS_VERSION} == "26" ]]; then
  PRIMARY_MAC_OS_VERSION=beta
  RUNNER_LABELS="self-hosted,macOS,mac-${PRIMARY_MAC_OS_VERSION},arm64"
else
  RUNNER_LABELS="self-hosted,macOS,mac${PRIMARY_MAC_OS_VERSION},arm64"
fi

# Get registration token with PAT
REG_TOKEN=$(
  curl -sX POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_PAT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/actions/runners/registration-token |  sed -n 's/.*"token": *"\([^"]*\)".*/\1/p'
)

mkdir -p ${USER_DIR}/${RUNNER_DIR}

# Unpack runner tarball
tar xzf ${USER_DIR}/actions-runner-osx-arm64-${RUNNER_VERSION#v}.tar.gz -C ${USER_DIR}/${RUNNER_DIR}

# Overwrite used runner with new ephemeral runner as per githubs recommendation (running a runner with --once is deprecated)
${USER_DIR}/${RUNNER_DIR}/config.sh remove --token "${REG_TOKEN}"
${USER_DIR}/${RUNNER_DIR}/config.sh --unattended \
  --url https://github.com/${GH_OWNER}/${GH_REPO} \
  --token "${REG_TOKEN}" \
  --name  "${RUNNER_NAME}" \
  --no-default-labels \
  --labels "${RUNNER_LABELS}" \
  --work   "${WORK_DIR}" \
  --ephemeral \
  --replace 
rm -rf ${USER_DIR}/${RUNNER_DIR}/${WORK_DIR}
ln -s  /Volumes/build_drive/ROOT-macOS-${PRIMARY_MAC_OS_VERSION}/${WORK_DIR} ${USER_DIR}/${RUNNER_DIR}/${WORK_DIR}
#sudo chown -R sftnight:staff ${USER_DIR}/${RUNNER_DIR}/${WORK_DIR}

# Launch runner
$USER_DIR/${RUNNER_DIR}/run.sh

