# Track 2 Setup Guide

## Option A: Use the Workshop EC2 Environment (recommended)

The workshop provides a pre-configured cloud environment for each participant. You do not need to install anything.

### What you need

- A laptop with Chrome or Firefox
- The URL and password provided on your workshop credential card

### How to connect

1. Open Chrome or Firefox
2. Navigate to the URL on your credential card (looks like `https://12.34.56.78:8080/?folder=/home/ubuntu/nf-workshop`)
3. You will see a browser security warning about an invalid certificate — this is expected. The server uses a self-signed certificate.
   - **Chrome:** click **Advanced**, then **Proceed to [IP address] (unsafe)**
   - **Firefox:** click **Advanced**, then **Accept the Risk and Continue**
4. Enter the password from your credential card
5. You will see a VS Code interface running in your browser, opened to your workshop folder

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

### Set up Synapse access

In Part 2 of the workshop, you will download data from the NF Data Portal using the Synapse command-line client. You need to authenticate once before this will work.

In the terminal, run:

```bash
synapse config
```

Enter your Synapse username and password when prompted. Your credentials will be saved and you will not need to enter them again.

### Start Claude Code

From the terminal:

```bash
claude
```

You are ready to go. Start from [Part 1 of the instructions](instructions.md#part-1-understand-the-study).


[← Back to Track 2 instructions](instructions.md) | [← Back to workshop home](../README.md)
