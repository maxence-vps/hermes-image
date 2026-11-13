# Hermes Agent + Claude Code CLI (subscription auth) + GitHub HTTPS auth.
# Keeps the official entrypoint (s6) untouched: everything is baked at build time.
ARG HERMES_VERSION=latest
FROM nousresearch/hermes-agent:${HERMES_VERSION}

USER root

# --- Claude Code CLI ---------------------------------------------------------
# Installed system-wide; updates come from image rebuilds (auto-updater disabled
# because the hermes user can't write to /usr/local).
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g --allow-scripts=@anthropic-ai/claude-code \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force \
 && mv /usr/local/bin/claude /usr/local/bin/claude-real \
 && claude-real --version

# Wrapper: always use the subscription (CLAUDE_CODE_OAUTH_TOKEN), never bill an API key
# even if ANTHROPIC_API_KEY is set for Hermes' own model.
RUN printf '%s\n' \
        '#!/bin/sh' \
        'unset ANTHROPIC_API_KEY' \
        'exec /usr/local/bin/claude-real "$@"' \
        > /usr/local/bin/claude \
 && chmod 755 /usr/local/bin/claude
ENV DISABLE_AUTOUPDATER=1

# --- GitHub over HTTPS ---------------------------------------------------------
# Token is read from $GITHUB_TOKEN at use time, never written to disk.
RUN git config --system credential.https://github.com.helper \
        '!f() { test "$1" = get || exit 0; echo username=x-access-token; echo "password=$GITHUB_TOKEN"; }; f' \
 && git config --system --add safe.directory '/workspace/*'

# --- Workspace for cloned repos --------------------------------------------
# A fresh named volume mounted here inherits this ownership.
RUN mkdir -p /workspace && chown 10000:10000 /workspace

LABEL org.opencontainers.image.description="Hermes Agent with Claude Code CLI and GitHub auth"
