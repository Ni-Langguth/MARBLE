# This script is supposed to be run on the VM you are configuring. It creates some directory structures and installs the necessary system packages.

env HOME=/Users/sftnight
export VM_NAME=$1

# versions of system installs
export XQUARTZ_VERSION=2.8.1
export GFORTRAN_VERSION=13.2
export CMAKE_VERSION=3.31.6
export NINJA_VERSION=1.10.2

# rename the VMs computer and hostname
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# partition the build_drive in case this is not done yet
export DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%

# create directories
export VM_NAME=$(scutil --get ComputerName)
export VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')
mkdir -p /Volumes/build_drive/SPI-macOS-${VERSION}/build
ln -s  /Volumes/build_drive/SPI-macOS-${VERSION}/build /Users/sftnight/build  
chown -R sftnight:staff /Users/sftnight/build  
chown -R sftnight:staff /Volumes/build_drive/SPI-macOS-${VERSION}
ls -lOa /Volumes/build_drive/SPI-macOS-${VERSION}
ls -lOa /Users/sftnight/build  

# Download and install java
cd /Users/sftnight
curl -L -O https://cdn.azul.com/zulu/bin/zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg
hdiutil attach zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg
sudo installer -pkg /Volumes/Azul\ Zulu\ JDK\ 17.60+17/Double-Click\ to\ Install\ Azul\ Zulu\ JDK\ 17.pkg -target /
hdiutil detach /Volumes/Azul\ Zulu\ JDK\ 17.60+17
rm -rf zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg

# Download and install ninja
cd /Users/sftnight
curl -LO https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz
tar -xzf v${NINJA_VERSION}.tar.gz
cd ninja-${NINJA_VERSION}
python3 configure.py --bootstrap
sudo mkdir -p /usr/local/bin
sudo cp ninja /usr/local/bin/
cd /Users/sftnight
rm v${NINJA_VERSION}.tar.gz
rm -rf ninja-${NINJA_VERSION}

# Download and install cmake
cd /Users/sftnight
curl -LO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo hdiutil attach /Users/sftnight/cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo cp -R /Volumes/cmake-${CMAKE_VERSION}-macos-universal/CMake.app /Volumes/cmake-${CMAKE_VERSION}-macos-universal/Applications/
hdiutil detach /Volumes/cmake-${CMAKE_VERSION}-macos-universal
rm cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install

# Download and install gfortran (depending on the Version of macOS)

# Download and install Xquartz

# xrootd

# 
