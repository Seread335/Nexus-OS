#!/usr/bin/env bash
set -euo pipefail

apt-get update || true
apt-get install -y git curl build-essential pkg-config libssl-dev || true

# Install rustup non-interactive
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="/root/.cargo/bin:$PATH"

# Install stable toolchain
rustup toolchain install stable
rustup default stable

# Clone and build
cd /tmp
rm -rf RustScan
git clone https://github.com/RustScan/RustScan.git
cd RustScan
cargo build --release --locked

# Copy artifact
mkdir -p /workspace/build_artifacts
cp target/release/rustscan /workspace/build_artifacts/ || true
ls -lh /workspace/build_artifacts || true
