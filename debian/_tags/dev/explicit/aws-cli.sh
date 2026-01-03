log "Installing AWS CLI (official installer)..."

# Docs: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# We use the official bundled installer so we get the latest AWS CLI release
# published by AWS at their installer URL (not the distro package, and not
# the Python/pip-based CLI v1).

arch="$(uname -m)"
case "$arch" in
  x86_64)
    url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    ;;
  aarch64|arm64)
    url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
    ;;
  *)
    die "Unsupported architecture for AWS CLI installer: $arch"
    ;;
esac

sudo_run apt-get install -y unzip

tmp_dir="$(mktemp -d)"
zip_path="$tmp_dir/awscli.zip"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

log "Downloading: $url"
fetch_url "$url" >"$zip_path"

log "Unpacking installer..."
run unzip -q "$zip_path" -d "$tmp_dir"

log "Running installer..."
sudo_run "$tmp_dir/aws/install" --update

run aws --version

log "Done (AWS CLI)."

