CURRENT_VM_NAME=$1
HOST_NAME=$(scutil --get ComputerName)
STORAGE_VM_NAME="${CURRENT_VM_NAME#${HOST_NAME}-}"
TEAM=$(echo "$STORAGE_VM_NAME" | cut -d'-' -f1)
USER_DIR=/Users/sftnight
PARALLELS_DIR=$USER_DIR/Parallels
S3_BUCKET=s3://macvmstorage



# CLEAN SECRETS FROM VM BEFORE UPLOADING:
# REMOVE PAT from VM
prlctl start $1
sleep 5
prlctl exec $1 'sudo rm /Users/sftnight/.PAT'
sleep 1
prlctl stop $CURRENT_VM_NAME --kill
sleep 5

prlctl clone "$CURRENT_VM_NAME" --name "$STORAGE_VM_NAME"
SNAPSHOTS=$(prlctl snapshot-list "$STORAGE_VM_NAME" -t | tr -d '*' | tr -d '{}' | tr ' ' '\n' | grep -v '^$')
if [[ -z "$SNAPSHOTS" ]]; then
  echo "No snapshots found."
else
  echo "Found snapshots:"
  echo "$SNAPSHOTS"

  for SNAP in $SNAPSHOTS; do
    echo "Deleting snapshot $SNAP..."
    prlctl snapshot-delete "$VM_NAME" -i "$SNAP"
  done
fi
zip -r /Users/sftnight/Parallels/"$STORAGE_VM_NAME".zip /Users/sftnight/Parallels/"$STORAGE_VM_NAME".macvm

prlctl unregister $STORAGE_VM_NAME
rm -rf /Users/sftnight/Parallels/"$STORAGE_VM_NAME".macvm

/Users/sftnight/Library/Python/3.9/bin/s3cmd put $PARALLELS_DIR/$STORAGE_VM_NAME.zip $S3_BUCKET/$TEAM/$STORAGE_VM_NAME.zip
