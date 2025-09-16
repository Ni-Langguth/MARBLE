PARALLELSFOLDER=/Users/sftnight/Parallels

unlockAll() {
  for file in $PARALLELSFOLDER/*; do
    chflags nouchg "$file"
  done
}

unlockAll

