VM_NAME=$1

# rename the VMs computer and hostname
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# Partition the build_drive in case this has not happened yet (after recreating one or in case this is the first VM that is set up, otherwise nothing happens)
export DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%

# create directories
export VM_NAME=$(scutil --get ComputerName)
export VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')

# At the time of writing, macos26 is the beta version of macos - keep this up to date when the next beta comes
if [[ ${VERSION}=="26" ]]; then
  PRIMARY_MAC_OS_VERSION=beta
fi

mkdir -p /Volumes/build_drive/ROOT-macOS-${VERSION}/ROOT-CI
mkdir -p /Volumes/build_drive/ROOT-macOS-${VERSION}/_work
ln -s  /Volumes/build_drive/ROOT-macOS-${VERSION}/ROOT-CI /Users/sftnight/ROOT-CI
chown -R sftnight:staff /Users/sftnight/ROOT-CI
chown -R sftnight:staff /Volumes/build_drive/ROOT-macOS-${VERSION}
chflags -h uchg /Users/sftnight/ROOT-CI
ls -lOa /Volumes/build_drive/ROOT-macOS-${VERSION}
ls -lOa /Users/sftnight/ROOT-CI

# link the ssh public key from the host to the VM for scripting
mkdir /Users/sftnight/.ssh
ln -s /Volumes/My\ Shared\ Files/Home/.ssh/parallels_vm_key.pub /Users/sftnight/.ssh/authorized_keys
sudo chown -R sftnight:staff /Users/sftnight/.ssh
