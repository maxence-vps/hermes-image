# hermes-agent (custom image)

[Hermes Agent](https://github.com/NousResearch/hermes-agent) with:

- **Claude Code CLI** baked in. `claude` is a wrapper that unsets `ANTHROPIC_API_KEY`,
  so `claude -p` always runs on the subscription (`CLAUDE_CODE_OAUTH_TOKEN`).
- **GitHub over HTTPS**: git reads `$GITHUB_TOKEN` at use time (never written to disk).
- **`/workspace`** owned by the `hermes` user, for cloned repos.

The official entrypoint (s6) is untouched.

## Image

`ghcr.io/maxencemottard/hermes-agent`

| Tag | Meaning |
|---|---|
| `latest` | Last build |
| `YYYYMMDD` | Build date (use to pin / roll back) |
| `sha-<commit>` | Build from a given commit |

Rebuilt on push to `main`, every Monday (new Hermes / Claude Code releases), or manually
(*Actions → Build & push image → Run workflow*, optional Hermes base tag).

## Environment

| Variable | Purpose |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | From `claude setup-token` (subscription) |
| `GITHUB_TOKEN` / `GH_TOKEN` | Fine-grained PAT (Contents + Pull requests: read/write) |
| `ANTHROPIC_API_KEY` | Optional, Hermes' own model only (never used by `claude`) |

Plus the usual Hermes variables (API server, dashboard auth, …).
