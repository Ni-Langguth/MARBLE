#!/bin/bash
SCRIPT=vm_cycler.sh

if [[ $(pgrep -f ${SCRIPT}) ]]; then
  echo "killing ${SCRIPT}"
  kill $(pgrep -f ${SCRIPT})
else
  echo "${SCRIPT} not found"
fi

