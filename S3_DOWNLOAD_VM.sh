STORAGE_VM_NAME=$1
export VM_NAME=$(scutil --get ComputerName)-$STORAGE_VM_NAME

# download, unzip, register, rename VM
cd /Users/sftnight/Parallels
/Users/sftnight/Library/Python/3.9/bin/s3cmd get s3://macvmstorage/$TEAM -r $STORAGE_VM_NAME
unzip /Users/sftnight/Parallels/$STORGE_VM_NAME.zip
prlctl register /Users/sftnight/Parallels/$STORAGE_VM_NAME.macvm
prlctl set $STORAGE_VM_NAME --name $VM_NAME

# randomize mac-address of VM
prlctl set ${VM_NAME} --device-del net0
prlctl set ${VM_NAME} --device-add net --type bridged --iface default

# create build_drive? (should never be necessary if VM was configured correctly before upload)
# register VM to network
# activate runner-daemon for ROOT VMs / timeout-daemon for SPI VMs (maybe do this in a seperate script, once the parallels tools are installed? Do the parallels tools have to be reinstalled?
