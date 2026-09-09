#!/usr/bin/env bash
# Managed by lr-opencode-fork-updater
set -euo pipefail
export LC_ALL=C
unset TAR_OPTIONS GZIP

fail() { printf 'lr-opencode installer: %s\n' "$*" >&2; exit 1; }

prefix=${HOME:+$HOME/.local}
force=false
while (( $# )); do
    case "$1" in
        --prefix)
            (( $# >= 2 )) || fail '--prefix requires an absolute path'
            prefix=$2
            shift 2
            ;;
        --force) force=true; shift ;;
        --help)
            printf 'Usage: bash install.sh [--prefix /absolute/path] [--force]\nLinux only. Default prefix: $HOME/.local. --force replaces an unmanaged bin/lr-opencode, never a directory.\n'
            exit 0
            ;;
        *) fail "Unknown option: $1" ;;
    esac
done
[[ -n "$prefix" ]] || fail 'Set HOME or provide --prefix with an absolute path'
[[ "$prefix" == /* && "$prefix" != *[$'\n\r\t']* ]] || fail '--prefix must be an absolute path without control whitespace'
[[ $(uname -s) == Linux ]] || fail 'Only Linux is supported (use Homebrew on macOS)'
dependencies='On Alpine, install dependencies with: apk add bash curl tar coreutils util-linux'
for dependency in curl flock tar gzip sha256sum cmp readlink mktemp timeout grep; do
    command -v "$dependency" >/dev/null || fail "Missing dependency: $dependency. $dependencies"
done
tar_version=$(tar --version 2>/dev/null) && [[ "$tar_version" == 'tar (GNU tar) '* ]] || fail "GNU tar is required, not BusyBox/BSD tar. $dependencies"
timeout_version=$(timeout --version 2>/dev/null) && [[ "$timeout_version" == 'timeout (GNU coreutils) '* ]] || fail "GNU timeout is required, not BusyBox timeout. $dependencies"
case $(uname -m) in
    x86_64|amd64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) fail 'Unsupported Linux architecture' ;;
esac
target=lr-opencode-linux-$arch
if [[ "$arch" == x64 ]] && ! grep -qE '^flags[[:space:]]*:.*[[:space:]]avx2([[:space:]]|$)' /proc/cpuinfo 2>/dev/null; then
    target+=-baseline
fi
libc=$(ldd --version 2>&1 || true)
if [[ "$libc" == *musl* || -f /etc/alpine-release ]]; then
    target+=-musl
fi
archive=$target.tar.gz

umask 022
mkdir -p -- "$prefix"
prefix=$(cd -- "$prefix" && pwd -P)
bin=$prefix/bin
root=$prefix/lib/lr-opencode
for directory in "$bin" "$prefix/lib" "$root" "$root/versions"; do
    [[ ! -L "$directory" ]] || fail "Refusing symlinked installation directory: $directory"
    mkdir -p -- "$directory"
done
[[ ! -L "$root/install.lock" && ( ! -e "$root/install.lock" || -f "$root/install.lock" ) ]] || fail 'Install lock must be a regular file'
exec 9>>"$root/install.lock"
flock -x 9

destination=$bin/lr-opencode
managed=false
if [[ -L "$destination" && $(readlink -- "$destination") == "$root/current/launcher" ]]; then
    managed=true
elif [[ -e "$destination" || -L "$destination" ]]; then
    [[ ! -d "$destination" ]] || fail "Refusing to replace directory: $destination"
    "$force" || fail "Unmanaged $destination exists; use --force to replace only that path"
fi

# Validate the bytes as well as the line: command substitution alone loses trailing newlines.
read_channel() {
    local file=$1 line
    [[ -f "$file" && ! -L "$file" ]] || fail "Missing regular channel metadata: $file"
    line=$(<"$file")
    [[ "$line" =~ ^([1-9][0-9]*)\ (v0\.0\.0-fork\.[0-9a-f]{12})\ ([0-9a-f]{64})$ ]] || fail 'Invalid channel metadata'
    release_id=${BASH_REMATCH[1]}
    tag=${BASH_REMATCH[2]}
    sums_hash=${BASH_REMATCH[3]}
    printf '%s\n' "$line" | cmp -s - "$file" || fail 'Channel must contain exactly one LF-terminated line'
}

installed_id=
installed_tag=
installed_sums_hash=
current=
if [[ -e "$root/current" || -L "$root/current" ]]; then
    [[ -L "$root/current" ]] || fail 'Managed current pointer is not a symlink'
    current=$(readlink -f -- "$root/current") || fail 'Invalid managed current pointer'
    [[ "$current" == "$root/versions/"* && "${current#"$root/versions/"}" != */* ]] || fail 'Current pointer is outside managed versions'
    read_channel "$current/channel.txt"
    installed_id=$release_id
    installed_tag=$tag
    installed_sums_hash=$sums_hash
fi

stage=$(mktemp -d "$root/.install.XXXXXXXXXX")
bin_stage=
cleanup() {
    rm -rf -- "$stage"
    if [[ -n "$bin_stage" ]]; then rm -rf -- "$bin_stage"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
fetch() {
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 15 --max-time 300 --output "$2" "$1"
}
fetch 'https://raw.githubusercontent.com/leuchtraketen/homebrew-tap/HEAD/lr-opencode-channel.txt' "$stage/channel.txt"
read_channel "$stage/channel.txt"
if [[ -n "$installed_id" ]]; then
    if (( ${#release_id} < ${#installed_id} )) ||
        { (( ${#release_id} == ${#installed_id} )) && [[ "$release_id" < "$installed_id" ]]; }; then
        fail "Channel release $release_id is older than installed release $installed_id; refusing downgrade"
    fi
    [[ "$release_id" != "$installed_id" || "$tag" == "$installed_tag" ]] || fail 'Channel changed tag for the installed release ID'
    [[ "$release_id" != "$installed_id" || "$sums_hash" == "$installed_sums_hash" ]] || fail 'Channel changed SHA256SUMS hash for the installed release ID'
fi
url=https://github.com/leuchtraketen/opencode/releases/download/$tag
fetch "$url/SHA256SUMS" "$stage/SHA256SUMS"
actual=$(sha256sum < "$stage/SHA256SUMS")
[[ "${actual%% *}" == "$sums_hash" ]] || fail 'SHA256SUMS does not match its committed hash'
matches=0
expected=
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^([0-9a-f]{64})\ [\ \*]([A-Za-z0-9._-]+)$ ]] || fail 'Malformed SHA256SUMS entry'
    if [[ "${BASH_REMATCH[2]}" == "$archive" ]]; then
        expected=${BASH_REMATCH[1]}
        matches=$((matches + 1))
    fi
done < "$stage/SHA256SUMS"
(( matches == 1 )) || fail 'SHA256SUMS must contain exactly one matching archive'
fetch "$url/$archive" "$stage/archive.tar.gz"
actual=$(sha256sum < "$stage/archive.tar.gz")
[[ "${actual%% *}" == "$expected" ]] || fail 'Archive checksum mismatch'

# Never extract archive paths onto disk, even after validating the sole root entry.
tar --absolute-names --quoting-style=escape -tzf "$stage/archive.tar.gz" > "$stage/entries"
printf 'lr-opencode\n' | cmp -s - "$stage/entries" || fail 'Archive must contain only root lr-opencode'
entry=$(tar --absolute-names --quoting-style=escape -tvzf "$stage/archive.tar.gz")
[[ "$entry" == -* ]] || fail 'Archive lr-opencode must be a regular file, not a link'
mkdir -- "$stage/version"
tar --absolute-names -xOzf "$stage/archive.tar.gz" -- lr-opencode > "$stage/version/lr-opencode"
[[ -s "$stage/version/lr-opencode" ]] || fail 'Archive binary is empty'
chmod 755 "$stage/version/lr-opencode"
cp -- "$stage/channel.txt" "$stage/version/channel.txt"
cat > "$stage/version/launcher" <<'LAUNCHER'
#!/usr/bin/env bash
# Managed by lr-opencode-fork-updater
set -euo pipefail
export OPENCODE_DISABLE_AUTOUPDATE=1
args=("$@")
while (( $# )); do
    case "$1" in
        --) break ;;
        --log-level|--logLevel|--port|--hostname|--mdns-domain|--mdnsDomain|--cors|--method|-m)
            (( $# >= 2 )) || break
            shift 2
            ;;
        --*=*) shift ;;
        --print-logs|--printLogs|--pure|--mdns|--no-*|-h|--help|-v|--version)
            shift
            if [[ ${1-} == true || ${1-} == false ]]; then shift; fi
            ;;
        -*) shift ;;
        upgrade)
            printf 'lr-opencode is managed by its installer. Rerun the lr-opencode Linux installer with the same --prefix to upgrade.\n' >&2
            exit 1
            ;;
        *) break ;;
    esac
done
launcher=$(readlink -f -- "$0")
exec "${launcher%/*}/lr-opencode" "${args[@]}"
LAUNCHER
chmod 755 "$stage/version/launcher"
mkdir -- "$stage/home"
if ! (cd -- "$stage/home" && timeout --kill-after=5 30 env -i PATH=/usr/bin:/bin HOME="$stage/home" \
    XDG_CONFIG_HOME="$stage/home/config" XDG_DATA_HOME="$stage/home/data" \
    XDG_CACHE_HOME="$stage/home/cache" XDG_STATE_HOME="$stage/home/state" XDG_RUNTIME_DIR="$stage/home/runtime" \
    OPENCODE_DISABLE_AUTOUPDATE=1 LC_ALL=C \
    "$stage/version/lr-opencode" --version > "$stage/version-output"); then
    fail 'Binary --version smoke test failed'
fi
printf '%s\n' "${tag#v}" | cmp -s - "$stage/version-output" || fail 'Binary version does not match the channel tag'

if [[ "$installed_id" == "$release_id" && -f "$current/lr-opencode" && -x "$current/lr-opencode" && ! -L "$current/lr-opencode" &&
    -f "$current/launcher" && -x "$current/launcher" && ! -L "$current/launcher" ]] &&
    cmp -s "$current/lr-opencode" "$stage/version/lr-opencode" &&
    cmp -s "$current/launcher" "$stage/version/launcher"; then
    printf 'lr-opencode %s is already installed and verified.\n' "${tag#v}"
else
    version=$release_id-$tag.${stage##*.}
    mv -- "$stage/version" "$root/versions/$version"
    ln -s -- "versions/$version" "$stage/current"
    mv -Tf -- "$stage/current" "$root/current"
    printf 'Installed lr-opencode %s in %s\n' "${tag#v}" "$prefix"
fi
if ! "$managed"; then
    bin_stage=$(mktemp -d "$bin/.lr-opencode.XXXXXXXXXX")
    ln -s -- "$root/current/launcher" "$bin_stage/lr-opencode"
    mv -Tf -- "$bin_stage/lr-opencode" "$destination"
fi
printf 'Run: %s\nAdd %s to PATH if needed; no shell configuration was changed.\n' "$destination" "$bin"
