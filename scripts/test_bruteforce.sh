#!/bin/bash
set -e
for i in $(seq 1 5); do
  curl -k -X POST https://10.20.0.10/login -d "user=test&pass=bad" || true
done
