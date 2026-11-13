#!/usr/bin/env bash
# Reproducible developer bootstrap. Run from the repository or any directory.
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BARRIO_TOOLCHAINS="${BARRIO_TOOLCHAINS:-/workspace/toolchains}"
export ANDROID_HOME="$BARRIO_TOOLCHAINS/android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$BARRIO_TOOLCHAINS/android-user"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$BARRIO_TOOLCHAINS/config}"
export PUB_CACHE="${PUB_CACHE:-$BARRIO_TOOLCHAINS/pub-cache}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$BARRIO_TOOLCHAINS/gradle-cache}"
export PATH="$BARRIO_TOOLCHAINS/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
mkdir -p "$BARRIO_TOOLCHAINS" "$PUB_CACHE" "$GRADLE_USER_HOME" "$ANDROID_USER_HOME" "$XDG_CONFIG_HOME"
if [[ ! -d "$BARRIO_TOOLCHAINS/flutter/.git" ]]; then
  git clone --depth 1 --branch 3.35.7 https://github.com/flutter/flutter.git "$BARRIO_TOOLCHAINS/flutter"
fi
[[ "$(git -C "$BARRIO_TOOLCHAINS/flutter" rev-parse HEAD)" == adc901062556672b4138e18a4dc62a4be8f4b3c2 ]] || { echo 'Unexpected Flutter checkout; preserve it and select a clean BARRIO_TOOLCHAINS directory.' >&2; exit 1; }
if [[ ! -x "$ANDROID_HOME/cmdline-tools/19.0/bin/sdkmanager" ]]; then
  BARRIO_TMP="$(mktemp -d)"
  trap 'rm -rf -- "$BARRIO_TMP"' EXIT
  curl --fail --location --retry 2 https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -o "$BARRIO_TMP/tools.zip"
  # Digest from the official Android repository manifest; TLS remains verified.
  echo "5fdcc763663eefb86a5b8879697aa6088b041e70  $BARRIO_TMP/tools.zip" | sha1sum --check --status
  unzip -q "$BARRIO_TMP/tools.zip" -d "$BARRIO_TMP/extracted"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  mv "$BARRIO_TMP/extracted/cmdline-tools" "$ANDROID_HOME/cmdline-tools/19.0"
fi
SDKMANAGER=("$ANDROID_HOME/cmdline-tools/19.0/bin/sdkmanager" "--sdk_root=$ANDROID_HOME")
# sdkmanager does not interpret HTTPS_PROXY itself. Preserve the inherited route.
if [[ -n "${HTTPS_PROXY:-}" ]]; then
  mapfile -t BARRIO_PROXY < <(python3 - <<'PY'
import os, urllib.parse
p=urllib.parse.urlsplit(os.environ['HTTPS_PROXY'])
print(p.hostname or '')
print(p.port or 80)
PY
)
  SDKMANAGER+=(--proxy=http "--proxy_host=${BARRIO_PROXY[0]}" "--proxy_port=${BARRIO_PROXY[1]}")
fi
# Feed finite answers so pipefail preserves sdkmanager's actual outcome.
printf 'y\ny\ny\ny\ny\ny\ny\ny\ny\ny\n' | "${SDKMANAGER[@]}" --licenses
"${SDKMANAGER[@]}" 'platform-tools' 'platforms;android-36' 'build-tools;35.0.0' 'ndk;27.0.12077973'
echo "2db75c40782f5e8ba1fc278a5574bab070adccb2d21ca5a6e5ed840888448046  $PROJECT_DIR/android/gradle/wrapper/gradle-wrapper.jar" | sha256sum --check --status
flutter --version
flutter config --android-sdk "$ANDROID_HOME" --no-analytics
flutter precache --android
cd "$PROJECT_DIR"
# local.properties is ignored and contains paths only.
printf 'sdk.dir=%s\nflutter.sdk=%s\n' "$ANDROID_HOME" "$BARRIO_TOOLCHAINS/flutter" > android/local.properties
flutter pub get
flutter doctor -v
