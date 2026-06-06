---
name: code-review
description: trigger code review from codex via cursor cli and claude via claude code.
disable-model-invocation: true
allowed-tools: Bash(agent *), Bash (git *)
---

# Code Reviewer

## Instructions

When the user invokes this skill, perform a code review 

**Optional Input** $ARGUMENTS (can provide some context to the current workstream)

### Step 1: Get the diff from git

```bash
git status
git diff --stat
git diff --cached --stat
git log origin/main..HEAD --online
```

If there are no changes, tell the user and stop

### Step 2: Trigger review with via cursor agent cli

Generate a prompt asking for a code review of the changes found in the git diff.

ensure prompt requests recommended fixes

`agent {prompt} --model gpt-5.3-codex`

Also begin a subagent using Opus to also do a review passing the same prompt.

### Step 3: Compare findings between the 2 reviews

Validate the output from codex and opus and compare findings and fices.

Follow up with either if regarding discrepencies in fingings.

### Step 4: Return findings to user

Generate a table output of findings and recommended fixes for the user, order by severity.
