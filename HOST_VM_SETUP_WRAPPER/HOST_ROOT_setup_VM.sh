# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
# arg1 VM_NAME
if [[ -z $1 ]]; then
  read -p "Enter the name of the VM you want to set up: " VM_NAME
else
  VM_NAME=$1
fi

SHARED_MARBLE_DIR="/Volumes/My\ Shared\ Files/Home/MARBLE"

isVMon() {
  prlctl list --no-header | grep $VM_NAME | wc -l
}

startVM() {
  prlctl start $VM_NAME > /dev/null 2>&1
  while [ true ]; do
    if [[ $(isVMon $VM_NAME) -eq 1 ]]; then break; fi
    sleep 1
  done
  echo "$VM_NAME is on."
}

ssh-keygen -t ed25519 -f ~/.ssh/parallels_vm_key
ssh-keygen -y -f ~/.ssh/parallels_vm_key >> ~/.ssh/authorized_keys

if [ -z "$VM_NAME" ]; then echo "The first argument to this script should be the name of the VM you want to configure."
else
  startVM $VM_NAME
  prlctl exec $VM_NAME "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/VM_ROOT_01_configure.sh $VM_NAME" 
  prlctl exec $VM_NAME "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/VM_ROOT_02_system_installs.sh $VM_NAME" 
fi
