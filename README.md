# hermes-agent (custom image)

[Hermes Agent](https://github.com/NousResearch/hermes-agent) with:

- **Claude Code CLI** baked in (`claude` on the `PATH`). Log in once by running `claude` in the
  container; the session is stored in `/opt/data/home/.claude` (HOME of Hermes commands, on the
  data volume), so it survives image updates.
- **GitHub CLI (`gh`)** for PRs, reviews, Actions runs…
- **GitHub auth at startup**: an s6 cont-init script logs `gh` in from `$GH_TOKEN` / `$GITHUB_TOKEN`
  and sets it as git's credential helper. Needed because Hermes strips these vars from the
  commands it runs. Token stored by gh in `/opt/data/home/.config/gh` (HOME of Hermes commands) and `/opt/data/.config/gh`, refreshed on every start.
- **Tailscale**: `tailscale` and `tailscaled` baked in and supervised by s6 in userspace-networking
  mode (no `/dev/net/tun` or `NET_ADMIN` cap required). State is saved in `/opt/data/.tailscale`
  (data volume) so node identity and credentials persist across image updates. SSH client config
  transparently routes `*.ts.net` and `100.*` through `tailscale nc`.
- **`/workspace`** owned by the `hermes` user, for cloned repos.

The official entrypoint (s6) is untouched.

## Image

`ghcr.io/maxence-vps/hermes-image` (named after the repo)

| Tag | Meaning |
|---|---|
| `latest` | Latest release build |
| `vX.Y.Z` / `X.Y.Z` | SemVer release tag managed by Release Please |
| `vX` / `vX.Y` | Floating major and minor release tags |
| `sha-<commit>` | Build from a given commit |

Releases and SemVer tags are automated using [Release Please](https://github.com/googleapis/release-please-action) from Conventional Commits. Images are built and published when a release PR is merged on `main`.

## Environment

| Variable | Purpose |
|---|---|
| `GITHUB_TOKEN` / `GH_TOKEN` | Fine-grained PAT (Contents + Pull requests: read/write) |
| `TS_AUTHKEY` / `TAILSCALE_AUTHKEY` | (Optional) Tailscale auth key for zero-touch auto-join |
| `TAILSCALE_HOSTNAME` | (Optional) Machine name in Tailnet (default: `hermes-agent`) |

Leave `ANTHROPIC_API_KEY` and `CLAUDE_CODE_OAUTH_TOKEN` unset: Claude Code gives them priority over
the stored login, and `ANTHROPIC_API_KEY` would bill the API instead of the subscription.

Plus the usual Hermes variables (API server, dashboard auth, …).
