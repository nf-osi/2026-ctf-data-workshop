# Track 2 Setup Guide

## Option A: Use the Workshop EC2 Environment (recommended)

The workshop provides a pre-configured cloud environment for each participant. You do not need to install anything.

### What you need

- A laptop with Chrome or Firefox
- The URL and password provided on your workshop credential card

### How to connect

1. Open Chrome or Firefox
2. Navigate to the URL on your credential card (looks like `http://12.34.56.78:8080/?folder=/home/ubuntu/nf-workshop`)
3. Enter the password from your credential card
4. You will see a VS Code interface running in your browser, opened to your workshop folder

### Your workshop folder

VS Code opens directly to `~/nf-workshop/`. You will see:

```
~/nf-workshop/
├── analysis.R          ← starter R script
└── data/               ← empty for now; you will download data here in Part 2
```

To open a terminal:
- Menu → Terminal → New Terminal
- Or press `` Ctrl+` ``

### Start Claude Code

From the terminal:

```bash
claude
```

You are ready to go. Start from [Part 1 of the instructions](instructions.md#part-1-understand-the-study).


[← Back to Track 2 instructions](instructions.md) | [← Back to workshop home](../README.md)
