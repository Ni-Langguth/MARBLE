# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_MARBLE_DIR="/Volumes/My\ Shared\ Files/Home/MARBLE"
SHARED_MARBLE_DIR="/Volumes/My Shared Files/Home/MARBLE"

# copy daemon and its script to the VM.
# This step requires a github PAT with rights to register a runner to the root repo

sudo cp "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/AUTO_RUNNER/start.actions.runner.plist" /Library/LaunchDaemons
cp "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/AUTO_RUNNER/VM_ROOT_download_and_config_runner.sh" /Users/sftnight 
sudo launchctl bootstrap system /Library/LaunchDaemons/start.actions.runner.plist
sudo chown sftnight:staff "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/AUTO_RUNNER/VM_ROOT_download_and_config_runner.sh"
echo $1 > /Users/sftnight/.PAT

