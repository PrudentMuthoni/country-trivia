# OpenCode API Key Setup Guide

This guide explains how to obtain an OpenCode Zen API key and configure it for the GitHub Actions PR review workflow.

---

## Step 1: Get an OpenCode Zen API Key

### Option A: OpenCode Console (Recommended)

1. Go to [https://opencode.ai/console](https://opencode.ai/console)
2. Sign up or log in with your GitHub account
3. Navigate to **API Keys** in the dashboard
4. Click **Create New Key**
5. Give it a name (e.g., `github-actions-pr-review`)
6. Copy the API key (starts with `sk-`)

### Option B: OpenCode Zen Direct

1. Go to [https://opencode.ai/zen](https://opencode.ai/zen)
2. Sign up for a free account
3. Navigate to **Settings** > **API Keys**
4. Generate a new key
5. Copy the API key

---

## Step 2: Add the API Key to GitHub Repository Secrets

### Via GitHub Web UI

1. Go to your repository: `https://github.com/PrudentMuthoni/country-trivia`
2. Click **Settings** (top tab)
3. In the left sidebar, click **Secrets and variables** > **Actions**
4. Click **New repository secret**
5. Fill in:
   - **Name:** `OPENCODE_API_KEY`
   - **Secret:** Paste your OpenCode API key (the `sk-...` value)
6. Click **Add secret**

### Via GitHub CLI

```bash
gh secret set OPENCODE_API_KEY --repo PrudentMuthoni/country-trivia
# Paste your API key when prompted
```

---

## Step 3: Verify the Workflow

1. The workflow is defined in `.github/workflows/pr-review.yml`
2. It triggers automatically on:
   - `pull_request` opened
   - `pull_request` synchronize (new commits pushed)
   - `pull_request` reopened
3. To test, create a new PR or push new commits to an existing PR
4. Check the **Actions** tab in your repository to see the workflow run
5. The review will be posted as a comment on the PR

---

## How It Works

```
PR opened/updated
       │
       ▼
GitHub Actions triggered
       │
       ▼
Checkout code at PR head SHA
       │
       ▼
Install OpenCode CLI
       │
       ▼
Configure with Big Pickle model
(opencode/big-pickle via Zen API)
       │
       ▼
Get PR diff (base...head)
       │
       ▼
Run OpenCode review with prompt
       │
       ▼
Post review as PR comment
```

---

## Model Details

| Property | Value |
|----------|-------|
| **Model ID** | `opencode/big-pickle` |
| **Provider** | OpenCode Zen |
| **Base URL** | `https://opencode.ai/zen/v1` |
| **Context Window** | 200,000 tokens |
| **Max Output** | 32,000 tokens |
| **Cost** | Free (during beta period) |
| **Reasoning** | Yes |

---

## Troubleshooting

### Workflow fails with "API key invalid"

- Verify the secret name is exactly `OPENCODE_API_KEY` (case-sensitive)
- Ensure the key was copied correctly (no extra spaces)
- Check the key hasn't expired in the OpenCode Console

### Workflow doesn't trigger

- Ensure the workflow file is on the `develop` branch (the default branch)
- Check that GitHub Actions is enabled in repository settings
- Verify the workflow YAML syntax is valid

### Review comment not posted

- Check the workflow logs for errors
- Ensure `GITHUB_TOKEN` has permission to write to pull requests
- Verify the PR diff is not empty

---

## Cost Considerations

Big Pickle is currently **free** during its beta period. However:

- The free period may end at any time
- Monitor your usage in the OpenCode Console
- If the free period ends, you will need to:
  - Switch to a paid Zen plan, or
  - Configure a different provider (e.g., Anthropic, OpenAI) in the workflow

---

## Updating the Model

To use a different model in the workflow, edit `.github/workflows/pr-review.yml`:

```yaml
# Change this line
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/big-pickle",  # <-- Change model here
  ...
}
EOF
```

And this line:
```bash
cat /tmp/pr-diff.txt | opencode run --pure --model "opencode/big-pickle" "..."
```

Available Zen models: [https://opencode.ai/zen](https://opencode.ai/zen)
