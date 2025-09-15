# This script downloads and reconfigures a VM from the bucket to match this host.
# This script DOES NOT add that VM to the CI. Refer to README.md, specifically 'Create a CI VM', 'Add to CI' for that.

if [ -z $1 ]; then
  read -p "Enter the name of the VM you want to download (YYYY-MM-DD-TEAM-VM-macOS-VERSION, without .zip): " STORAGE_VM_NAME
else
  STORAGE_VM_NAME=$1
fi
echo $STORAGE_VM_NAME

PURE_VM_NAME="$(echo "$STORAGE_VM_NAME" | cut -d'-' -f4-)"
VM_NAME=$(scutil --get ComputerName)-$PURE_VM_NAME
TEAM=$(echo "$PURE_VM_NAME" | cut -d'-' -f1)

# download, unzip, register, rename VM
cd /Users/sftnight/Parallels
/Users/sftnight/Library/Python/3.9/bin/s3cmd get -r s3://macvmstorage/$TEAM/$STORAGE_VM_NAME /Users/sftnight/Parallels/
echo ${STORAGE_VM_NAME}.zip

unzip -j /Users/sftnight/Parallels/${STORAGE_VM_NAME}.zip -d /Users/sftnight/Parallels/$STORAGE_VM_NAME.macvm

prlctl register /Users/sftnight/Parallels/$STORAGE_VM_NAME.macvm
prlctl set $STORAGE_VM_NAME --name $VM_NAME

# randomize mac-address of VM
prlctl set ${VM_NAME} --device-del net0
prlctl set ${VM_NAME} --device-add net --type bridged --iface default

# set hardware parameters according to host
prlctl set ${VM_NAME} --cpus $(sysctl -n hw.ncpu)
prlctl set ${VM_NAME} --memsize $(bc <<< "($(sysctl -n hw.memsize)-4*1073741824)/1024/1024")

# Check whether there is a build_drive, if there is none on this host, download it from S3 as well
if [[ -d /Users/sftnight/Parallels/build_drive.hdd ]]; then
  echo "/Users/sftnight/Parallels/build_drive.hdd exists"
else
  echo "File not found. Downloading from S3..."
  /Users/sftnight/Library/Python/3.9/bin/s3cmd get s3://macvmstorage/build_drive.hdd /Users/sftnight/Parallels/build_drive.hdd
  unzip -j /Users/sftnight/Parallels/build_drive.hdd.zip -d /Users/sftnight/Parallels/build_drive.hdd
  rm -rf /Users/sftnight/Parallels/build_drive.hdd.zip
fi

# CLEAN UP VM ZIP
rm -rf /Users/sftnight/Parallels/${STORAGE_VM_NAME}.zip

MSG="
After executing this script, the following steps must be performed manually: \n
\t - Register the VM to the CERN network at https://landb.cern.ch/portal/devices/register \n
\t\t  - mac-address: $(prlctl list -i ${VM_NAME} | grep net | sed -n 's/.*mac=\([^ ]*\).*/\1/p') \n
\t\t  - name: ${VM_NAME} \n
\t\t  - opt out of IPV6, it can lead to problems \n
\t\t  - log into the VMs GUI once, the reinstallation of Parallels Tools will start automatically after a moment, then require a restart \n
\t\t  - once the VM is restarted, execute these two lines on the host: \n
prlctl exec $VM_NAME "sudo scutil --set ComputerName $VM_NAME"
prlctl exec $VM_NAME "sudo scutil --set HostName $VM_NAME"
\t - Finally, if you want to set this VM up as a CI machine, look up README>Create a CI VM>Then add the VM to CI
"
echo $MSG
