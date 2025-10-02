#!/bin/bash

LOGFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)
      LOGFILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
if [[ -n "$LOGFILE" ]]; then
  exec >>"$LOGFILE" 2>&1
  echo "Logging enabled: $LOGFILE"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
trap '$DIR/.unlock_all_vms.sh; exit 130' INT

startVM() {
  log "Starting $1."
  lockAllExcept $1
  prlctl start $1 > /dev/null 2>&1
  sleep 5
  
  ATTEMPT=0
  while [[ "$(isVMon $1)" -eq 0 && $ATTEMPT -lt 10 ]]; do
    sleep 1
    ATTEMPT=$(($ATTEMPT+1))
  done
  log "ATTEMPT=${ATTEMPT}"
  if [[ $ATTEMPT -gt 9 ]]; then
    exec "$0"
  fi
  log "VM is on"

  ATTEMPT=0
  while [[ "$(pingSshVM $1)" -eq 0 && $ATTEMPT -lt 10 ]]; do
    sleep 1
    ATTEMPT=$(($ATTEMPT+1))
  done
  log "ATTEMPT=${ATTEMPT}"   
  if [[ $ATTEMPT -gt 9 ]]; then
    exec "$0"
  fi
  log "VM is reachable by ssh"

  ATTEMPT=0
  while [[ "$(isRunnerReady $1)" -eq 0 && $ATTEMPT -lt 10 ]]; do
    sleep 1
    ATTEMPT=$(($ATTEMPT+1))
  done
  log "ATTEMPT=${ATTEMPT}"   
  if [[ $ATTEMPT -gt 9 ]]; then
    exec "$0"
  fi
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
  for file in $PARALLELS_DIR/*; do
    if [[ "$file" != "$PARALLELS_DIR/$1.macvm" && "$file" == *"macvm" ]]; then chflags uchg "$file"; fi
  done
}
 
unlockAll() {
  for file in $PARALLELS_DIR/*; do
    chflags nouchg "$file"
  done
}

isVMon() {
  lsof | grep $1 | wc -l
} 

isVMGithubBusy() {
  echo $(sshOnVM $1 "pgrep -f 'Runner.Worker' >/dev/null 2>&1 && echo 1 || echo 0") 
}

isVMJenkinsBusy() {
  echo $(sshOnVM $1 "ps -ef | grep jenkins | grep -v 'grep' >/dev/null 2>&1 && echo 1 || echo 0")
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
#  INDEX=$(($RANDOM % ${#ALL_ROOT_VMS[@]}))
  INDEX=$(expr $((${INDEX}+1)) % 3)
  NEXT_VM=${ALL_ROOT_VMS[$INDEX]}
  echo $NEXT_VM
}

waitFor() {
  TIMER="$1"
  log "Waiting for $TIMER seconds."
  for ((i=1; i<=TIMER; i++)); do
    if [ -t 0 ]; then
      filled=$(printf "%${i}s" | tr ' ' '#')
      empty=$(printf "%$((TIMER - i))s")
      printf "\r[%s%s] %3ds" "$filled" "$empty" "$i"
    fi
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
PARALLELS_DIR=/Users/sftnight/Parallels
LAST_RUN_VM=
ALL_ROOT_VMS=($(listAllRootVMs))
#echo $ALL_ROOT_VMS
BUSY_SINCE=
INDEX=0

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
  if [[ $(lsof | grep macphsft | grep VM | grep macvm | wc -l) -gt 0 ]]; then
    RUNNING_VMS=$(listRunningVMs)
    log "There is a running VM on this host: ${RUNNING_VMS}"
    for RUNNING_VM in "${RUNNING_VMS[@]}"; do
#      if [[ $RUNNING_VM == *ROOT* ]]; then

#        if [[ "$(isVMGithubBusy $RUNNING_VM)" -eq 0 ]]; then
        if [[ "$(isVMJenkinsBusy $RUNNING_VM)" -eq 0 && "$(isVMGithubBusy $RUNNING_VM)" -eq 0 ]]; then
          log "${RUNNING_VM}is idle."
          LAST_RUN_VM=$RUNNING_VM
          stopVM $RUNNING_VM
          BUSY_SINCE=
        else
          if [[ -z $BUSY_SINCE ]]; then
            BUSY_SINCE=[$(date '+%Y-%m-%d %H:%M:%S')]
            log "${RUNNING_VM}is busy"
          else
            printf "\033[1A\033[2K\033[1A\033[2K\033[1A\033[2K\033[1A\033[2K"
            log "${RUNNING_VM}is busy since ${BUSY_SINCE}"
          fi
        fi

#      else
#        log "${RUNNING_VM}is not a ROOT VM. The cycler will not interfere."
#      fi
    done
    waitFor 60
  else 
    log "No VMs on this host."
    startVM $RANDOM_VM
    LAST_RUN_VM=$RANDOM_VM
    waitFor $(expr $((60 + $(($RANDOM % 60)))))
    log "Waiting period over on $RANDOM_VM! "
  fi
done
