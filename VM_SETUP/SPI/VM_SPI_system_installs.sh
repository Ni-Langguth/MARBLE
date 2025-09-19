# This script is supposed to be run on the VM you are configuring. It creates some directory structures and installs the necessary system packages.

HOME=/Users/sftnight
#su - sftnight
export VM_NAME=$1

# versions of system installs
export XQUARTZ_VERSION=2.8.1
export GFORTRAN_VERSION=13.2
export CMAKE_VERSION=3.31.6
export NINJA_VERSION=1.10.2
export XROOTD_VERSION=5.7.1

# rename the VMs computer and hostname
sudo scutil --set ComputerName $VM_NAME
sudo scutil --set HostName $VM_NAME

# partition the build_drive in case this is not done yet
export DISK_NAME=$(diskutil list | grep -v \t | grep -v NAME | grep \* | grep -o 'disk[0-9]')
diskutil partitionDisk ${DISK_NAME} GPT JHFS+ build_drive 100%

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
echo "export PATH=\$PATH:/usr/local/bin" >> /Users/sftnight/.zshrc


# Download and install gfortran (depending on the Version of macOS)
install_gfortran(){
  cd /Users/sftnight

  curl -O -L https://github.com/fxcoudert/gfortran-for-macOS/releases/download/$STRING1/$STRING2.dmg
  hdiutil attach $STRING2.dmg
  sudo installer -pkg /Volumes/$STRING2/gfortran.pkg -target /
  sudo mkdir -p /usr/local/lib
  cd /usr/local/lib
  sudo ln -s ../gfortran/lib/libgfortran.5.dylib
  sudo ln -s ../gfortran/lib/libquadmath.0.dylib
  export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/gfortran/lib
  echo "export DYLD_LIBRARY_PATH=\$DYLD_LIBRARY_PATH:/usr/local/gfortran/lib" >> /Users/sftnight/.zshrc
  echo "export DYLD_LIBRARY_PATH=\$DYLD_LIBRARY_PATH:/usr/local/gfortran/lib" >> /Users/sftnight/.profile
  cd
  hdiutil detach /Volumes/gfortran*
  sudo rm -rf /Users/sftnight/gfortran*.dmg
}

export MACOS_VERSION=$(sw_vers --productVersion | sed -E 's/^([0-9]+).*/\1/')
case "$MACOS_VERSION" in
  13) echo 13; export STRING1=12.2-ventura; export STRING2=gfortran-ARM-12.2-Ventura; install_gfortran ;;
  14) echo 14; export STRING1=12.2-sonoma; export STRING2=gfortran-ARM-12.2-Sonoma; install_gfortran ;;
  15) echo 15; export STRING1=12.2-sequoia; export STRING2=gfortran-12.2-ARM-Sequoia; install_gfortran ;;
  26) echo 26; export STRING1=13.2-sonoma; export STRING2=gfortran-ARM-13.2-Sonoma; install_gfortran   ;;
esac

# xrootd
cd /Users/sftnight
export ARCH=$(uname -m)
export CLANG_VERSION=$(clang --version | grep version | sed "s/.*version //" | sed "s/\..*//")
mkdir -p /Users/sftnight/xrootd/xrootd-${XROOTD_VERSION}/build
curl -L https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz -o /Users/sftnight/xrootd/openssl-3.4.0.tar.gz
LC_ALL=C tar xzf /Users/sftnight/xrootd/openssl-3.4.0.tar.gz -C /Users/sftnight/xrootd
cd /Users/sftnight/xrootd/openssl-3.4.0 && LC_ALL=C ./Configure --prefix=/Users/sftnight/xrootd/openssl/3.4.0/
make -j 10 -C /Users/sftnight/xrootd/openssl-3.4.0
make -j 10 install -C /Users/sftnight/xrootd/openssl-3.4.0
curl -L https://xrootd.web.cern.ch/download/v${XROOTD_VERSION}/xrootd-${XROOTD_VERSION}.tar.gz -o /Users/sftnight/xrootd/xrootd-${XROOTD_VERSION}.tar.gz
LC_ALL=C tar xzf /Users/sftnight/xrootd/xrootd-${XROOTD_VERSION}.tar.gz -C /Users/sftnight/xrootd
cd /Users/sftnight/xrootd/xrootd-${XROOTD_VERSION}/build && /usr/local/bin/cmake -D OPENSSL_ROOT_DIR=/Users/sftnight/xrootd/openssl/3.4.0/ -D CMAKE_INSTALL_PREFIX=/Users/sftnight/xrootd/${XROOTD_VERSION}/arm64-mac14-clang160-opt/ ..
cd /Users/sftnight/xrootd/xrootd-${XROOTD_VERSION}/build && make install -j 10
ln -sf /Users/sftnight/xrootd/${XROOTD_VERSION}/arm64-mac14-clang160-opt /Users/sftnight/xrootd/latest
mkdir -p /Users/sftnight/xrootd/5.7.1/arm64-mac14-clang160-opt

# Download and install Xquartz
cd /Users/sftnight
curl -o /Users/sftnight/XQuartz-${XQUARTZ_VERSION}.dmg -L https://github.com/XQuartz/XQuartz/releases/download/XQuartz-${XQUARTZ_VERSION}/XQuartz-${XQUARTZ_VERSION}.dmg
hdiutil attach /Users/sftnight/XQuartz-${XQUARTZ_VERSION}.dmg
sudo installer -pkg /Volumes/XQuartz-${XQUARTZ_VERSION}/XQuartz.pkg -target /
echo "export PATH=\$PATH:/opt/X11/bin" >> /Users/sftnight/.zshrc

cp /Users/sftnight/.zshrc /Users/sftnight/.profile

