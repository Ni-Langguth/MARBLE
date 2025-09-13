# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_MARBLE_DIR="/Volumes/My\ Shared\ Files/Home/MARBLE"

isVMon() {
  prlctl list --no-header | grep $1 | wc -l
}

startVM() {
  prlctl start $1 > /dev/null 2>&1
  while [ true ]; do
    if [[ $(isVMon $1) -eq 1 ]]; then break; fi
    sleep 1
  done
  echo "$1 is on."
}

ssh-keygen -t ed25519 -f ~/.ssh/parallels_vm_key
ssh-keygen -y -f ~/.ssh/parallels_vm_key > ~/.ssh/parallels_vm_key.pub

if [ -z "$1" ]; then echo "The first argument to this script should be the name of the VM you want to configure."
else
  startVM $1
  prlctl exec $1 "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/VM_ROOT_01_configure.sh $1" 
  prlctl exec $1 "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/VM_ROOT_02_system_installs.sh $1" 
fi
