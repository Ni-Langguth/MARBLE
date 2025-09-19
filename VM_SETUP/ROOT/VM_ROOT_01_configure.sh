VM_NAME=$1

# RENAME VM INTERNALLY
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# PARTITION build_drive IF NECESSARY
DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%

# CREATE DIRECTORIES
VM_NAME=$(scutil --get ComputerName)
VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')

  # AT THE TIME OF WRITING MACOS 26 IS THE BETA VERSION, PLEASE KEEP UP TO DATE ONCE IT LEAVES THE BETA STATE (REMOVE 26 OR COMMENT THIS OUT - ADD THE NEW VERSION ONCE THERE IS A NEW BETA...)
if [[ ${VERSION}=="26" ]]; then
  PRIMARY_MAC_OS_VERSION=beta
fi

mkdir -p /Volumes/build_drive/ROOT-macOS-${VERSION}/ROOT-CI
mkdir -p /Volumes/build_drive/ROOT-macOS-${VERSION}/_work
ln -s  /Volumes/build_drive/ROOT-macOS-${VERSION}/ROOT-CI /Users/sftnight/ROOT-CI
chown -R sftnight:staff /Users/sftnight/ROOT-CI
chown -R sftnight:staff /Volumes/build_drive/ROOT-macOS-${VERSION}
chflags -h uchg /Users/sftnight/ROOT-CI

# LINK SSH KEY FROM HOST TO VM FOR SCRIPTING
mkdir /Users/sftnight/.ssh
ln -s /Volumes/My\ Shared\ Files/Home/.ssh/authorized_keys /Users/sftnight/.ssh/authorized_keys
sudo chown -R sftnight:staff /Users/sftnight/.ssh

# UPDATE MACOS TO LATEST VERSION
#sudo softwareupdate -ia
