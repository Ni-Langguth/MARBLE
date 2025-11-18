# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
# arg1: VM_NAME, arg2: PAT
if [[ -z $2 ]]; then
  read -p "Enter the name of the VM you want to set up: " VM_NAME
  read -p "Enter the github PAT: " PAT
else
  VM_NAME=$1
  PAT=$2
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_BARMAN_DIR="/Volumes/My\ Shared\ Files/Home/BARMAN"

isVMon() {
  prlctl list --no-header | grep $VM_NAME | wc -l
}
${DIR}/../.unlock_all_vms.sh

startVM() {
  echo "Starting $VM_NAME"
  prlctl start $VM_NAME
  while [ true ]; do
    if [[ $(isVMon $VM_NAME) -eq 1 ]]; then break; fi
    sleep 1
  done
  sleep 5
  echo "$VM_NAME is on."
}

startVM $VM_NAME
prlctl exec $VM_NAME "${SHARED_BARMAN_DIR}/VM_SETUP/ROOT/VM_ROOT_03_activate_auto_runner_setup.sh ${PAT}"
sleep 1

prlctl stop $VM_NAME --kill

ssh-keygen -t ed25519 -f ~/.ssh/parallels_vm_key
ssh-keygen -y -f ~/.ssh/parallels_vm_key >> ~/.ssh/authorized_keys

