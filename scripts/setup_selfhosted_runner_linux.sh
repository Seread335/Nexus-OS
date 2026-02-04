#!/bin/bash
# Setup GitHub Actions self-hosted runner on Linux (Ubuntu/Debian/Arch)
# Usage: bash setup_selfhosted_runner_linux.sh <RUNNER_TOKEN> <RUNNER_NAME> <GITHUB_REPO_URL>

set -e

RUNNER_TOKEN="${1:?Usage: $0 <RUNNER_TOKEN> [RUNNER_NAME] [GITHUB_REPO_URL]}"
RUNNER_NAME="${2:-nexus-runner-$(hostname)}"
GITHUB_REPO="${3:?GitHub repo URL required (e.g., https://github.com/user/repo)}"
RUNNER_DIR="/opt/actions-runner"
RUNNER_USER="ghrunner"
RUNNER_GROUP="ghrunner"

echo "=== GitHub Actions Self-Hosted Runner Setup (Linux) ==="
echo "Token: ${RUNNER_TOKEN:0:10}...***"
echo "Runner Name: $RUNNER_NAME"
echo "Repo: $GITHUB_REPO"
echo "Install Dir: $RUNNER_DIR"
echo ""

# Step 1: Create runner user and group (if not exists)
if ! id "$RUNNER_USER" &>/dev/null; then
  echo "[1/6] Creating user '$RUNNER_USER'..."
  sudo useradd -r -s /bin/bash -d "$RUNNER_DIR" "$RUNNER_USER" || true
  sudo groupadd -r "$RUNNER_GROUP" || true
else
  echo "[1/6] User '$RUNNER_USER' already exists."
fi

# Step 2: Create runner directory
echo "[2/6] Creating runner directory..."
sudo mkdir -p "$RUNNER_DIR"
sudo chown -R "$RUNNER_USER:$RUNNER_GROUP" "$RUNNER_DIR"

# Step 3: Download latest runner release
echo "[3/6] Downloading latest GitHub Actions runner..."
cd "$RUNNER_DIR" || exit 1
sudo -u "$RUNNER_USER" bash -c '
  RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d'"'"'"'"'"'"'"'"' -f4 | sed "s/v//")
  RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  echo "Downloading runner v${RUNNER_VERSION}..."
  curl -L -o actions-runner.tar.gz "$RUNNER_URL" || {
    echo "Failed to download runner; trying fallback..."
    # Fallback to a known stable version
    curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
  }
  tar xzf actions-runner.tar.gz
  rm actions-runner.tar.gz
'

# Step 4: Install dependencies
echo "[4/6] Installing runner dependencies..."
sudo apt-get update >/dev/null 2>&1 || sudo pacman -Sy >/dev/null 2>&1 || true
if command -v apt-get &>/dev/null; then
  sudo apt-get install -y curl git libssl-dev libicu-dev zlib1g-dev >/dev/null 2>&1
elif command -v pacman &>/dev/null; then
  sudo pacman -S --noconfirm curl git openssl icu zlib >/dev/null 2>&1
fi

# Step 5: Configure runner
echo "[5/6] Configuring runner (this may prompt for input)..."
sudo -u "$RUNNER_USER" bash -c "
  cd '$RUNNER_DIR' || exit 1
  ./config.sh --url '$GITHUB_REPO' --token '$RUNNER_TOKEN' --name '$RUNNER_NAME' --work '_work' --unattended --replace
"

# Step 6: Install systemd service
echo "[6/6] Installing systemd service..."
cat > /tmp/actions-runner.service <<'SYSTEMD_EOF'
[Unit]
Description=GitHub Actions Runner Service
After=network.target

[Service]
Type=simple
User=ghrunner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

sudo mv /tmp/actions-runner.service /etc/systemd/system/actions-runner.service
sudo systemctl daemon-reload
sudo systemctl enable actions-runner.service
sudo systemctl start actions-runner.service

echo ""
echo "=== Setup Complete ==="
echo "Runner '$RUNNER_NAME' is now registered and running."
echo "Check status: sudo systemctl status actions-runner"
echo "View logs: sudo journalctl -u actions-runner -f"
echo ""
echo "The runner will appear under Settings → Actions → Runners in your GitHub repo."
