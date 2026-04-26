# Claude Code + LiteLLM Hybrid Routing Setup

## What this is
This repository provides an example hybrid routing configuration that connects Claude Code to a LiteLLM proxy, allowing for multiple back‑ends such as OpenRouter or a local LM Studio instance.

## Screenshots
![Claude custom models](/doc/Claude-custom-models.png)

## Prerequisites
- Python 3.9+ and `pip`
- LiteLLM package (`pip install litellm`)
- MacOS/Linux/WSL
- See the [LiteLLM quick‑start guide](https://docs.litellm.ai/docs/proxy/quick_start) for installation details.
## Installation

```bash
curl -LO https://raw.githubusercontent.com/cuzfrog/claude-code-litellm-hybrid-setup/main/litellm_config.yaml \
     -O https://raw.githubusercontent.com/cuzfrog/claude-code-litellm-hybrid-setup/main/setenv
```

## Config
- **OpenRouter** – `OPENROUTER_API_KEY` to be set in the environment.
- **LM Studio** – See [doc/LOCAL_AI.md](doc/LOCAL_AI.md) for a local hardware/model example.
- The `anthropic/` prefix tells LiteLLM to speak the Anthropic API contract.
- `api_base` point to the Anthropic compatible endpoints.

## Start the proxy
```bash
litellm --config litellm_config.yaml
```
This launches the LiteLLM proxy on the default port (`4000`).

## Configure for Claude Code
```bash
. ./setenv
claude
```
Source the `setenv` script before invoking Claude Code. It sets environment variables such as `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, and `CLAUDE_CODE_SUBAGENT_MODEL` to point at the proxy.

## AI‑assisted setup prompt
You can ask an AI assistant to tailor this configuration to your own environment. Example prompt:
```
I have a local LM Studio server running at http://my‑local‑host:8000. Please modify the `litellm_config.yaml` and `setenv` script so Claude Code routes to this endpoint.
```

