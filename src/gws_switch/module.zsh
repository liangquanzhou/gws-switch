#!/bin/zsh

typeset -g GWS_SWITCH_ROOT="${GWS_SWITCH_ROOT:-${${(%):-%N}:A:h:h:h}}"
source "${GWS_SWITCH_ROOT}/src/gws_switch/common.zsh"

gws-switch() {
  gws_switch_cmd_gws "$@"
}

gws-switch-raw() {
  "$GWS_SWITCH_RAW_BIN" "$@"
}

gws-switch-use() {
  gws_switch_cmd_use "$@"
}

gws-switch-as() {
  gws_switch_cmd_use "$@"
}

gws-switch-who() {
  gws_switch_cmd_who "$@"
}

gws-switch-accounts() {
  gws_switch_cmd_accounts "$@"
}

gws-switch-do() {
  gws_switch_cmd_do "$@"
}

gws-switch-login() {
  gws_switch_cmd_login "$@"
}

gws-switch-status() {
  gws_switch_cmd_status "$@"
}

gws-switch-doctor() {
  gws_switch_cmd_doctor "$@"
}

gws-switch-config-init() {
  gws_switch_cmd_config_init "$@"
}

alias gws-switch-didi='gws-switch-use didi'
alias gws-switch-gmail='gws-switch-use gmail'

if [[ "${GWS_SWITCH_ENABLE_COMPAT_ALIASES:-0}" == "1" ]]; then
  alias gws='gws-switch'
  alias gws-raw='gws-switch-raw'
  alias gws-use='gws-switch-use'
  alias gws-as='gws-switch-as'
  alias gws-who='gws-switch-who'
  alias gws-accounts='gws-switch-accounts'
  alias gws-do='gws-switch-do'
  alias gws-login='gws-switch-login'
  alias gws-status='gws-switch-status'
  alias gws-doctor='gws-switch-doctor'
  alias gws-config-init='gws-switch-config-init'
  alias gws-didi='gws-switch-didi'
  alias gws-gmail='gws-switch-gmail'
fi
