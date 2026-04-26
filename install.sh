#!/bin/bash
cp "$(dirname "$0")/litellm_config.yaml" "$(dirname "$0")/setenv" "${1:-$HOME}"
