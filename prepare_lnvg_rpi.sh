#!/usr/bin/env bash
set -euo pipefail

LOG="[LNVG-PREP]"
info(){ echo "$LOG $*"; }
warn(){ echo "$LOG WARNING: $*" >&2; }
die(){ echo "$LOG ERROR: $*" >&2; exit 1; }

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Run as root: sudo $0"
}

detect_config_txt() {
  if [[ -f /boot/firmware/config.txt ]]; then
    echo "/boot/firmware/config.txt"
  elif [[ -f /boot/config.txt ]]; then
    echo "/boot/config.txt"
  else
    echo ""
  fi
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local b="${f}.bak.$(date +%Y%m%d_%H%M%S)"
  cp -a "$f" "$b"
  info "Backup created: $b"
}

# Replace or append a managed block in config.txt
ensure_managed_block() {
  local file="$1"

  local begin="# --- BEGIN LNVG MANAGED ---"
  local end="# --- END LNVG MANAGED ---"

  # Managed lines (kept close to your current config intent)
  # Note: We intentionally do NOT touch camera_auto_detect/display_auto_detect/etc.
  # Only LNVG-specific GPU/GPIO/overlays live here.
  local block
  block="$(cat <<'EOF'
# --- BEGIN LNVG MANAGED ---
# KMS/DRM for EGLFS on Raspberry Pi
max_framebuffers=2
disable_fw_kms_setup=1

[all]
# KMS driver for V3D (EGLFS kms)
dtoverlay=vc4-kms-v3d

# Default GPIO output states
gpio=13=op,dh
gpio=19=op,dh
gpio=5=op,dl
gpio=6=op,dl

# 1-wire (two buses)
dtoverlay=w1-gpio,gpiopin=4,pullup=1
dtoverlay=w1-gpio,gpiopin=17,pullup=1

# Shutdown button on GPIO3
dtoverlay=gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up

# Disable SPI if not needed
dtparam=spi=off
# --- END LNVG MANAGED ---
EOF
)"

  if grep -qF "$begin" "$file"; then
    info "Updating existing LNVG managed block in $file"
    # Delete old block
    # (portable sed: write to temp then move)
    local tmp
    tmp="$(mktemp)"
    awk -v b="$begin" -v e="$end" '
      BEGIN{inblk=0}
      index($0,b){inblk=1; next}
      index($0,e){inblk=0; next}
      inblk==0{print}
    ' "$file" > "$tmp"
    # Append updated block at end (keeps it deterministic)
    printf "\n%s\n" "$block" >> "$tmp"
    mv "$tmp" "$file"
  else
    info "Appending LNVG managed block to $file"
    printf "\n%s\n" "$block" >> "$file"
  fi
}

main() {
  require_root

  info "OS release:"
  cat /etc/os-release || true

  info "Setting timezone to Europe/Prague"
  timedatectl set-timezone Europe/Prague || warn "timedatectl failed (non-systemd?)"
  timedatectl status || true

  info "APT update + full-upgrade"
  apt-get update
  apt-get -y full-upgrade

  info "Configuring system locale (cs_CZ.UTF-8)"

  apt_install locales
  
  # enable cs_CZ.UTF-8 if not already enabled
  if ! grep -q "^cs_CZ.UTF-8 UTF-8" /etc/locale.gen; then
    sed -i 's/^# *\(cs_CZ.UTF-8 UTF-8\)/\1/' /etc/locale.gen
  fi
  
  # (optional) keep en_GB as fallback
  if ! grep -q "^en_GB.UTF-8 UTF-8" /etc/locale.gen; then
    sed -i 's/^# *\(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen || true
  fi
  
  locale-gen
  
  update-locale LANG=cs_CZ.UTF-8 LC_ALL=cs_CZ.UTF-8
  
  export LANG=cs_CZ.UTF-8
  export LC_ALL=cs_CZ.UTF-8
  
  info "Locale set to cs_CZ.UTF-8"
  locale
  
  info "CA certificates + GitHub TLS test"
  apt_install ca-certificates curl
  update-ca-certificates || true
  curl -I https://github.com | head -n 1 || warn "GitHub TLS test failed (check network/CA)"

  info "EGL/GBM/KMS runtime packages"
  apt_install mesa-utils libegl1 libgles2 libdrm2 libgbm1

  info "Configuring KMS/GPIO overlays via managed block"
  local cfg
  cfg="$(detect_config_txt)"
  if [[ -z "$cfg" ]]; then
    warn "config.txt not found (/boot/firmware/config.txt or /boot/config.txt). Skipping."
  else
    backup_file "$cfg"
    ensure_managed_block "$cfg"
    info "config.txt updated: $cfg"
  fi

  info "Installing build tools + Qt5 dev"
  apt_install \
    build-essential cmake git pkg-config \
    qtbase5-dev qtdeclarative5-dev qtbase5-private-dev \
    qtquickcontrols2-5-dev

  info "Installing required QML runtime modules"
  apt_install \
    qml-module-qtquick2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-window2

  info "Ensuring qmake exists"
  command -v qmake >/dev/null || die "qmake not found (unexpected). Is qtbase5-dev installed?"

  # Build user & home
  local build_user="${SUDO_USER:-root}"
  local build_home
  build_home="$(getent passwd "$build_user" | cut -d: -f6 || echo "/root")"

  info "Using build user: $build_user (home: $build_home)"

  # ---- QtMqtt (qtmqtt v5.15.2) ----
  local qtmqtt_dir="$build_home/qtmqtt"
  info "Building & installing QtMqtt (qtmqtt) v5.15.2"
  if [[ -d "$qtmqtt_dir/.git" ]]; then
    info "qtmqtt exists -> fetch"
    sudo -u "$build_user" git -C "$qtmqtt_dir" fetch --tags --all
  else
    info "Cloning qtmqtt"
    sudo -u "$build_user" git clone https://github.com/qt/qtmqtt.git "$qtmqtt_dir"
  fi

  sudo -u "$build_user" bash -lc "
    set -e
    cd '$qtmqtt_dir'
    git checkout -f v5.15.2
    rm -rf build
    mkdir build
    cd build
    qmake ../qtmqtt.pro
    make -j\"\$(nproc)\"
  "
  ( cd "$qtmqtt_dir/build" && make install )
  ldconfig

  info "Verify Qt5Mqtt CMake discovery"
  cmake --find-package -DNAME=Qt5Mqtt -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=EXIST || warn "Qt5Mqtt not discoverable by CMake"

  # ---- pigpio ----
  local pigpio_dir="$build_home/pigpio"
  info "Building & installing pigpio into /usr/local (without Python module)"
  if [[ -d "$pigpio_dir/.git" ]]; then
    info "pigpio exists -> pull"
    sudo -u "$build_user" git -C "$pigpio_dir" pull --ff-only || true
  else
    info "Cloning pigpio"
    sudo -u "$build_user" git clone https://github.com/joan2937/pigpio.git "$pigpio_dir"
  fi

  sudo -u "$build_user" bash -lc "
    set -e
    cd '$pigpio_dir'
    make -j\"\$(nproc)\"
  "

  # Manual install to avoid python distutils error on Debian 13
  install -m 0755 "$pigpio_dir/pigpiod" /usr/local/bin/
  install -m 0755 "$pigpio_dir/pigs"    /usr/local/bin/
  install -m 0644 "$pigpio_dir/pigpio.h"      /usr/local/include/
  install -m 0644 "$pigpio_dir/pigpiod_if.h"  /usr/local/include/
  install -m 0644 "$pigpio_dir/pigpiod_if2.h" /usr/local/include/
  install -m 0755 "$pigpio_dir/libpigpio.so"      /usr/local/lib/
  install -m 0755 "$pigpio_dir/libpigpiod_if.so"  /usr/local/lib/
  install -m 0755 "$pigpio_dir/libpigpiod_if2.so" /usr/local/lib/

  ln -sf /usr/local/lib/libpigpio.so      /usr/local/lib/libpigpio.so.1
  ln -sf /usr/local/lib/libpigpiod_if.so  /usr/local/lib/libpigpiod_if.so.1
  ln -sf /usr/local/lib/libpigpiod_if2.so /usr/local/lib/libpigpiod_if2.so.1
  ldconfig

  info "pigpio libs installed:"
  ldconfig -p | grep -i pigpio || true
  info "pigpiod version:"
  /usr/local/bin/pigpiod -v || true

  info "Recommended groups so you can run EGLFS without sudo:"
  echo "  sudo usermod -aG video,render,input $build_user"
  echo "  sudo reboot"

  info "Optional: test EGL driver quickly:"
  echo "  eglinfo | grep -E \"EGL driver name|OpenGL core profile renderer\""

  info "Done."
}

main "$@"
