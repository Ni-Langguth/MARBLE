VM_NAME=$1

# RENAME VM INTERNALLY
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# PARTITION build_drive IF NECESSARY
DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%
if [ -d /Volumes/build_drive ]; then
  echo "build_drive exists."
else
  echo "build_drive does not exist, something went wrong"
  exit
fi

# CREATE DIRECTORIES
VM_NAME=$(scutil --get ComputerName)
VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')

ln -s  /Volumes/build_drive/ROOT-macOS-${VERSION} /Users/sftnight/build
chown -R sftnight:staff /Users/sftnight/build
chown -R sftnight:staff /Volumes/build_drive/ROOT-macOS-${VERSION}

# LINK SSH KEY FROM HOST TO VM FOR SCRIPTING
mkdir /Users/sftnight/.ssh
ln -s /Volumes/My\ Shared\ Files/Home/.ssh/parallels_vm_key.pub /Users/sftnight/.ssh/authorized_keys
sudo chown -R sftnight:staff /Users/sftnight/.ssh

# UPDATE MACOS TO LATEST VERSION
sudo softwareupdate -ia
