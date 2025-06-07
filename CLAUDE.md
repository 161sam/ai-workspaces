# Claude Agents Guide

This document describes how to interact with Claude-based agents in this repository. It mirrors the information in `AGENTS.md` but focuses on the Anthropics Claude model.

## Project Structure

- `/scripts` – Helper scripts for installation
- `/flowise` – Flowise chatflows
- `/grafana` – Grafana configuration
- `/prometheus` – Prometheus configuration
- `/n8n` – n8n workflows and data
- `/tests` – Python tests
- Root-level utilities such as `n8n_pipe.py`

## Coding Guidelines

- Use **Python 3** with PEP 8 style
- Prefer `black` for formatting
- Document functions thoroughly

## Test Instructions

1. Install Python dependencies using `pip install -r requirements.txt`
2. Execute `pytest`

Additional Node-based tests can be run with `npm test` if present.

## Development and PR Workflow

1. Work in a feature branch
2. Run tests before pushing
3. Open a pull request against the default branch
4. Mention `@openhands-agent` or label the issue with `fix-me` to invoke the OpenHands resolver

## Available Agents

- **OpenHands Resolver** – helps triage issues using Claude
- **Claude 3.5 Sonnet** – main model for CLAUDE.md workflows
