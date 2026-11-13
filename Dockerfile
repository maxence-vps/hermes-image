# Hermes Agent + Claude Code CLI (subscription auth) + GitHub HTTPS auth.
# Keeps the official entrypoint (s6) untouched: everything is baked at build time.
ARG HERMES_VERSION=latest
FROM nousresearch/hermes-agent:${HERMES_VERSION}

USER root

# --- Claude Code CLI ---------------------------------------------------------
# Installed system-wide; updates come from image rebuilds (auto-updater disabled
# because the hermes user can't write to /usr/local).
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g --prefix /opt/claude-code \
        --allow-scripts=@anthropic-ai/claude-code \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force \
 && /opt/claude-code/bin/claude --version

# Wrapper: always use the subscription (CLAUDE_CODE_OAUTH_TOKEN), never bill an API key
# even if ANTHROPIC_API_KEY is set for Hermes' own model.
RUN printf '%s\n' \
        '#!/bin/sh' \
        'unset ANTHROPIC_API_KEY' \
        'exec /opt/claude-code/bin/claude "$@"' \
        > /usr/local/bin/claude \
 && chmod 755 /usr/local/bin/claude \
 && /usr/local/bin/claude --version
ENV DISABLE_AUTOUPDATER=1

# --- GitHub CLI ----------------------------------------------------------------
# Official apt repo. gh authenticates from $GH_TOKEN automatically.
RUN mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/* \
 && gh --version

# --- GitHub auth ---------------------------------------------------------------
# Hermes strips GH_TOKEN/GITHUB_TOKEN from the commands it runs, so gh is logged in
# at every start from the token (s6 cont-init) and git uses gh as credential helper.
COPY --chmod=755 rootfs/etc/cont-init.d/03-github-auth /etc/cont-init.d/03-github-auth
RUN git config --system --add safe.directory '/workspace/*'

# --- Workspace for cloned repos --------------------------------------------
# A fresh named volume mounted here inherits this ownership.
RUN mkdir -p /workspace && chown 10000:10000 /workspace

LABEL org.opencontainers.image.description="Hermes Agent with Claude Code CLI and GitHub auth"
