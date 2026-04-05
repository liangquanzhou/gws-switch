#!/bin/zsh

set -euo pipefail

ROOT="${0:A:h:h}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export HOME="${TMP_DIR}/home"
export XDG_CONFIG_HOME="${HOME}/.config"
mkdir -p "${XDG_CONFIG_HOME}/gws/accounts" "${XDG_CONFIG_HOME}/gws-gmail" "${TMP_DIR}/bin"

cat > "${TMP_DIR}/bin/gws" <<'EOF'
#!/bin/zsh
set -euo pipefail

config_dir="${GOOGLE_WORKSPACE_CLI_CONFIG_DIR:-}"
cmd="${1:-}"

write_creds() {
  mkdir -p "$config_dir"
  cat > "${config_dir}/credentials.json" <<'JSON'
{
  "client_id": "mock-client.apps.googleusercontent.com",
  "client_secret": "mock-secret",
  "refresh_token": "mock-refresh-token"
}
JSON
}

case "$cmd" in
  auth)
    sub="${2:-}"
    case "$sub" in
      login)
        write_creds
        print -r -- "mock login ok"
        ;;
      export)
        if [[ -f "${config_dir}/credentials.json" || -f "${config_dir}/credentials.enc" ]]; then
          print -r -- '{"token":"ok"}'
        else
          print -u2 -- "No credentials provided"
          exit 1
        fi
        ;;
      status)
        print -r -- "mock status"
        ;;
      *)
        print -u2 -- "unknown auth subcommand: $sub"
        exit 1
        ;;
    esac
    ;;
  *)
    print -r -- "RAW:$*|CFG=${config_dir}"
    ;;
esac
EOF
chmod +x "${TMP_DIR}/bin/gws"

cat > "${XDG_CONFIG_HOME}/gws/accounts/zhouliangquan@didi-labs.com.json" <<'JSON'
{
  "client_id": "work-client.apps.googleusercontent.com",
  "client_secret": "work-secret",
  "refresh_token": "work-refresh-token"
}
JSON

cat > "${XDG_CONFIG_HOME}/gws/accounts/liangquanzhou@gmail.com.json" <<'JSON'
{
  "client_id": "gmail-client.apps.googleusercontent.com",
  "client_secret": "gmail-secret",
  "refresh_token": "gmail-refresh-token"
}
JSON

cat > "${XDG_CONFIG_HOME}/gws/client_secret.json" <<'JSON'
{
  "installed": {
    "client_id": "base-client.apps.googleusercontent.com",
    "project_id": "base-project",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "base-secret",
    "redirect_uris": ["http://localhost"]
  }
}
JSON

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    print -u2 -- "expected to find: $needle"
    print -u2 -- "actual: $haystack"
    exit 1
  fi
}

export GWS_SWITCH_RAW_BIN="${TMP_DIR}/bin/gws"
export GWS_SWITCH_SECRETS_FILE="${TMP_DIR}/missing-secrets.zsh"

help_output="$("${ROOT}/bin/gws-switch" --help)"
assert_contains "$help_output" "Usage:"
assert_contains "$help_output" "gws-switch use"

version_output="$("${ROOT}/bin/gws-switch" --version)"
assert_contains "$version_output" "gws-switch "

accounts_output="$("${ROOT}/bin/gws-switch-accounts")"
assert_contains "$accounts_output" "liangquanzhou@gmail.com"
assert_contains "$accounts_output" "zhouliangquan@didi-labs.com"

"${ROOT}/bin/gws-switch-gmail" >/dev/null
who_output="$("${ROOT}/bin/gws-switch-who")"
assert_contains "$who_output" "liangquanzhou@gmail.com"

"${ROOT}/bin/gws-switch-login" gmail >/dev/null
doctor_output="$("${ROOT}/bin/gws-switch-doctor" gmail)"
assert_contains "$doctor_output" "auth_export_probe: ok"

status_output="$("${ROOT}/bin/gws-switch-status" gmail)"
assert_contains "$status_output" "runtime_credentials_exists: true"
assert_contains "$status_output" "client_secret: present"

raw_output="$("${ROOT}/bin/gws-switch" drive files list)"
assert_contains "$raw_output" "CFG=${XDG_CONFIG_HOME}/gws-gmail"

config_path="${TMP_DIR}/generated-config.json"
"${ROOT}/bin/gws-switch-config-init" --path "$config_path" >/dev/null
assert_contains "$(cat "$config_path")" "\"app_config_dir\""

print -r -- "smoke: ok"
