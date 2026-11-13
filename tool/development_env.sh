#!/usr/bin/env bash
# Source this file before invoking Flutter, Dart, or Gradle in this workspace.
export BARRIO_TOOLCHAINS="${BARRIO_TOOLCHAINS:-/workspace/toolchains}"
export ANDROID_HOME="$BARRIO_TOOLCHAINS/android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$BARRIO_TOOLCHAINS/android-user"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$BARRIO_TOOLCHAINS/config}"
export PUB_CACHE="${PUB_CACHE:-$BARRIO_TOOLCHAINS/pub-cache}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$BARRIO_TOOLCHAINS/gradle-cache}"
export PATH="$BARRIO_TOOLCHAINS/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
if [[ -x "$BARRIO_TOOLCHAINS/jdk-21.0.9+10/bin/javac" ]]; then
  export JAVA_HOME="$BARRIO_TOOLCHAINS/jdk-21.0.9+10"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
mkdir -p "$PUB_CACHE" "$GRADLE_USER_HOME" "$ANDROID_USER_HOME" "$XDG_CONFIG_HOME"
# Java does not inherit HTTPS_PROXY. Keep its proxy settings in the local cache,
# preserving unrelated user settings and never adding credentials to the repo.
python3 - <<'PY'
import os
from pathlib import Path
from urllib.parse import urlsplit
proxy = urlsplit(os.environ.get('HTTPS_PROXY', ''))
if proxy.hostname:
    path = Path(os.environ['GRADLE_USER_HOME']) / 'gradle.properties'
    values = {f'systemProp.{protocol}.{key}': str(value)
              for protocol in ('http', 'https')
              for key, value in [('proxyHost', proxy.hostname), ('proxyPort', proxy.port or 80)]}
    previous = path.read_text() if path.exists() else ''
    lines = [line for line in previous.splitlines() if line.split('=', 1)[0] not in values]
    path.write_text('\n'.join(lines + [f'{key}={value}' for key, value in values.items()]) + '\n')
PY
