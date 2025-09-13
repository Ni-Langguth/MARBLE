# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_MARBLE_DIR="/Volumes/My\ Shared\ Files/Home/MARBLE"

isVMon() {
  prlctl list --no-header | grep $1 | wc -l
}

startVM() {
  echo "Starting $1."
  prlctl start $1 > /dev/null 2>&1
  while [ true ]; do
    if [[ $(isVMon $1) -eq 1 ]]; then break; fi
    sleep 1
  done
  echo "$1 is on."
}


if [ -z "$1" ]; then echo "The first argument to this script should be the name of the VM you want to configure."
else
  startVM $1
  prlctl exec $VM_NAME "${SHARED_MARBLE_DIR}/VM_SETUP/SPI/VM_SPI_system_installs.sh $1"
fi
