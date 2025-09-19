#!/bin/bash
SCRIPT=vm_cycler.sh

if [[ $(pgrep -f ${SCRIPT}) ]]; then
  echo "killing ${SCRIPT}"
  kill -9 $(pgrep -f ${SCRIPT})
else
  echo "${SCRIPT} not found"
fi

