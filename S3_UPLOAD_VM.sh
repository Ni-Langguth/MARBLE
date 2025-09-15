if [ -z "$1" ]; then
  read -p "Enter the name of the VM you want to upload: " CURRENT_VM_NAME
else
  CURRENT_VM_NAME=$1
fi
HOST_NAME=$(scutil --get ComputerName)
PURE_VM_NAME="${CURRENT_VM_NAME#${HOST_NAME}-}"
STORAGE_VM_NAME="$(date +%F)-$PURE_VM_NAME"
TEAM=$(echo "$PURE_VM_NAME" | cut -d'-' -f1)
USER_DIR=/Users/sftnight
PARALLELS_DIR=$USER_DIR/Parallels
S3_BUCKET=s3://macvmstorage

if [[ $(prlctl list --no-header | wc -l) -ne 0 ]]; then
  echo "Make sure that all VMs on this machine are stopped first."
  exit
fi

# Clone VM - script leaves the original as is
prlctl clone "$CURRENT_VM_NAME" --name "$STORAGE_VM_NAME"

# REMOVE PAT
prlctl start $STORAGE_VM_NAME
sleep 15
prlctl exec $STORAGE_VM_NAME "sudo rm /Users/sftnight/.PAT"
# CLEAR ZSH_HISTORY
prlctl exec $STORAGE_VM_NAME "rm /Users/sftnight/.zsh_history && touch /Users/sftnight/.zsh_history && chmod 600 /Users/sftnight/.zsh_history"
# RENAME VM
prlctl exec $STORAGE_VM_NAME "sudo scutil --set ComputerName $STORAGE_VM_NAME"
prlctl exec $STORAGE_VM_NAME "sudo scutil --set HostName $STORAGE_VM_NAME"
sleep 1
prlctl stop $STORAGE_VM_NAME --kill
sleep 3

SNAPSHOTS=$(prlctl snapshot-list "$STORAGE_VM_NAME" -t | tr -d '*' | tr -d '{}' | tr ' ' '\n' | grep -v '^$')
echo $SNAPSHOTS
while [[ ! -z "$SNAPSHOTS" ]]; do
  if [[ -z "$SNAPSHOTS" ]]; then
    echo "No snapshots found."; break
  else
    echo "Found snapshots:"
    echo "$SNAPSHOTS"

    for SNAP in $SNAPSHOTS; do
      echo "Deleting snapshot $SNAP from VM $STORAGE_VM_NAME"
      prlctl snapshot-delete "$STORAGE_VM_NAME" -i "$SNAP"
    done
    sleep 1
    SNAPSHOTS=$(prlctl snapshot-list "$STORAGE_VM_NAME" -t | tr -d '*' | tr -d '{}' | tr ' ' '\n' | grep -v '^$')
  fi
done

# Zip clone
zip -r /Users/sftnight/Parallels/"$STORAGE_VM_NAME".zip /Users/sftnight/Parallels/"$STORAGE_VM_NAME".macvm

prlctl unregister $STORAGE_VM_NAME
rm -rf /Users/sftnight/Parallels/"$STORAGE_VM_NAME".macvm

/Users/sftnight/Library/Python/3.9/bin/s3cmd put $PARALLELS_DIR/$STORAGE_VM_NAME.zip $S3_BUCKET/$TEAM/$STORAGE_VM_NAME.zip
