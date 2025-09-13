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

