startVM() {
  log "Starting $1."
  lockAllExcept $1
  prlctl start $1 > /dev/null 2>&1
  ATTEMPT=0
#  while [[ "$(isVMon $1)" -eq 0 || "$(pingSshVM $1)" -eq 0 || "$(isRunnerReady $1)" -eq 0 || ATTEMPT -lt 10 ]]; do
  while [ true ]; do
    if [[ "$(isVMon $1)" -eq 0 || "$(pingSshVM $1)" -eq 0 || "$(isRunnerReady $1)" -eq 0 || ATTEMPT -lt 10 ]]; then break; fi
    ping $1 > /dev/null 2>&1
    sleep 1
    ATTEMPT=ATTEMPT+1
  done
#  while [[ "$(pingSshVM $1)" -eq 0 ]]; do
#    sleep 1
#  done
#  while [[ "$(isRunnerReady $1)" -eq 0 ]]; do
#    sleep 1
#  done
  log "Runner ready."
}

stopVM() {
  log "Stopping $1."
  prlctl stop $1 --kill > /dev/null 2>&1
  unlockAll
}

stopAllVMs() {
  COUNT_RUNNING_VMS=$(countRunningVMs)
  while [ $COUNT_RUNNING_VMS -ne 0 ]; do
    RUNNING_VMS=($(listRunningVMs))
    for RUNNING_VM in "${RUNNING_VMS[@]}"; do
      stopVM $RUNNING_VM
    done
    COUNT_RUNNING_VMS=$(countRunningVMs)
  done
}

lockAllExcept(){
  for file in $PARALLELSFOLDER/*; do
    if [[ "$file" != "$PARALLELSFOLDER/$1.macvm" && "$file" == *"macvm" ]]; then chflags uchg "$file"; fi
  done
}
 
unlockAll() {
  for file in $PARALLELSFOLDER/*; do
    chflags nouchg "$file"
  done
}

isVMon() {
  lsof | grep $1 | wc -l
} 

isVMGithubBusy() {
  echo $(sshOnVM $1 "pgrep -f 'Runner.Worker' >/dev/null 2>&1 && echo 1 || echo 0") 
}

pingSshVM() {
  sshOnVM $1 "echo ping >/dev/null 2>&1 && echo 1 || echo 0"
}

sshOnVM() {
  ssh -i /Users/sftnight/.ssh/parallels_vm_key -o BatchMode=yes -o StrictHostKeyChecking=no  -o IdentitiesOnly=yes $remoteUser@$1 "zsh -l -c '$2'" 
}

countRunningVMs() {
  echo $(prlctl list --no-header --output name | wc -l) 
}

listRunningVMs() {
  echo "$(prlctl list --no-header --output name | tr '\n' ' ')" 
}

listAllVMs() {
  echo "$(prlctl list -a --no-header --output name | tr '\n' ' ')"
}

listAllRootVMs() { 
  echo "$(prlctl list -a --no-header --output name | grep ROOT | tr '\n' ' ')" 
}

pickRandomRootVM() {
  RANDOM_INDEX=$(($RANDOM % ${#ALL_ROOT_VMS[@]}))
  RANDOM_VM=${ALL_ROOT_VMS[$RANDOM_INDEX]}
  echo $RANDOM_VM
}

waitFor() {
#  VM_NAME="$1"
  TIMER="$1"
  log "Waiting for $TIMER seconds."
  for ((i=1; i<=TIMER; i++)); do
    filled=$(printf "%${i}s" | tr ' ' '#')
    empty=$(printf "%$((TIMER - i))s")
    printf "\r[%s%s] %3ds" "$filled" "$empty" "$i"
    sleep 1
  done
  echo
}

log() { 
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" 
}

isRunnerReady() {
  sshOnVM $1 "pgrep -f 'Runner.Listener' >/dev/null 2>&1 && echo 1 || echo 0" 
}

log "Cycler started."

remoteUser=sftnight
PARALLELSFOLDER=/Users/sftnight/Parallels
LAST_RUN_VM=
log "listing root"
ALL_ROOT_VMS=($(listAllRootVMs))
echo $ALL_ROOT_VMS

log "picking"
RANDOM_VM=$(pickRandomRootVM)
log "picked $RANDOM_VM"
log "listing all"
log "All VMs: $(listAllVMs)"
log "All ROOT VMs: $(listAllRootVMs)"

unlockAll
while true; do
  while [[ "$RANDOM_VM" == "$LAST_RUN_VM" ]]; do
    RANDOM_VM=$(pickRandomRootVM)
  done
#  if [[ "$(ps -ef | grep prlctl | grep -v 'grep')" == "" && $(lsof | grep macphsft | grep VM | grep macvm | wc -l) -gt 0 ]]; then
  if [[ $(lsof | grep macphsft | grep VM | grep macvm | wc -l) -gt 0 ]]; then
    RUNNING_VMS=$(listRunningVMs)
    log "There is a running VM on this host: $RUNNING_VMS."
    for RUNNING_VM in "${RUNNING_VMS[@]}"; do
      if [[ $RUNNING_VM == *ROOT* ]]; then
        if [[ "$(isVMGithubBusy $RUNNING_VM)" -eq 0 ]]; then
          log "$RUNNING_VM is idle."
          LAST_RUN_VM=$RUNNING_VM
          stopVM $RUNNING_VM
        else
          log "$RUNNING_VM is busy."
        fi
      else
        log "$RUNNING_VM is not a ROOT VM. The cycler will not interfere."
      fi
    done
    waitFor 10
  else 
    log "No VMs on this host."
    startVM $RANDOM_VM
    LAST_RUN_VM=$RANDOM_VM
    waitFor 150
    log "Waiting period over on $RANDOM_VM! "
  fi
done
