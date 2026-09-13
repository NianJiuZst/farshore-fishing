#!/usr/bin/env bash
# Only run --accept-sdk-license after the user accepts the official agreement:
# https://developer.android.com/studio#terms-and-conditions
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [[ "${1:-}" != --accept-sdk-license ]]; then
  echo 'Android SDK license acceptance is required before downloading/installing SDK tools.' >&2
  echo 'Review https://developer.android.com/studio#terms-and-conditions' >&2
  exit 2
fi
mkdir -p tools/downloads tools/android-sdk/cmdline-tools build/logs build/android-user
CLI=commandlinetools-linux-15859902_latest.zip
CLI_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
if [[ ! -f "tools/downloads/$CLI" ]]; then
  curl -fLsS --retry 2 --connect-timeout 20 "https://dl.google.com/android/repository/$CLI" -o "tools/downloads/$CLI"
fi
echo "$CLI_SHA256  tools/downloads/$CLI" | sha256sum -c -
if [[ ! -x tools/android-sdk/cmdline-tools/latest/bin/sdkmanager ]]; then
  unzip -q "tools/downloads/$CLI" -d tools/android-sdk/cmdline-tools
  mv tools/android-sdk/cmdline-tools/cmdline-tools tools/android-sdk/cmdline-tools/latest
fi
export JAVA_HOME="${JAVA_HOME:-$ROOT/tools/jdk/jdk-21.0.12.1+1}"
export ANDROID_HOME="$ROOT/tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$ROOT/build/android-user"
export ANDROID_AVD_HOME="$ROOT/build/android-avd"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
# Java does not automatically consume the executor's HTTP(S)_PROXY variables.
# Use the already-authorized proxy and existing system trust store, without changing either.
SDK_NETWORK_ARGS=()
if [[ -n "${HTTPS_PROXY:-}" ]]; then
  read -r PROXY_HOST PROXY_PORT < <(python3 - <<'PY'
import os, urllib.parse
p=urllib.parse.urlsplit(os.environ['HTTPS_PROXY'])
assert not p.username and not p.password, 'Secure proxy configuration required'
print(p.hostname, p.port or 80)
PY
  )
  SDK_NETWORK_ARGS=(--proxy=http --proxy_host="$PROXY_HOST" --proxy_port="$PROXY_PORT")
fi
if [[ -n "${SSL_CERT_FILE:-}" && -f /etc/ssl/certs/java/cacerts ]]; then
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"
fi
set +e
yes | sdkmanager --sdk_root="$ANDROID_HOME" "${SDK_NETWORK_ARGS[@]}" \
  'platform-tools' 'platforms;android-36' 'build-tools;36.1.0' \
  'ndk;29.0.14206865' 'emulator' 'system-images;android-36;default;x86_64' \
  >build/logs/sdk-install.log 2>&1
RESULT=${PIPESTATUS[1]}
set -e
[[ "$RESULT" == 0 ]] || { echo 'SDK install failed; inspect build/logs/sdk-install.log' >&2; exit "$RESULT"; }
sdkmanager --sdk_root="$ANDROID_HOME" "${SDK_NETWORK_ARGS[@]}" --list_installed >build/logs/sdk-installed.txt 2>&1
echo 'Android SDK packages installed. See build/logs/sdk-installed.txt'

