#!/usr/bin/env bash
set -Eeuo pipefail

export NIX_CONFIG="experimental-features = nix-command flakes"

DISK="/dev/nvme0n1"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="/mnt"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this installer as root: sudo bash ./install.sh" >&2
  exit 1
fi

if [[ ! -b ${DISK} ]]; then
  echo "Expected installation disk ${DISK} was not found." >&2
  exit 1
fi

if [[ ! -f ${REPO_ROOT}/flake.nix ]]; then
  echo "flake.nix was not found in ${REPO_ROOT}." >&2
  exit 1
fi

echo "==> Target disk"
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN "${DISK}"
echo
echo "==> Other disks (these are NOT referenced by Disko)"
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN | grep -v "$(basename "${DISK}")" || true

echo
echo "==> Locking and evaluating the configuration before disk changes"
cd "${REPO_ROOT}"
nix flake lock
nix flake check --no-build --show-trace

echo
printf 'This permanently erases every partition on %s.\n' "${DISK}"
printf 'The expected model is ADATA LEGEND 960, approximately 1 TB.\n'
printf 'The Kingston USB drive /dev/sda must remain untouched.\n\n'
read -r -p "Type exactly 'ERASE /dev/nvme0n1' to continue: " confirmation

if [[ ${confirmation} != "ERASE /dev/nvme0n1" ]]; then
  echo "Confirmation did not match. Nothing was erased."
  exit 1
fi

umount -R "${TARGET}" 2>/dev/null || true
mkdir -p "${TARGET}"

echo "==> Partitioning, formatting and mounting ${DISK}"
nix run .#disko -- \
  --mode destroy,format,mount \
  "${REPO_ROOT}/hosts/desktop/disko.nix"

echo "==> Copying this repository to ${TARGET}/etc/nixos"
mkdir -p "${TARGET}/etc/nixos"
cp -a "${REPO_ROOT}/." "${TARGET}/etc/nixos/"
rm -f "${TARGET}/etc/nixos/result"

echo "==> Installing NixOS"
nixos-install --flake "${TARGET}/etc/nixos#desktop"

echo "==> Set the password for user mart"
nixos-enter --root "${TARGET}" -c 'passwd mart'

nixos-enter --root "${TARGET}" -c 'chown -R mart:users /etc/nixos'

echo
echo "Installation complete. Review the output above, then run: reboot"
