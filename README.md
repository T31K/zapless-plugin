# zapless-plugin

> Claude Code + OpenClaw plugin for [Zapless](https://zapless.app)

Connect your apps on the Zapless dashboard. Install this plugin. Your agent knows what to do.

## What This Does

This plugin automatically injects your Zapless skill context into every Claude Code session — no copy-pasting required.

On session start it checks:
1. Is the `zapless` CLI installed?
2. Are you authenticated?
3. What apps do you have connected?

Then injects the right commands for your connected apps into Claude's context. Nothing more.

It also watches for new apps mid-session and updates automatically.

## Requirements

- [Claude Code](https://claude.ai/code) v1.0.33+
- [Zapless CLI](https://github.com/T31K/zapless-cli) installed (`npm i -g zapless` or via installer)
- A Zapless account — [zapless.app](https://zapless.app)
- `jq` installed (`brew install jq`)

## Install

```bash
claude plugin install zapless@T31K/zapless-plugin
```

Then authenticate if you haven't already:

```bash
zapless auth login --token <your-install-token>
```

Get your token from [zapless.app/dashboard](https://zapless.app/dashboard).

## How It Works

Three hooks run automatically:

| Hook | Trigger | What it does |
|------|---------|--------------|
| `init.sh` | Session start | Checks CLI + auth, injects skill context for connected apps |
| `guard.sh` | Before any `zapless` command | Verifies auth is still valid, blocks with a clear message if not |
| `pulse.sh` | After each Claude turn | Detects newly connected or disconnected apps every 60s |

All hook output is injected silently — you won't see walls of text in your chat.

## Supported Apps

Gmail, Google Calendar, Google Drive, Google Docs, Google Sheets, Google Slides, Google Meet, GitHub, Slack, Notion

More coming as Zapless adds integrations.

## Troubleshooting

**CLI not found after installing plugin:**
```bash
curl -fsSL https://zapless.app/install.sh | sh
```

**Auth errors:**
```bash
zapless doctor
```

**Plugin not injecting context:**
Make sure you're on Claude Code v1.0.33+. Run `/reload-plugins` to force a reload.

## License

MIT
