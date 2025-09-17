unlockAll() {
  for file in $PARALLELS_DIR/*; do
    chflags nouchg "$file"
  done
}
PARALLELS_DIR=/Users/sftnight/Parallels
unlockAll
