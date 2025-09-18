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
SHARED_MARBLE_DIR="/Volumes/My\ Shared\ Files/Home/MARBLE"
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

if [ -z "$VM_NAME" ]; then echo "The first argument to this script should be the name of the VM you want to configure."
else
  startVM $VM_NAME
  prlctl exec $VM_NAME "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/VM_ROOT_03_activate_auto_runner_setup.sh $PAT" 
fi

prlctl stop $VM_NAME --kill
