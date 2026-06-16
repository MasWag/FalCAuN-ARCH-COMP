#!/bin/sh

set -u

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

java_major_version() {
    "$1" -version 2>&1 | sed -n 's/.* version "\([^"]*\)".*/\1/p' | awk -F. '{
        if ($1 == "1") {
            print $2
        } else {
            print $1
        }
        exit
    }'
}

use_java_home_if_version_17() {
    candidate=$1
    if [ -x "$candidate/bin/java" ]; then
        major=$(java_major_version "$candidate/bin/java")
        if [ "$major" = "17" ]; then
            JAVA_HOME=$candidate
            export JAVA_HOME
            PATH=$JAVA_HOME/bin:$PATH
            export PATH
            return 0
        fi
    fi
    return 1
}

setup_sdkman() {
    if [ -n "${SDKMAN_DIR:-}" ] && [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        set +u
        . "$SDKMAN_DIR/bin/sdkman-init.sh"
        set -u
        return
    fi

    for candidate in "$HOME/.sdkman" /opt/homebrew/opt/sdkman-cli/libexec /usr/local/opt/sdkman-cli/libexec; do
        if [ -s "$candidate/bin/sdkman-init.sh" ]; then
            SDKMAN_DIR=$candidate
            export SDKMAN_DIR
            set +u
            . "$SDKMAN_DIR/bin/sdkman-init.sh"
            set -u
            return
        fi
    done
}

setup_java_home() {
    if [ -n "${JAVA_HOME:-}" ] && use_java_home_if_version_17 "$JAVA_HOME"; then
        return
    fi

    if command -v java >/dev/null 2>&1; then
        major=$(java_major_version java)
        if [ "$major" = "17" ]; then
            return
        fi
    fi

    if [ -x /usr/libexec/java_home ]; then
        candidate=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
        if [ -n "$candidate" ] && use_java_home_if_version_17 "$candidate"; then
            return
        fi
    fi

    for candidate in \
        /usr/lib/jvm/java-17-openjdk-* \
        /usr/lib/jvm/java-17-openjdk \
        /usr/lib/jvm/*17* \
        /usr/java/*17* \
        /opt/java/*17*
    do
        if use_java_home_if_version_17 "$candidate"; then
            return
        fi
    done

    fail "Could not find Java 17 automatically. Please install JDK 17 and run:
  export JAVA_HOME=/path/to/jdk-17
  export PATH=\"\$JAVA_HOME/bin:\$PATH\"
Then retry ./run_all_main_kts.sh"
}

setup_matlab_home() {
    if [ -n "${MATLAB_HOME:-}" ] && [ -x "$MATLAB_HOME/bin/matlab" ]; then
        return
    fi

    for candidate in /Applications/MATLAB_R*.app /usr/local/MATLAB/R*; do
        if [ -x "$candidate/bin/matlab" ]; then
            MATLAB_HOME=$candidate
            export MATLAB_HOME
            return
        fi
    done

    fail "Could not find MATLAB automatically. Please set MATLAB_HOME, for example:
  export MATLAB_HOME=/Applications/MATLAB_R2026a.app
or:
  export MATLAB_HOME=/usr/local/MATLAB/R2026a
Then retry ./run_all_main_kts.sh"
}

setup_sdkman
setup_java_home
setup_matlab_home

if ! command -v kscript >/dev/null 2>&1; then
    fail "Could not find kscript on PATH. If you use SDKMAN, run:
  . ~/.bashrc
or set SDKMAN_DIR to your SDKMAN installation, then retry ./run_all_main_kts.sh"
fi

scripts='
AT/AT1.main.kts
AT/AT2.main.kts
AT/AT6a.main.kts
AT/AT6abc.main.kts
AT/AT6b.main.kts
AT/AT6c.main.kts
CC/CC1.main.kts
CC/CC2.main.kts
CC/CC3.main.kts
CC/CC4.main.kts
CC/CCx.main.kts
SC/SCa.main.kts
PM/pacemaker.main.kts
'

status=0
for script in $scripts; do
    dir=$(dirname "$script")
    base=$(basename "$script")
    printf '%s\n' "===== $script ====="
    (
        cd "$dir" || exit 1
        "./$base" "$@"
    )
    rc=$?
    printf '%s\n' "===== $script exit $rc ====="
    if [ "$rc" -ne 0 ]; then
        status=$rc
    fi
done

exit "$status"
