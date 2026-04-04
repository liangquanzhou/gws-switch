# gws-switch

Local multi-account wrapper for `googleworkspace-cli` (`gws`).

面向个人/团队内部的 Google Workspace 多账号切换包装层。
它复用上游 `gws` 的认证和 keyring 机制，只补多账号切换、配置管理和诊断能力。

## Commands

- `gws-switch`
- `gws-switch-use <account|gmail|didi>`
- `gws-switch-gmail`
- `gws-switch-didi`
- `gws-switch-who`
- `gws-switch-accounts`
- `gws-switch-do <account> <gws args...>`
- `gws-switch-login <account|gmail|didi>`
- `gws-switch-status [account|gmail|didi]`
- `gws-switch-doctor [account|gmail|didi]`
- `gws-switch-config-init [--force] [--path <file>]`

## 中文说明

日常本地安装后，主要用这些短命令：

- `gws-switch-gmail`
- `gws-switch-didi`
- `gws-switch-who`
- `gws-switch-accounts`
- `gws-switch-status`
- `gws-switch-doctor`
- `gws-switch-config-init`

设计原则：

- 不替代上游 `gws`
- 复用上游 `gws auth login/export`
- 只负责多账号状态、路由、诊断和配置

适用范围：

- 个人机器
- 团队内部少量复用
- 已经安装过上游 `gws` 的环境

当前还不适合直接当成“开箱即用的公开软件”理解，原因主要是：

- 仍然依赖上游 `gws`
- 仍然假设用户知道 Google OAuth / keyring / config dir 概念
- 真实发布前还需要收敛命令命名和安装模型

兼容说明：

- 正式命令统一为 `gws-switch-*`
- 旧的 `gws-*` 不再是默认公开接口
- 如果你本地确实还想保留旧别名，可以自行在 shell 里做 alias

## Layout

- wrapper config: `~/.config/gws-switch`
- work runtime config: `~/.config/gws`
- gmail runtime config: `~/.config/gws-gmail`
- account registry: `~/.config/gws/accounts`
- wrapper manifest: `~/.config/gws-switch/accounts.json`
- active account state: `~/.config/gws/.current_account`

## Install

```bash
zsh scripts/install-local.sh
```

## Packaging

Build a local release archive:

```bash
zsh scripts/package-release.sh
```

This writes a tarball under `dist/` and prints its SHA256.

## Config

Optional config file:

- `~/.config/gws-switch/config.json`

Example fields:

- `raw_gws_bin`
- `config_dir`
- `gmail_config_dir`
- `accounts_dir`
- `state_file`
- `base_client_secret`
- `secrets_file`
- `manifest_file`
- `default_account`

Bootstrap or refresh the local config file:

```bash
gws-switch-config-init
gws-switch-config-init --force
```

## Publish Notes

If you publish this project, there are two different install surfaces:

1. Local/manual install  
This uses the same canonical prefixed commands as the published package.

2. Homebrew install  
The Homebrew formula installs prefixed commands only:

- `gws-switch`
- `gws-switch-use`
- `gws-switch-gmail`
- `gws-switch-didi`
- `gws-switch-who`
- `gws-switch-accounts`
- `gws-switch-do`
- `gws-switch-login`
- `gws-switch-status`
- `gws-switch-doctor`
- `gws-switch-config-init`

This separation is intentional.  
This avoids shadowing the upstream `gws` binary.

## Security Notes

Tracked source files should not contain live OAuth credentials, refresh tokens, or encrypted runtime credentials.

Files that should stay local and must not be committed:

- `~/.config/gws-switch/config.json`
- `~/.config/gws-switch/accounts.json`
- `~/.config/gws/credentials.json`
- `~/.config/gws/credentials.enc`
- `~/.config/gws-gmail/credentials.enc`

If you publish the repository, also check git author identity, because commit metadata can expose your personal email.

## Notes

- wraps the upstream binary at `/opt/homebrew/bin/gws`
- uses upstream keyring/encrypted credential storage
- keeps dotfiles as a thin compatibility layer only
- includes a HEAD-only Homebrew formula draft in your tap until a public repo/release exists
