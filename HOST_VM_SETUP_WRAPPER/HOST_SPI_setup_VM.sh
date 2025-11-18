# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_BARMAN_DIR="/Volumes/My\ Shared\ Files/Home/BARMAN"
VM_NAME=$1
isVMon() {
  prlctl list --no-header | grep $1 | wc -l
}

startVM() {
  echo "Starting $1"
  prlctl start $1
  while [ true ]; do
    if [[ $(isVMon $1) -eq 1 ]]; then break; fi
    sleep 1
  done
  sleep 5
  echo "$1 is on."
}


if [ -z "$1" ]; then echo "The first argument to this script should be the name of the VM you want to configure."
else
  startVM $1
  prlctl exec $VM_NAME "${SHARED_BARMAN_DIR}/VM_SETUP/SPI/VM_SPI_01_configure.sh $1"
  prlctl exec $VM_NAME "${SHARED_BARMAN_DIR}/VM_SETUP/SPI/VM_SPI_system_installs.sh $1"
fi
