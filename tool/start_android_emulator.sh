#!/usr/bin/env bash
set -euo pipefail
BARRIO_TOOLS="${BARRIO_TOOLCHAINS:-/workspace/toolchains}"
export ANDROID_SDK_ROOT="$BARRIO_TOOLS/android"
export ANDROID_USER_HOME="$BARRIO_TOOLS/android-user"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
BARRIO_ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
if "$BARRIO_ADB" devices | rg -q '^emulator-5554[[:space:]]'; then
  "$BARRIO_ADB" devices
  exit 0
fi
if [[ ! -f "$ANDROID_AVD_HOME/barrio-api29.ini" ]]; then
  echo 'AVD barrio-api29 missing. Install emulator and system-images;android-29;default;x86_64 through sdkmanager, then create the AVD.' >&2
  exit 1
fi
mkdir -p /workspace/Barrio_Cero/build/emulator
nohup "$ANDROID_SDK_ROOT/emulator/emulator" -avd barrio-api29 -no-window -no-audio -no-boot-anim -no-snapshot -accel off -gpu swiftshader_indirect -memory 4096 -cores 2 -port 5554 > /workspace/Barrio_Cero/build/emulator/start.log 2>&1 < /dev/null &
printf 'Emulator process %s started; readiness: adb -s emulator-5554 shell getprop sys.boot_completed (must return 1).\n' "$!"
