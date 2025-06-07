# AI Agents Guide

This repository uses ChatGPT-compatible agents to automate tasks and handle pull requests. The sections below summarize the project layout, coding style, testing steps, and the expected development workflow.

## Project Structure

- **/scripts** – Shell scripts used for installation and maintenance
- **/flowise** – Example Flowise chatflow definitions
- **/grafana** – Grafana dashboards and provisioning
- **/prometheus** – Prometheus configuration
- **/n8n** – n8n data and import scripts
- **/tests** – Python test suite
- Key Python utilities live at the repository root, e.g. `start_services.py` and `n8n_pipe.py`

## Coding Guidelines

- Write code in **Python 3** and follow **PEP 8** conventions
- Format code with **black** and check style with **flake8** if available
- Keep shell scripts POSIX-compatible
- Document public functions with clear docstrings

## Test Instructions

1. Install dependencies from `requirements.txt`
2. Run `pytest` from the repository root

Node-based services such as n8n can be tested with `npm test` where applicable, though no Node tests currently exist.

## Development and PR Workflow

1. Create a feature branch and commit changes with descriptive messages
2. Ensure `pytest` passes before opening a pull request
3. Pull requests should target the default branch and include a brief summary of changes
4. Mention `@openhands-agent` or apply the **fix-me** label to trigger automated triage by OpenHands

### Repository Secrets

The following repository secrets are expected for the OpenHands workflow:

- `LLM_MODEL`
- `OPENHANDS_MAX_ITER`
- `OPENHANDS_MACRO`
- `TARGET_BRANCH`
- `TARGET_RUNNER`

These secrets should be configured in your GitHub repository settings.

## Available Agents

- **OpenHands Resolver** – GitHub Action responding to issues and comments
- **ChatGPT** – default model for tasks defined in this AGENTS.md
