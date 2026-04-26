# Claude Code + LiteLLM Hybrid Routing Setup

## What this is
This repository provides a ready‑to‑use hybrid routing configuration that connects Claude Code to a LiteLLM proxy, which in turn can route requests to multiple back‑ends such as OpenRouter or a local LM Studio instance.

## Screenshots
![Claude custom models](/doc/Claude-custom-models.png)

## Prerequisites
- Python 3.9+ and `pip`
- LiteLLM package (`pip install litellm`)
- WSL/Linux environment (Windows not officially supported)
- See the [LiteLLM quick‑start guide](https://docs.litellm.ai/docs/proxy/quick_start) for installation details.
## Installation

Clone the repo and run `install.sh` from your target directory:
```bash
cd /your/target/dir
bash /path/to/repo/install.sh
```
Copies `litellm_config.yaml` and `setenv` into the current directory.

## Supported backends
- **OpenRouter** – uses Anthropic‑compatible API contract via the `anthropic/` prefix.
- **LM Studio (local)** – runs on `http://localhost:1234` and is exposed through LiteLLM. See [doc/LOCAL_AI.md](doc/LOCAL_AI.md) for local hardware/model details.

## Config
- The `anthropic/` prefix forces LiteLLM to speak the Anthropic API contract required by Claude Code.
- `api_base` fields point to the appropriate backend endpoints. The local LM Studio endpoint has been changed to `http://localhost:1234`.

## Start the proxy
```bash
litellm --config litellm_config.yaml
```
This launches the LiteLLM proxy on the default port (`4000`).

## Configure Claude Code
```bash
. ./setenv
```
Source the `setenv` script before invoking Claude Code. It sets environment variables such as `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, and `CLAUDE_CODE_SUBAGENT_MODEL` to point at the proxy.

## AI‑assisted setup prompt
You can ask an AI assistant to tailor this configuration to your own environment. Example prompt:
```
I have a local LM Studio server running at http://my‑local‑host:8000. Please modify the `litellm_config.yaml` and `setenv` script so Claude Code routes to this endpoint.
```

