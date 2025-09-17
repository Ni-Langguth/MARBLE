lockAllExcept(){
  for file in $PARALLELS_DIR/*; do
    if [[ "$file" != "$PARALLELS_DIR/$1.macvm" && "$file" == *"macvm" ]]; then chflags uchg "$file"; fi
  done
}
PARALLELS_DIR=/Users/sftnight/Parallels
lockAllExcept $1
