# This script is supposed to be run on the VM you are configuring. It creates some directory structures and installs the necessary system packages.
# Double-check the versions of the specified software to be installed - especially gfortran - because it might differ between macOS versions.

# The VM mounts the Home Directory of the Host automatically and can access the scripts stored there
SHARED_MARBLE_DIR="/Volumes/My Shared Files/Home/MARBLE"


HOME=/Users/sftnight

export VM_NAME=$1

# versions of system installs
export XQUARTZ_VERSION=2.8.1
export CMAKE_VERSION=4.0.3
export NINJA_VERSION=1.10.2

# Download and install gfortran
install_gfortran(){
  cd /Users/sftnight

  curl -O -L https://github.com/fxcoudert/gfortran-for-macOS/releases/download/$STRING1/$STRING2.dmg
  hdiutil attach $STRING2.dmg
  sudo installer -pkg /Volumes/$STRING2/gfortran.pkg -target /
#    curl -O -L https://github.com/fxcoudert/gfortran-for-macOS/releases/download/${GFORTRAN_VERSION}-${macos_vers}/gfortran-${GFORTRAN_VERSION}-ARM-${Macos_Vers}.dmg
#    hdiutil attach gfortran-${GFORTRAN_VERSION}-ARM-${Macos_Vers}.dmg
#    sudo installer -pkg /Volumes/gfortran-${GFORTRAN_VERSION}-ARM-${Macos_Vers}/gfortran.pkg -target /
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
  14) echo 14; export STRING1=14.2-sonoma; export STRING2=gfortran-ARM-14.2-Sonoma; install_gfortran ;;
  15) echo 15; export STRING1=14.2-sequoia; export STRING2=gfortran-14.2-ARM-Sequoia; install_gfortran ;;
  26) echo 26; export STRING1=13.2-sonoma; export STRING2=gfortran-ARM-13.2-Sonoma; install_gfortran   ;;
esac
# 13 -> 12.2.0
# https://github.com/fxcoudert/gfortran-for-macOS/releases/download/12.2-ventura/gfortran-ARM-12.2-Ventura.dmg
# STRING1=12.2.0-ventura
# STRING2=gfortran-ARM-12.2.0-Ventura
# 14 -> 14.2.0
# https://github.com/fxcoudert/gfortran-for-macOS/releases/download/14.2-sonoma/gfortran-ARM-14.2-Sonoma.dmg
# STRING1=14.2.0-sonoma
# STRING2=gfortran-ARM-14.2.0-Sonoma
# 15 -> 14.2.0
# https://github.com/fxcoudert/gfortran-for-macOS/releases/download/14.2-sequoia/gfortran-14.2-ARM-Sequoia.dmg
# STRING1=14.2.0-sequoia
# STRING2=gfortran-14.2.0-ARM-Sequoia
# 26 -> 13.2.0 ???
# https://github.com/fxcoudert/gfortran-for-macOS/releases/download/13.2-sonoma/gfortran-ARM-13.2-Sonoma.dmg





# Download and install java

cd /Users/sftnight
curl -L -O https://cdn.azul.com/zulu/bin/zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg
hdiutil attach zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg 
sudo installer -pkg /Volumes/Azul\ Zulu\ JDK\ 17.60+17/Double-Click\ to\ Install\ Azul\ Zulu\ JDK\ 17.pkg -target /
hdiutil detach /Volumes/Azul\ Zulu\ JDK\ 17.60+17
rm -rf zulu17.60.17-ca-jdk17.0.16-macosx_aarch64.dmg


# Download and install macports

cd /Users/sftnight
curl -O https://distfiles.macports.org/MacPorts/MacPorts-2.11.4.tar.bz2
tar xf MacPorts-2.11.4.tar.bz2
cd MacPorts-2.11.4
./configure
make
sudo make install
echo "export PATH=\$PATH:/opt/local/bin" >> /Users/sftnight/.zshrc
echo "export PATH=\$PATH:/opt/local/bin" >> /Users/sftnight/.profile
export PATH=$PATH:/opt/local/bin
sudo port selfupdate
rm -rf /Users/sftnight/MacPorts*


# Download and install XQuartz

cd /Users/sftnight
echo ${XQUARTZ_VERSION}
curl -O -L https://github.com/XQuartz/XQuartz/releases/download/XQuartz-${XQUARTZ_VERSION}/XQuartz-${XQUARTZ_VERSION}.dmg
hdiutil attach XQuartz-${XQUARTZ_VERSION}.dmg
sudo installer -pkg /Volumes/XQuartz-${XQUARTZ_VERSION}/XQuartz.pkg -target /
echo "export PATH=\$PATH:/opt/X11/bin" >> /Users/sftnight/.zshrc
echo "export PATH=\$PATH:/opt/X11/bin" >> /Users/sftnight/.profile
export PATH=$PATH:/opt/X11/bin
hdiutil detach /Volumes/XQuartz-*
rm -rf /Users/sftnight/XQuartz*

# Download and install cmake

cd /Users/sftnight
curl -LO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo hdiutil attach /Users/sftnight/cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo cp -R /Volumes/cmake-${CMAKE_VERSION}-macos-universal/CMake.app /Volumes/cmake-${CMAKE_VERSION}-macos-universal/Applications/
hdiutil detach /Volumes/cmake-${CMAKE_VERSION}-macos-universal
rm cmake-${CMAKE_VERSION}-macos-universal.dmg
sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install


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


# Install things from port

sudo /opt/local/bin/port install ccache protobuf-c giflib libpng libjpeg-turbo tiff curl-ca-bundle libxml2 nlohmann-json libmpc


# Configure ccache

echo "export CCACHE_DIR=/Volumes/build_drive/ccache" >> /Users/sftnight/.zshrc
echo "export CCACHE_TEMPDIR=/Volumes/build_drive/ccache/tmp" >> /Users/sftnight/.zshrc
echo "export CCACHE_DIR=/Volumes/build_drive/ccache" >> /Users/sftnight/.profile
echo "export CCACHE_TEMPDIR=/Volumes/build_drive/ccache/tmp" >> /Users/sftnight/.profile
export CCACHE_DIR=/Volumes/build_drive/ccache
export CCACHE_TEMPDIR=/Volumes/build_drive/ccache/tmp
/opt/local/bin/ccache -M 20GB


# Install and link python packages from pip

export PATH=$PATH:/Users/sftnight/Library/Python/3.9/bin
echo "export PATH=\$PATH:/Users/sftnight/Library/Python/3.9/bin" >> /Users/sftnight/.zshrc
echo "export PATH=\$PATH:/Users/sftnight/Library/Python/3.9/bin" >> /Users/sftnight/.profile

sudo -u sftnight HOME=/Users/sftnight mkdir -p /Users/sftnight/Library/Python/3.9/lib/python/site-packages
sudo -u sftnight HOME=/Users/sftnight python3 -m pip install --upgrade pip
sudo -u sftnight HOME=/Users/sftnight python3 -m pip install --force-reinstall --user --no-cache-dir -r "${SHARED_MARBLE_DIR}/VM_SETUP/ROOT/requirements.txt" openstacksdk==1.4.0 onnx==1.15.0 xgboost==2.0.3 urllib3==1.26.20

sudo ln -s /Users/sftnight/Library/Python/3.9/bin/ipython /usr/local/bin/ipython
sudo ln -s /Users/sftnight/Library/Python/3.9/bin/ipython3 /usr/local/bin/ipython3
sudo ln -s /Users/sftnight/Library/Python/3.9/bin/jupyter /usr/local/bin/jupyter
