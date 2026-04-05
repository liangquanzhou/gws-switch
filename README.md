# gws-switch

Local multi-account wrapper for `googleworkspace-cli` (`gws`).

Google Workspace 多账号切换包装层。
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

Main entry behavior:

- `gws-switch --help`
- `gws-switch --version`
- `gws-switch raw <gws args...>`
- `gws-switch <upstream gws args...>`

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

- 个人多账号使用
- 小团队共享同一套命令习惯
- 已经安装过上游 `gws` 的环境

前置条件：

- 已安装上游 `googleworkspace-cli` / `gws`
- 系统可用 `zsh`
- 已具备 Google OAuth 授权能力

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

推荐正式使用 Homebrew 安装。这样本地与发布版的命令、目录结构和升级方式保持一致。

### Homebrew

```bash
brew tap liangquanzhou/tap
brew install liangquanzhou/tap/gws-switch
```

如果你还没有安装上游 `gws`，需要先单独安装它；`gws-switch` 是包装层，不会替代上游客户端本身。

安装后可执行文件会在 Homebrew 前缀下，例如：

- `/opt/homebrew/bin/gws-switch`
- `/opt/homebrew/bin/gws-switch-gmail`
- `/opt/homebrew/bin/gws-switch-doctor`

### Local Dev

仅在开发或调试仓库时使用本地安装：

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
- `app_config_dir`
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

## Testing

Local smoke test:

```bash
zsh scripts/test.sh
```

This test suite uses a fake upstream `gws` binary and temporary config directories, so it does not depend on your real Google credentials.

## Publish Notes

If you publish this project, there are two different install surfaces:

1. Local/manual install  
This is for development only. It uses the same canonical prefixed commands as the published package.

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

如果你的 shell 里同时存在本地开发版和 brew 版，建议让 dotfiles 优先 source brew 安装目录，避免交互式 shell 和非交互式 shell 指向不同实现。

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

- auto-detects the upstream `gws` binary from common install locations when possible
- uses upstream keyring/encrypted credential storage
- keeps dotfiles as a thin compatibility layer only
- includes a stable Homebrew formula plus optional `--HEAD` install path for development

## Release Process

```bash
zsh scripts/package-release.sh
git tag v0.1.0
git push origin main --tags
```

Then update the tap formula with:

- release tarball URL
- `sha256`
- `version`

Track released changes in [CHANGELOG.md](./CHANGELOG.md).

## License

MIT. See [LICENSE](./LICENSE).

## Project Docs

- [CHANGELOG.md](./CHANGELOG.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [SECURITY.md](./SECURITY.md)
