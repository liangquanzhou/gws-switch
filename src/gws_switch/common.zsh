#!/bin/zsh

if [[ -z "${GWS_SWITCH_ROOT:-}" ]]; then
  typeset -g GWS_SWITCH_ROOT="${${(%):-%N}:A:h:h:h}"
fi

typeset -g GWS_SWITCH_RAW_BIN="${GWS_SWITCH_RAW_BIN:-}"
typeset -g GWS_SWITCH_APP_CONFIG_DIR="${GWS_SWITCH_APP_CONFIG_DIR:-}"
typeset -g GWS_SWITCH_CONFIG_FILE="${GWS_SWITCH_CONFIG_FILE:-}"
typeset -g GWS_SWITCH_CONFIG_DIR="${GWS_SWITCH_CONFIG_DIR:-}"
typeset -g GWS_SWITCH_GMAIL_CONFIG_DIR="${GWS_SWITCH_GMAIL_CONFIG_DIR:-}"
typeset -g GWS_SWITCH_ACCOUNTS_DIR="${GWS_SWITCH_ACCOUNTS_DIR:-}"
typeset -g GWS_SWITCH_STATE_FILE="${GWS_SWITCH_STATE_FILE:-}"
typeset -g GWS_SWITCH_BASE_CLIENT_SECRET="${GWS_SWITCH_BASE_CLIENT_SECRET:-}"
typeset -g GWS_SWITCH_SECRETS_FILE="${GWS_SWITCH_SECRETS_FILE:-}"
typeset -g GWS_SWITCH_MANIFEST_FILE="${GWS_SWITCH_MANIFEST_FILE:-}"
typeset -g GWS_SWITCH_DEFAULT_ACCOUNT="${GWS_SWITCH_DEFAULT_ACCOUNT:-}"
typeset -g GWS_SWITCH_CONFIG_LOADED="${GWS_SWITCH_CONFIG_LOADED:-0}"

gws_switch_detect_raw_bin() {
  emulate -L zsh

  local candidate
  for candidate in \
    "${GWS_SWITCH_RAW_BIN:-}" \
    /opt/homebrew/bin/gws \
    /usr/local/bin/gws \
    "${commands[gws]:-}"
  do
    [[ -n "$candidate" ]] || continue
    [[ -x "$candidate" ]] || continue
    print -r -- "$candidate"
    return 0
  done

  return 1
}

gws_switch_version() {
  emulate -L zsh

  local version_file="${GWS_SWITCH_ROOT}/VERSION"
  if [[ -f "$version_file" ]]; then
    <"$version_file"
    return 0
  fi

  print -r -- "0.0.0-dev"
}

gws_switch_print_usage() {
  emulate -L zsh

  cat <<EOF
gws-switch $(gws_switch_version)

Usage:
  gws-switch help
  gws-switch version
  gws-switch who
  gws-switch accounts
  gws-switch use <account|gmail|didi>
  gws-switch login <account|gmail|didi>
  gws-switch status [account|gmail|didi]
  gws-switch doctor [account|gmail|didi]
  gws-switch do <account|gmail|didi> <gws args...>
  gws-switch config-init [--force] [--path <file>]
  gws-switch raw <gws args...>
  gws-switch <upstream gws args...>

Shortcuts:
  gws-switch-gmail
  gws-switch-didi
  gws-switch-who
  gws-switch-accounts
  gws-switch-status
  gws-switch-doctor
  gws-switch-config-init

Notes:
  - Public commands use the gws-switch-* prefix to avoid shadowing upstream gws.
  - Upstream gws is auto-detected from common Homebrew/system locations when possible.
  - Use "gws-switch raw ..." to bypass account routing and call upstream gws directly.
EOF
}

gws_switch_apply_config() {
  emulate -L zsh

  [[ "${GWS_SWITCH_CONFIG_LOADED:-0}" == "1" ]] && return 0

  local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local raw_gws_bin="${GWS_SWITCH_RAW_BIN:-}"
  local app_config_dir="${GWS_SWITCH_APP_CONFIG_DIR:-${xdg_config_home}/gws-switch}"
  local config_file="${GWS_SWITCH_CONFIG_FILE:-${app_config_dir}/config.json}"
  local config_dir="${GWS_SWITCH_CONFIG_DIR:-${xdg_config_home}/gws}"
  local gmail_config_dir="${GWS_SWITCH_GMAIL_CONFIG_DIR:-${xdg_config_home}/gws-gmail}"
  local accounts_dir="${GWS_SWITCH_ACCOUNTS_DIR:-${config_dir}/accounts}"
  local state_file="${GWS_SWITCH_STATE_FILE:-${config_dir}/.current_account}"
  local base_client_secret="${GWS_SWITCH_BASE_CLIENT_SECRET:-${config_dir}/client_secret.json}"
  local secrets_file="${GWS_SWITCH_SECRETS_FILE:-$HOME/.config/zsh/secrets.zsh}"
  local manifest_file="${GWS_SWITCH_MANIFEST_FILE:-${app_config_dir}/accounts.json}"
  local default_account="${GWS_SWITCH_DEFAULT_ACCOUNT:-}"

  if [[ -f "$config_file" ]]; then
    eval "$(
      python3 - "$config_file" <<'PY'
import json
import shlex
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
mapping = {
    "raw_gws_bin": "raw_gws_bin",
    "app_config_dir": "app_config_dir",
    "config_dir": "config_dir",
    "gmail_config_dir": "gmail_config_dir",
    "accounts_dir": "accounts_dir",
    "state_file": "state_file",
    "base_client_secret": "base_client_secret",
    "secrets_file": "secrets_file",
    "manifest_file": "manifest_file",
    "default_account": "default_account",
}
for key, var in mapping.items():
    value = data.get(key)
    if value is not None:
        print(f"{var}={shlex.quote(str(value))}")
PY
    )"

    app_config_dir="${app_config_dir:-${xdg_config_home}/gws-switch}"
    config_dir="${config_dir:-${xdg_config_home}/gws}"
    gmail_config_dir="${gmail_config_dir:-${xdg_config_home}/gws-gmail}"
    accounts_dir="${accounts_dir:-${config_dir}/accounts}"
    state_file="${state_file:-${config_dir}/.current_account}"
    base_client_secret="${base_client_secret:-${config_dir}/client_secret.json}"
    manifest_file="${manifest_file:-${app_config_dir}/accounts.json}"
    config_file="${config_file:-${app_config_dir}/config.json}"
  fi

  if [[ -z "$raw_gws_bin" || ! -x "$raw_gws_bin" ]]; then
    raw_gws_bin="$(gws_switch_detect_raw_bin || true)"
  fi

  typeset -g GWS_SWITCH_RAW_BIN="$raw_gws_bin"
  typeset -g GWS_SWITCH_APP_CONFIG_DIR="$app_config_dir"
  typeset -g GWS_SWITCH_CONFIG_FILE="$config_file"
  typeset -g GWS_SWITCH_CONFIG_DIR="$config_dir"
  typeset -g GWS_SWITCH_GMAIL_CONFIG_DIR="$gmail_config_dir"
  typeset -g GWS_SWITCH_ACCOUNTS_DIR="$accounts_dir"
  typeset -g GWS_SWITCH_STATE_FILE="$state_file"
  typeset -g GWS_SWITCH_BASE_CLIENT_SECRET="$base_client_secret"
  typeset -g GWS_SWITCH_SECRETS_FILE="$secrets_file"
  typeset -g GWS_SWITCH_MANIFEST_FILE="$manifest_file"
  typeset -g GWS_SWITCH_DEFAULT_ACCOUNT="$default_account"
  typeset -g GWS_SWITCH_CONFIG_LOADED=1
}

gws_switch_apply_config

gws_switch_require_raw_bin() {
  emulate -L zsh
  [[ -x "$GWS_SWITCH_RAW_BIN" ]] || {
    print -u2 -- "gws-switch: raw gws binary not found at $GWS_SWITCH_RAW_BIN"
    return 1
  }
}

gws_switch_manifest_sync() {
  emulate -L zsh

  mkdir -p -- "${GWS_SWITCH_MANIFEST_FILE:h}" "$GWS_SWITCH_ACCOUNTS_DIR"

  python3 - "$GWS_SWITCH_MANIFEST_FILE" "$GWS_SWITCH_ACCOUNTS_DIR" "$GWS_SWITCH_CONFIG_DIR" "$GWS_SWITCH_GMAIL_CONFIG_DIR" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
accounts_dir = Path(sys.argv[2])
default_config_dir = sys.argv[3]
gmail_config_dir = sys.argv[4]

data = {"accounts": []}
if manifest_path.exists():
    try:
        data = json.loads(manifest_path.read_text())
    except Exception:
        data = {"accounts": []}

accounts = {}
for item in data.get("accounts", []):
    email = item.get("email")
    if email:
        accounts[email] = item

for path in sorted(accounts_dir.glob("*.json")):
    email = path.stem
    alias = "gmail" if email.endswith("@gmail.com") else "didi"
    config_dir = gmail_config_dir if alias == "gmail" else default_config_dir
    item = accounts.get(email, {})
    item.update(
        {
            "email": email,
            "alias": item.get("alias") or alias,
            "config_dir": item.get("config_dir") or config_dir,
            "account_file": str(path),
        }
    )
    accounts[email] = item

result = {"accounts": sorted(accounts.values(), key=lambda item: item["email"])}
manifest_path.write_text(json.dumps(result, indent=2) + "\n")
PY
}

gws_switch_manifest_register_account() {
  emulate -L zsh

  local account="$1"
  local alias_name="$2"
  local config_dir="$3"
  local account_file="${4:-}"

  mkdir -p -- "${GWS_SWITCH_MANIFEST_FILE:h}"

  python3 - "$GWS_SWITCH_MANIFEST_FILE" "$account" "$alias_name" "$config_dir" "$account_file" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
account = sys.argv[2]
alias_name = sys.argv[3]
config_dir = sys.argv[4]
account_file = sys.argv[5]

data = {"accounts": []}
if manifest_path.exists():
    try:
        data = json.loads(manifest_path.read_text())
    except Exception:
        data = {"accounts": []}

accounts = {item.get("email"): item for item in data.get("accounts", []) if item.get("email")}
item = accounts.get(account, {})
item["email"] = account
if alias_name:
    item["alias"] = alias_name
item["config_dir"] = config_dir
if account_file:
    item["account_file"] = account_file
accounts[account] = item

manifest_path.write_text(
    json.dumps({"accounts": sorted(accounts.values(), key=lambda item: item["email"])}, indent=2) + "\n"
)
PY
}

gws_switch_list_accounts() {
  emulate -L zsh
  gws_switch_manifest_sync

  python3 - "$GWS_SWITCH_MANIFEST_FILE" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
if not manifest_path.exists():
    raise SystemExit(0)

data = json.loads(manifest_path.read_text())
for item in data.get("accounts", []):
    email = item.get("email")
    if email:
        print(email)
PY
}

gws_switch_alias_for_account() {
  emulate -L zsh
  local account="${1:l}"

  case "$account" in
    *@gmail.com) print -r -- "gmail" ;;
    *@didi-labs.com|*@didiglobal.com|*@xiaojukeji.com) print -r -- "didi" ;;
  esac
}

gws_switch_read_default_account() {
  emulate -L zsh

  if [[ -n "${GWS_SWITCH_DEFAULT_ACCOUNT:-}" ]]; then
    print -r -- "$GWS_SWITCH_DEFAULT_ACCOUNT"
    return
  fi

  if [[ -n "${GWS_DEFAULT_ACCOUNT:-}" ]]; then
    print -r -- "$GWS_DEFAULT_ACCOUNT"
    return
  fi

  if [[ -f "$GWS_SWITCH_SECRETS_FILE" ]]; then
    local line value
    line="$(grep -E '^export GWS_DEFAULT_ACCOUNT=' "$GWS_SWITCH_SECRETS_FILE" | head -1)" || true
    if [[ -n "$line" ]]; then
      value="${line#export GWS_DEFAULT_ACCOUNT=}"
      value="${value#\"}"
      value="${value%\"}"
      print -r -- "$value"
      return
    fi
  fi

  local account
  for account in "${(@f)$(gws_switch_list_accounts)}"; do
    if [[ "$account" == *@didi-labs.com || "$account" == *@didiglobal.com || "$account" == *@xiaojukeji.com ]]; then
      print -r -- "$account"
      return
    fi
  done
}

gws_switch_account_source() {
  emulate -L zsh

  if [[ -n "${GOOGLE_WORKSPACE_CLI_ACCOUNT:-}" ]]; then
    print -r -- "env"
    return
  fi

  if [[ -f "$GWS_SWITCH_STATE_FILE" ]]; then
    local account
    account="$(<"$GWS_SWITCH_STATE_FILE")"
    if [[ -n "$account" ]]; then
      print -r -- "state"
      return
    fi
  fi

  if [[ -n "$(gws_switch_read_default_account)" ]]; then
    print -r -- "default"
  else
    print -r -- "unset"
  fi
}

gws_switch_effective_account() {
  emulate -L zsh

  if [[ -n "${GOOGLE_WORKSPACE_CLI_ACCOUNT:-}" ]]; then
    print -r -- "$GOOGLE_WORKSPACE_CLI_ACCOUNT"
    return
  fi

  if [[ -f "$GWS_SWITCH_STATE_FILE" ]]; then
    local account
    account="$(<"$GWS_SWITCH_STATE_FILE")"
    if [[ -n "$account" ]]; then
      print -r -- "$account"
      return
    fi
  fi

  gws_switch_read_default_account
}

gws_switch_resolve_account() {
  emulate -L zsh

  local query="${1:-}"
  local normalized="${query:l}"
  local -a accounts matches
  accounts=("${(@f)$(gws_switch_list_accounts)}")

  if [[ -z "$query" ]]; then
    gws_switch_effective_account
    return
  fi

  local account
  for account in "${accounts[@]}"; do
    if [[ "$account" == "$query" ]]; then
      print -r -- "$account"
      return 0
    fi
  done

  case "$normalized" in
    didi|work)
      for account in "${accounts[@]}"; do
        if [[ "$account" == *@didi-labs.com || "$account" == *@didiglobal.com || "$account" == *@xiaojukeji.com ]]; then
          print -r -- "$account"
          return 0
        fi
      done
      ;;
    gmail|personal)
      for account in "${accounts[@]}"; do
        if [[ "$account" == *@gmail.com ]]; then
          print -r -- "$account"
          return 0
        fi
      done
      ;;
  esac

  matches=()
  for account in "${accounts[@]}"; do
    if [[ "${account:l}" == *"$normalized"* ]]; then
      matches+=("$account")
    fi
  done

  if (( ${#matches[@]} == 1 )); then
    print -r -- "${matches[1]}"
    return 0
  fi

  if (( ${#matches[@]} > 1 )); then
    print -u2 -- "gws-switch: ambiguous account '$query'"
    printf '  %s\n' "${matches[@]}" >&2
    return 1
  fi

  print -u2 -- "gws-switch: no account matching '$query'"
  if (( ${#accounts[@]} > 0 )); then
    printf '  %s\n' "${accounts[@]}" >&2
  fi
  return 1
}

gws_switch_account_config_dir() {
  emulate -L zsh
  local account="$1"
  gws_switch_manifest_sync

  local config_dir
  config_dir="$(
    python3 - "$GWS_SWITCH_MANIFEST_FILE" "$account" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
account = sys.argv[2]
if manifest_path.exists():
    data = json.loads(manifest_path.read_text())
    for item in data.get("accounts", []):
        if item.get("email") == account and item.get("config_dir"):
            print(item["config_dir"])
            raise SystemExit(0)
PY
  )"

  if [[ -n "$config_dir" ]]; then
    print -r -- "$config_dir"
    return
  fi

  if [[ "$(gws_switch_alias_for_account "$account")" == "gmail" ]]; then
    print -r -- "$GWS_SWITCH_GMAIL_CONFIG_DIR"
  else
    print -r -- "$GWS_SWITCH_CONFIG_DIR"
  fi
}

gws_switch_runtime_credentials_file() {
  emulate -L zsh
  local config_dir="$1"

  if [[ -f "${config_dir}/credentials.json" ]]; then
    print -r -- "${config_dir}/credentials.json"
    return
  fi

  if [[ -f "${config_dir}/credentials.enc" ]]; then
    print -r -- "${config_dir}/credentials.enc"
    return
  fi

  print -r -- "${config_dir}/credentials.json"
}

gws_switch_creds_file() {
  emulate -L zsh
  local account="$1"
  print -r -- "${GWS_SWITCH_ACCOUNTS_DIR}/${account}.json"
}

gws_switch_cache_file() {
  emulate -L zsh
  local account="$1"
  print -r -- "${GWS_SWITCH_ACCOUNTS_DIR}/.token_cache_${account}"
}

gws_switch_clear_cache() {
  emulate -L zsh
  local account="$1"
  local cache_file
  cache_file="$(gws_switch_cache_file "$account")"
  [[ -f "$cache_file" ]] && rm -f -- "$cache_file"
}

gws_switch_write_state() {
  emulate -L zsh
  local account="$1"
  mkdir -p -- "${GWS_SWITCH_STATE_FILE:h}"
  print -r -- "$account" >| "$GWS_SWITCH_STATE_FILE"
  chmod 600 "$GWS_SWITCH_STATE_FILE"
}

gws_switch_proxy_env() {
  emulate -L zsh

  local proxy="${GWS_HTTP_PROXY:-${CLASH_HTTP_PROXY:-${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}}}"
  local bypass="localhost,127.0.0.1,::1"
  local extra_bypass="${NO_PROXY:-${no_proxy:-}}"
  local -a env_args

  env_args=(
    -u ALL_PROXY
    -u all_proxy
    -u HTTP_PROXY
    -u http_proxy
    -u HTTPS_PROXY
    -u https_proxy
    -u NO_PROXY
    -u no_proxy
  )

  if [[ -n "$proxy" ]]; then
    env_args+=(
      HTTP_PROXY="$proxy"
      HTTPS_PROXY="$proxy"
      http_proxy="$proxy"
      https_proxy="$proxy"
    )
  fi

  if [[ -n "$extra_bypass" ]]; then
    bypass="${bypass},${extra_bypass}"
  fi

  env_args+=(
    NO_PROXY="$bypass"
    no_proxy="$bypass"
  )

  env "${env_args[@]}" "$@"
}

gws_switch_write_client_secret_for_account() {
  emulate -L zsh

  local account="$1"
  local output_file="$2"
  local account_file
  account_file="$(gws_switch_creds_file "$account")"

  [[ -f "$account_file" ]] || {
    print -u2 -- "gws-switch: no stored account file for '$account'"
    return 1
  }

  python3 - "$account_file" "$output_file" <<'PY'
import json
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
data = json.loads(src.read_text())
client_id = data["client_id"]
client_secret = data["client_secret"]
project_id = client_id.split("-", 1)[0]

payload = {
    "installed": {
        "client_id": client_id,
        "project_id": project_id,
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_secret": client_secret,
        "redirect_uris": ["http://localhost"],
    }
}

dst.write_text(json.dumps(payload, indent=2) + "\n")
PY
  chmod 600 "$output_file"
}

gws_switch_run_with_account() {
  emulate -L zsh

  local account="$1"
  shift

  gws_switch_require_raw_bin || return 1

  if [[ -z "$account" ]]; then
    print -u2 -- "gws: no active account"
    print -u2 -- "Use gws-switch-gmail / gws-switch-didi / gws-switch-login first."
    return 1
  fi

  local config_dir runtime_credentials alias_name
  config_dir="$(gws_switch_account_config_dir "$account")"
  runtime_credentials="$(gws_switch_runtime_credentials_file "$config_dir")"
  alias_name="$(gws_switch_alias_for_account "$account")"

  if [[ ! -f "$runtime_credentials" ]]; then
    print -u2 -- "gws: account '$account' is not logged in"
    if [[ -n "$alias_name" ]]; then
      print -u2 -- "Run: gws-login ${alias_name}"
    else
      print -u2 -- "Run: gws-login ${account}"
    fi
    return 1
  fi

  gws_switch_proxy_env env GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$config_dir" "$GWS_SWITCH_RAW_BIN" "$@"
}

gws_switch_run_auth() {
  emulate -L zsh

  gws_switch_require_raw_bin || return 1

  local account config_dir
  account="$(gws_switch_effective_account)"

  if [[ -n "$account" ]]; then
    config_dir="$(gws_switch_account_config_dir "$account")"
  else
    config_dir="$GWS_SWITCH_CONFIG_DIR"
  fi

  gws_switch_proxy_env env GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$config_dir" "$GWS_SWITCH_RAW_BIN" auth "$@"
}

gws_switch_cmd_gws() {
  emulate -L zsh

  case "${1:-}" in
    ""|help|--help|-h)
      gws_switch_print_usage
      return 0
      ;;
    version|--version|-V)
      print -r -- "gws-switch $(gws_switch_version)"
      return 0
      ;;
    use|as)
      shift
      gws_switch_cmd_use "$@"
      return
      ;;
    who)
      shift
      gws_switch_cmd_who "$@"
      return
      ;;
    accounts)
      shift
      gws_switch_cmd_accounts "$@"
      return
      ;;
    do)
      shift
      gws_switch_cmd_do "$@"
      return
      ;;
    login)
      shift
      gws_switch_cmd_login "$@"
      return
      ;;
    status)
      shift
      gws_switch_cmd_status "$@"
      return
      ;;
    doctor)
      shift
      gws_switch_cmd_doctor "$@"
      return
      ;;
    config-init)
      shift
      gws_switch_cmd_config_init "$@"
      return
      ;;
    raw)
      shift
      gws_switch_require_raw_bin || return 1
      gws_switch_proxy_env "$GWS_SWITCH_RAW_BIN" "$@"
      return
      ;;
  esac

  gws_switch_require_raw_bin || return 1

  if [[ -n "${GOOGLE_WORKSPACE_CLI_TOKEN:-}" ]]; then
    exec "$GWS_SWITCH_RAW_BIN" "$@"
  fi

  if [[ "${1:-}" == "auth" ]]; then
    shift
    gws_switch_run_auth "$@"
    return
  fi

  gws_switch_run_with_account "$(gws_switch_effective_account)" "$@"
}

gws_switch_cmd_use() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch use <account|gmail|didi>"
    return 0
  fi

  if [[ "${1:-}" == "--clear" ]]; then
    unset GOOGLE_WORKSPACE_CLI_ACCOUNT
    [[ -f "$GWS_SWITCH_STATE_FILE" ]] && rm -f -- "$GWS_SWITCH_STATE_FILE"
    print -r -- "Cleared gws account override."
    return
  fi

  local account
  account="$(gws_switch_resolve_account "${1:-}")" || return 1
  export GOOGLE_WORKSPACE_CLI_ACCOUNT="$account"
  gws_switch_write_state "$account"
  print -r -- "Switched to: $account"
}

gws_switch_cmd_who() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch who"
    return 0
  fi

  local account source alias_name
  account="$(gws_switch_effective_account)"
  source="$(gws_switch_account_source)"

  if [[ -z "$account" ]]; then
    print -r -- "Current: (unset) [source: $source]"
    return 1
  fi

  alias_name="$(gws_switch_alias_for_account "$account")"
  if [[ -n "$alias_name" ]]; then
    print -r -- "Current: $account [alias: $alias_name, source: $source]"
  else
    print -r -- "Current: $account [source: $source]"
  fi
}

gws_switch_cmd_accounts() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch accounts"
    return 0
  fi

  local current source account marker alias_name
  current="$(gws_switch_effective_account)"
  source="$(gws_switch_account_source)"
  print -r -- "Current source: $source"

  while IFS= read -r account; do
    [[ -n "$account" ]] || continue
    marker=" "
    [[ "$account" == "$current" ]] && marker="*"
    alias_name="$(gws_switch_alias_for_account "$account")"
    if [[ -n "$alias_name" ]]; then
      print -r -- "${marker} ${account} [alias: ${alias_name}]"
    else
      print -r -- "${marker} ${account}"
    fi
  done < <(gws_switch_list_accounts)
}

gws_switch_cmd_do() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch do <account|gmail|didi> <gws args...>"
    return 0
  fi

  local account
  account="$(gws_switch_resolve_account "${1:-}")" || return 1
  shift || return 1

  (( $# > 0 )) || {
    print -u2 -- "Usage: gws-do <account> <gws args...>"
    return 1
  }

  gws_switch_run_with_account "$account" "$@"
}

gws_switch_cmd_login() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch login <account|gmail|didi> [upstream auth login args...]"
    return 0
  fi

  gws_switch_require_raw_bin || return 1

  local requested config_dir login_client_secret runtime_credentials alias_name
  requested="$(gws_switch_resolve_account "${1:-}")" || return 1
  shift $(( $# > 0 ? 1 : 0 )) || true

  config_dir="$(gws_switch_account_config_dir "$requested")"
  login_client_secret="${config_dir}/client_secret.json"
  alias_name="$(gws_switch_alias_for_account "$requested")"

  gws_switch_manifest_register_account "$requested" "$alias_name" "$config_dir" "$(gws_switch_creds_file "$requested")"

  mkdir -p -- "$config_dir"

  if [[ -f "$(gws_switch_creds_file "$requested")" ]]; then
    gws_switch_write_client_secret_for_account "$requested" "$login_client_secret" || return 1
  elif [[ -f "$GWS_SWITCH_BASE_CLIENT_SECRET" && "$login_client_secret" != "$GWS_SWITCH_BASE_CLIENT_SECRET" ]]; then
    cp "$GWS_SWITCH_BASE_CLIENT_SECRET" "$login_client_secret"
    chmod 600 "$login_client_secret"
  fi

  if [[ -n "$alias_name" ]]; then
    print -u2 -- "gws: opening browser login for '$alias_name' -> $requested"
  else
    print -u2 -- "gws: opening browser login for '$requested'"
  fi

  gws_switch_proxy_env env GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$config_dir" "$GWS_SWITCH_RAW_BIN" auth login "$@" || return 1

  runtime_credentials="$(gws_switch_runtime_credentials_file "$config_dir")"
  [[ -f "$runtime_credentials" ]] || {
    print -u2 -- "gws: login completed but no credentials file was written under $config_dir"
    return 1
  }

  if [[ -f "${config_dir}/credentials.json" ]]; then
    mkdir -p -- "$GWS_SWITCH_ACCOUNTS_DIR"
    python3 - "${config_dir}/credentials.json" "$(gws_switch_creds_file "$requested")" <<'PY'
import json
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
data = json.loads(src.read_text())
data.pop("type", None)
dst.write_text(json.dumps(data, indent=2) + "\n")
PY
    chmod 600 "$(gws_switch_creds_file "$requested")"
    gws_switch_clear_cache "$requested"
  fi

  gws_switch_manifest_register_account "$requested" "$alias_name" "$config_dir" "$(gws_switch_creds_file "$requested")"
  export GOOGLE_WORKSPACE_CLI_ACCOUNT="$requested"
  gws_switch_write_state "$requested"
  print -r -- "Updated credentials for: $requested"
}

gws_switch_cmd_status() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch status [account|gmail|didi]"
    return 0
  fi

  local account source creds_file cache_file cache_age alias_name config_dir runtime_credentials
  local client_id client_secret refresh_token

  if [[ -n "${1:-}" ]]; then
    account="$(gws_switch_resolve_account "$1")" || return 1
    source="explicit"
  else
    account="$(gws_switch_effective_account)"
    source="$(gws_switch_account_source)"
  fi

  [[ -n "$account" ]] || {
    print -u2 -- "gws: no active account"
    return 1
  }

  creds_file="$(gws_switch_creds_file "$account")"
  cache_file="$(gws_switch_cache_file "$account")"
  alias_name="$(gws_switch_alias_for_account "$account")"
  config_dir="$(gws_switch_account_config_dir "$account")"
  runtime_credentials="$(gws_switch_runtime_credentials_file "$config_dir")"

  print -r -- "account: $account"
  [[ -n "$alias_name" ]] && print -r -- "alias: $alias_name"
  print -r -- "source: $source"
  print -r -- "manifest_file: $GWS_SWITCH_MANIFEST_FILE"
  print -r -- "manifest_exists: $([[ -f "$GWS_SWITCH_MANIFEST_FILE" ]] && print true || print false)"
  print -r -- "config_dir: $config_dir"
  print -r -- "runtime_credentials: $runtime_credentials"
  print -r -- "runtime_credentials_exists: $([[ -f "$runtime_credentials" ]] && print true || print false)"
  print -r -- "credentials_file: $creds_file"
  print -r -- "credentials_exists: $([[ -f "$creds_file" ]] && print true || print false)"

  if [[ -f "$creds_file" ]]; then
    eval "$(
      python3 - "$creds_file" <<'PY'
import json
import shlex
import sys

with open(sys.argv[1]) as f:
    data = json.load(f)

for key in ("client_id", "client_secret", "refresh_token"):
    print(f"{key}={shlex.quote(str(data.get(key, '')))}")
PY
    )" || return 1
    print -r -- "client_id: $client_id"
    print -r -- "client_secret: $([[ -n "$client_secret" ]] && print present || print missing)"
    print -r -- "refresh_token: $([[ -n "$refresh_token" ]] && print present || print missing)"
  fi

  print -r -- "cache_file: $cache_file"
  if [[ -f "$cache_file" ]]; then
    cache_age=$(( $(date +%s) - $(head -1 "$cache_file" 2>/dev/null) ))
    print -r -- "cache_exists: true"
    print -r -- "cache_age_seconds: $cache_age"
  else
    print -r -- "cache_exists: false"
  fi
}

gws_switch_cmd_doctor() {
  emulate -L zsh

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print -r -- "Usage: gws-switch doctor [account|gmail|didi]"
    return 0
  fi

  local account source alias_name config_dir runtime_credentials runtime_kind
  local raw_bin_status config_file_status manifest_status state_status auth_probe

  if [[ -n "${1:-}" ]]; then
    account="$(gws_switch_resolve_account "$1")" || return 1
    source="explicit"
  else
    account="$(gws_switch_effective_account)"
    source="$(gws_switch_account_source)"
  fi

  if [[ -x "$GWS_SWITCH_RAW_BIN" ]]; then
    raw_bin_status="ok"
  else
    raw_bin_status="missing"
  fi

  [[ -f "$GWS_SWITCH_CONFIG_FILE" ]] && config_file_status="present" || config_file_status="absent"
  [[ -f "$GWS_SWITCH_MANIFEST_FILE" ]] && manifest_status="present" || manifest_status="absent"
  [[ -f "$GWS_SWITCH_STATE_FILE" ]] && state_status="present" || state_status="absent"

  print -r -- "doctor: gws-switch"
  print -r -- "project_root: $GWS_SWITCH_ROOT"
  print -r -- "raw_gws_bin: $GWS_SWITCH_RAW_BIN"
  print -r -- "raw_gws_bin_status: $raw_bin_status"
  print -r -- "config_file: $GWS_SWITCH_CONFIG_FILE"
  print -r -- "config_file_status: $config_file_status"
  print -r -- "manifest_file: $GWS_SWITCH_MANIFEST_FILE"
  print -r -- "manifest_status: $manifest_status"
  print -r -- "state_file: $GWS_SWITCH_STATE_FILE"
  print -r -- "state_status: $state_status"
  print -r -- "default_account: ${GWS_SWITCH_DEFAULT_ACCOUNT:-${GWS_DEFAULT_ACCOUNT:-}}"

  if [[ -z "$account" ]]; then
    print -r -- "current_account: (unset)"
    print -r -- "account_source: $source"
    return 0
  fi

  alias_name="$(gws_switch_alias_for_account "$account")"
  config_dir="$(gws_switch_account_config_dir "$account")"
  runtime_credentials="$(gws_switch_runtime_credentials_file "$config_dir")"
  runtime_kind="${runtime_credentials##*.}"

  print -r -- "current_account: $account"
  [[ -n "$alias_name" ]] && print -r -- "current_alias: $alias_name"
  print -r -- "account_source: $source"
  print -r -- "current_config_dir: $config_dir"
  print -r -- "runtime_credentials: $runtime_credentials"
  print -r -- "runtime_credentials_kind: $runtime_kind"
  print -r -- "runtime_credentials_exists: $([[ -f "$runtime_credentials" ]] && print true || print false)"
  print -r -- "account_registry_file: $(gws_switch_creds_file "$account")"
  print -r -- "account_registry_exists: $([[ -f "$(gws_switch_creds_file "$account")" ]] && print true || print false)"

  auth_probe="$(
    python3 - "$GWS_SWITCH_RAW_BIN" "$config_dir" <<'PY'
import os
import subprocess
import sys

raw_bin = sys.argv[1]
config_dir = sys.argv[2]
env = os.environ.copy()
env["GOOGLE_WORKSPACE_CLI_CONFIG_DIR"] = config_dir

try:
    proc = subprocess.run(
        [raw_bin, "auth", "export"],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
        timeout=5,
    )
except subprocess.TimeoutExpired:
    print("timeout")
except Exception as exc:
    print(f"error:{type(exc).__name__}")
else:
    if proc.returncode == 0:
        print("ok")
    else:
        err = (proc.stderr or "").strip().splitlines()
        tail = err[-1] if err else f"exit:{proc.returncode}"
        print(f"fail:{tail}")
PY
  )"
  print -r -- "auth_export_probe: $auth_probe"
}

gws_switch_cmd_config_init() {
  emulate -L zsh

  local force=0
  local target="${GWS_SWITCH_CONFIG_FILE}"

  while (( $# > 0 )); do
    case "$1" in
      --help|-h)
        print -r -- "Usage: gws-switch config-init [--force] [--path <file>]"
        return 0
        ;;
      --force) force=1 ;;
      --path)
        shift || {
          print -u2 -- "Usage: gws-config-init [--force] [--path <file>]"
          return 1
        }
        target="$1"
        ;;
      *)
        print -u2 -- "Usage: gws-config-init [--force] [--path <file>]"
        return 1
        ;;
    esac
    shift || true
  done

  mkdir -p -- "${target:h}"

  if [[ -f "$target" && "$force" != "1" ]]; then
    print -u2 -- "gws-config-init: config already exists at $target"
    print -u2 -- "Run with --force to overwrite."
    return 1
  fi

  python3 - "$target" "$GWS_SWITCH_RAW_BIN" "$GWS_SWITCH_APP_CONFIG_DIR" "$GWS_SWITCH_CONFIG_DIR" "$GWS_SWITCH_GMAIL_CONFIG_DIR" "$GWS_SWITCH_ACCOUNTS_DIR" "$GWS_SWITCH_STATE_FILE" "$GWS_SWITCH_BASE_CLIENT_SECRET" "$GWS_SWITCH_SECRETS_FILE" "$GWS_SWITCH_MANIFEST_FILE" "$(gws_switch_read_default_account)" <<'PY'
import json
import sys
from pathlib import Path

target = Path(sys.argv[1])
payload = {
    "raw_gws_bin": sys.argv[2],
    "app_config_dir": sys.argv[3],
    "config_dir": sys.argv[4],
    "gmail_config_dir": sys.argv[5],
    "accounts_dir": sys.argv[6],
    "state_file": sys.argv[7],
    "base_client_secret": sys.argv[8],
    "secrets_file": sys.argv[9],
    "manifest_file": sys.argv[10],
    "default_account": sys.argv[11],
}
target.write_text(json.dumps(payload, indent=2) + "\n")
PY

  print -r -- "Wrote config: $target"
}
