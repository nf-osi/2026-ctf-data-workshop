# EC2 Workshop Environment — Setup Guide

This directory contains scripts to provision, launch, and tear down the EC2 instances used for Track 2 of the NF Data Workshop.

## Overview

Each participant gets their own EC2 instance (t3.medium) running code-server — VS Code accessible in a web browser. Claude Code, R, and all required packages are pre-installed. 

```
Participant browser → http://<public-ip>:8080 → code-server → terminal → Claude Code + R
```

## Prerequisites (on your local machine)

- AWS CLI installed and configured (`aws configure`) with an IAM user that has EC2 permissions
- `jq` installed (`brew install jq` on macOS)
- An Anthropic API key (injected into instances at launch time)

## Workflow

```
1. Run security-group.sh   ← once, creates the security group
2. Run build-ami.sh        ← once, builds the AMI automatically
3. Run launch.sh           ← morning of the workshop
4. Hand out credentials    ← from credentials.csv output by launch.sh
5. Run teardown.sh         ← end of day
```

## Files

| File | Purpose |
|------|---------|
| `security-group.sh` | Creates the EC2 security group for workshop instances |
| `bootstrap.sh` | Installs all software on an EC2; called by `build-ami.sh` |
| `build-ami.sh` | Launches a temp EC2, runs bootstrap, snapshots an AMI, cleans up |
| `launch.sh` | Launches N instances from the AMI; outputs credentials CSV |
| `teardown.sh` | Terminates all workshop instances by tag |
| `test-launch.sh` | Launches a single test instance |
| `test-teardown.sh` | Terminates the test instance |

## Configuration

Edit the top of `launch.sh` to set:
- `AMI_ID` — the AMI you saved after running `bootstrap.sh`
- `N_PARTICIPANTS` — number of instances to launch
- `ANTHROPIC_API_KEY` — the API key to inject into each instance
- `AWS_REGION` — your preferred region
- `SECURITY_GROUP_ID` — output of `security-group.sh`
