# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_BARMAN_DIR="/Volumes/My Shared Files/Home/BARMAN"

# copy daemon and its script to the VM.
# This step requires a github PAT with rights to register a runner to the root repo

sudo rm /Library/LaunchDaemons/start.actions.runner.plist
sudo cp "${SHARED_BARMAN_DIR}/VM_SETUP/ROOT/AUTO_RUNNER/start.actions.runner.plist" /Library/LaunchDaemons
sudo rm /Users/sftnight/VM_ROOT_download_and_config_runner.sh
sudo cp "${SHARED_BARMAN_DIR}/VM_SETUP/ROOT/AUTO_RUNNER/VM_ROOT_download_and_config_runner.sh" /Users/sftnight
sudo chown sftnight:staff /Users/sftnight/VM_ROOT_download_and_config_runner.sh
sudo launchctl bootstrap system /Library/LaunchDaemons/start.actions.runner.plist
sudo chown sftnight:staff /Users/sftnight/VM_ROOT_download_and_config_runner.sh

echo "${1}" > /Users/sftnight/.PAT
