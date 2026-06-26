FROM node:22-bookworm

# Install system dependencies (curl for Goose download, git for agents, sudo for user)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    bzip2 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install agent CLIs (npm)
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g @openai/codex
RUN npm install -g @google/gemini-cli
RUN npm install -g opencode-ai
RUN npm install -g @mariozechner/pi-coding-agent
RUN npm install -g @github/copilot
RUN npm install -g @kilocode/cli

# Create daytona user (non-root) - Claude Code refuses to run as root
RUN useradd -m -s /bin/bash daytona || true \
    && echo 'daytona ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Kimi Code CLI (Moonshot) - shell-script installer, not npm.
# KIMI_NO_MODIFY_PATH avoids the installer editing .profile; PATH is set via .bashrc below.
RUN export HOME=/home/daytona KIMI_NO_MODIFY_PATH=1 \
    && curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash \
    && chown -R daytona:daytona /home/daytona/.kimi-code

# Install tokscale (token/cost metering). Binary embeds at build time
# via @tokscale/cli's platform optionalDependency - no runtime download.
RUN npm install -g tokscale@3.1.2

# Install Goose binary (not available via npm)
RUN mkdir -p /home/daytona/.local/bin /tmp/goose_tmp \
    && curl -fsSL "https://github.com/block/goose/releases/download/stable/goose-x86_64-unknown-linux-gnu.tar.bz2" \
    | tar -xjf - --no-same-owner --no-same-permissions -C /tmp/goose_tmp \
    && mv /tmp/goose_tmp/goose /home/daytona/.local/bin/goose \
    && chmod +x /home/daytona/.local/bin/goose \
    && rm -rf /tmp/goose_tmp

# Create required directories
RUN mkdir -p /home/daytona/.gemini /home/daytona/.config/goose /home/daytona/project \
    && chown -R daytona:daytona /home/daytona

# Pre-install ws + node-pty for the daytona-terminal pty server
RUN mkdir -p /opt/pty-server \
    && cd /opt/pty-server \
    && npm install --prefix /opt/pty-server ws@^8.18.0 node-pty@^1.0.0 \
    && chown -R daytona:daytona /opt/pty-server

# Set up PATH for daytona user
RUN echo 'export PATH="$HOME/.local/bin:$HOME/.kimi-code/bin:$PATH"' >> /home/daytona/.bashrc

USER daytona
WORKDIR /home/daytona/project

CMD ["sleep", "infinity"]
