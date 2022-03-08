#!/bin/bash
for i in $(seq 10); do
  ls */start.sh | xargs -n1 -P2 sh
done
