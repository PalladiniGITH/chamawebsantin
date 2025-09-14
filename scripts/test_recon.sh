#!/bin/bash
set -e
nmap -Pn -sS -sV 10.20.0.10
nmap -Pn 10.10.0.1
