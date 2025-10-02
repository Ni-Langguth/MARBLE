#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$DIR/vm_cycler.log"
SCRIPT="vm_cycler.sh"

if [[ $(pgrep -f ${SCRIPT}) ]]; then
  echo "${SCRIPT} running already with PID $(pgrep -f ${SCRIPT})"
  exit
else
  echo "starting cycler"
  nohup "${DIR}/${SCRIPT}" --log "${LOGFILE}" > /dev/null 2>&1 &
  echo "Started ${SCRIPT} (PID $(pgrep -f vm_cycler.sh)), logging to ${LOGFILE}"
fi
