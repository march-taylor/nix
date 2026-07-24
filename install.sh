#!/usr/bin/env bash
set -Eeuo pipefail

export NIX_CONFIG="experimental-features = nix-command flakes"

DISK="/dev/nvme0n1"
EXPECTED_MODEL="ADATA LEGEND 960"
MIN_DISK_BYTES=900000000000
MAX_DISK_BYTES=1100000000000
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="/mnt"

trap 'echo "Installation stopped at line ${LINENO}. Read the error above before retrying." >&2' ERR

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

actual_model="$(lsblk -dn -o MODEL "${DISK}" | sed 's/[[:space:]]*$//')"
actual_bytes="$(blockdev --getsize64 "${DISK}")"

if [[ ${actual_model} != *"${EXPECTED_MODEL}"* ]]; then
  echo "Refusing to continue: ${DISK} is '${actual_model}', expected '${EXPECTED_MODEL}'." >&2
  exit 1
fi

if (( actual_bytes < MIN_DISK_BYTES || actual_bytes > MAX_DISK_BYTES )); then
  echo "Refusing to continue: ${DISK} has unexpected size ${actual_bytes} bytes." >&2
  exit 1
fi

echo "==> Target disk verified"
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN "${DISK}"
echo
echo "==> Other disks (these are NOT referenced by Disko)"
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN | grep -v "$(basename "${DISK}")" || true

lock_flake() {
  local attempt
  for attempt in 1 2 3; do
    echo "==> Creating/updating flake.lock (attempt ${attempt}/3)"
    if nix flake lock; then
      return 0
    fi

    if (( attempt < 3 )); then
      echo "Flake download failed. Clearing the live ISO fetch cache before retrying." >&2
      rm -rf /root/.cache/nix
      sleep $((attempt * 2))
    fi
  done

  echo "Unable to create flake.lock after three attempts." >&2
  return 1
}

echo
echo "==> Locking and evaluating the configuration before disk changes"
cd "${REPO_ROOT}"
lock_flake
nix flake check --no-build --show-trace

echo
printf 'This permanently erases every partition on %s.\n' "${DISK}"
printf 'Verified model: %s, size: %s bytes.\n' "${actual_model}" "${actual_bytes}"
printf 'The Kingston USB drive /dev/sda is not referenced by Disko.\n\n'
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

echo "==> Verifying mounted filesystems"
root_fs="$(findmnt -n -o FSTYPE "${TARGET}")"
boot_fs="$(findmnt -n -o FSTYPE "${TARGET}/boot")"

if [[ ${root_fs} != "ext4" ]]; then
  echo "Expected ext4 at ${TARGET}, got '${root_fs}'." >&2
  exit 1
fi

if [[ ${boot_fs} != "vfat" ]]; then
  echo "Expected vfat at ${TARGET}/boot, got '${boot_fs}'." >&2
  exit 1
fi

lsblk -f "${DISK}"

echo "==> Copying this repository to ${TARGET}/etc/nixos"
mkdir -p "${TARGET}/etc/nixos"
cp -a "${REPO_ROOT}/." "${TARGET}/etc/nixos/"
rm -f "${TARGET}/etc/nixos/result"

echo "==> Installing NixOS"
nixos-install --flake "${TARGET}/etc/nixos#desktop"

echo "==> Set the password for user mart"
nixos-enter --root "${TARGET}" -c 'passwd mart'

nixos-enter --root "${TARGET}" -c 'chown -R mart:users /etc/nixos'
sync

echo
echo "Installation complete. Review the output above, then run: reboot"
