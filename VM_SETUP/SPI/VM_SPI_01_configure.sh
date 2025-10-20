VM_NAME=$1

# RENAME VM INTERNALLY
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# PARTITION build_drive IF NECESSARY
if [ -d /Volumes/build_drive ]; then
  echo "build_drive exists."
else
  DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
  diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%
fi

# CREATE DIRECTORIES
VM_NAME=$(scutil --get ComputerName)
VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')

mkdir -p /Volumes/build_drive/SPI-macOS-${VERSION}
ln -s  /Volumes/build_drive/SPI-macOS-${VERSION} /Users/sftnight/build
chown -R sftnight:staff /Users/sftnight/build
chown -R sftnight:staff /Volumes/build_drive/SPI-macOS-${VERSION}

# LINK SSH KEY FROM HOST TO VM FOR SCRIPTING
mkdir /Users/sftnight/.ssh
ln -s /Volumes/My\ Shared\ Files/Home/.ssh/authorized_keys /Users/sftnight/.ssh/authorized_keys
ln -s /Volumes/My\ Shared\ Files/Home/.ssh/parallels_vm_key /Users/sftnight/.ssh/parallels_vm_key
sudo chown -R sftnight:staff /Users/sftnight/.ssh

# UPDATE MACOS TO LATEST VERSION
#sudo softwareupdate -ia
