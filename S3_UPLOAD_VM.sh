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
  if [[ $(prlctl list --no-header | grep $CURRENT_VM_NAME | wc -l) -eq 0 ]]; then
    echo "stop other VMs first"
    exit
  fi
else
  prlctl start $CURRENT_VM_NAME
  sleep 20
fi

# Clone VM - script leaves the original as is
if [ -d $STORAGE_VM_NAME ]; then
  prlctl unregister $STORAGE_VM_NAME
  rm -rf $PARALLELS_DIR/$STORAGE_VM_NAME.macvm
fi

# REMOVE PAT FROM ORIGINAL
if [[ ${TEAM} == "ROOT"  ]]; then
  PAT=$(prlctl exec $CURRENT_VM_NAME "cat /Users/sftnight/.PAT")
  prlctl exec $CURRENT_VM_NAME "sudo rm /Users/sftnight/.PAT"
  prlctl exec $CURRENT_VM_NAME "if [ -f /Users/sftnight/.PAT ]; then echo '.PAT still exists'; else echo '.PAT was removed successfully'; fi"
fi

# CLEAR ZSH_HISTORY
prlctl exec $CURRENT_VM_NAME "rm /Users/sftnight/.zsh_history && touch /Users/sftnight/.zsh_history && chmod 600 /Users/sftnight/.zsh_history && sudo chown sftnight:staff /Users/sftnight/.zsh_history"
prlctl exec $CURRENT_VM_NAME "sudo scutil --set ComputerName $STORAGE_VM_NAME"
prlctl exec $CURRENT_VM_NAME "sudo scutil --set HostName $STORAGE_VM_NAME"
prlctl exec $CURRENT_VM_NAME "sudo scutil --get ComputerName"
prlctl exec $CURRENT_VM_NAME "sudo scutil --get HostName"
sleep 1
prlctl stop $CURRENT_VM_NAME --kill
sleep 5

# CREATE CLONE WITHOUT PAT
prlctl clone "$CURRENT_VM_NAME" --name "$STORAGE_VM_NAME"

# PUT PAT BACK ON ORIGINAL AND CHANGE NAMES BACK
prlctl start $CURRENT_VM_NAME
sleep 20
if [[ ${TEAM} == "ROOT"  ]]; then
  prlctl exec $CURRENT_VM_NAME "echo $PAT > /Users/sftnight/.PAT"
  prlctl exec $CURRENT_VM_NAME "if [ -f /Users/sftnight/.PAT ]; then echo '.PAT was replaced successfully'; else echo '.PAT is missing from original'; fi"
fi
# RENAME VM
prlctl exec $CURRENT_VM_NAME "sudo scutil --set ComputerName $CURRENT_VM_NAME"
prlctl exec $CURRENT_VM_NAME "sudo scutil --set HostName $CURRENT_VM_NAME"
sleep 1
prlctl stop $CURRENT_VM_NAME --kill
sleep 3

# REMOVE SNAPSHOTS FROM CLONE
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
cd /Users/sftnight/Parallels && zip -r "$STORAGE_VM_NAME".zip "$STORAGE_VM_NAME".macvm

prlctl unregister $STORAGE_VM_NAME
rm -rf /Users/sftnight/Parallels/"$STORAGE_VM_NAME".macvm

/Users/sftnight/Library/Python/3.9/bin/s3cmd put $PARALLELS_DIR/$STORAGE_VM_NAME.zip $S3_BUCKET/$TEAM/$STORAGE_VM_NAME.zip
