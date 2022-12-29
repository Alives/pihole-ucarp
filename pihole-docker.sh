#!/bin/bash

echo 'Waiting for CARP interface at 10.0.0.3...'
while true; do
  /sbin/ip address show dev eth0 | /bin/grep -q 10.0.0.3 && break
  /usr/bin/sleep 0.1
done
echo 'CARP interface is up.'

echo 'Starting PiHole docker in the background...'
/usr/bin/docker-compose \
  -f /opt/repos/pihole-ucarp/docker-compose.yml up -d pihole
echo 'Waiting for PiHole DNS to start up ...'
while true; do
  if out="$(dig +short +norecurse +retry=0 +timeout=1 @10.0.0.3 pi.hole)"; then
    if [[ -n "${out}" ]]; then
      break
    fi
  fi
  echo 'Still waiting for PiHole DNS to start up ...'
  sleep 1
done
echo 'PiHole started.'

echo 'Entering PiHole monitoring mode...'
while true; do
  if out="$(dig +short +norecurse +retry=0 +timeout=1 @10.0.0.3 pi.hole)"; then
    if [[ -z "${out}" ]]; then
      echo 'No output, VIP moved to router probably.'
      exit 1
    fi
    continue
  else
    echo "${out}" | grep -v '^$'
    exit 1
  fi
done
