# Security Policy

## Reporting a vulnerability

**Do not open a public issue for security problems.**

Report privately through GitHub:
**Security → Advisories → Report a vulnerability** on this repository
(https://github.com/reallysec/signaldesk/security/advisories/new), or email
security@reallysec.com.

Please include the affected version (Settings → Online update, or `APP_IMAGE_TAG` in `.env`),
steps to reproduce, and the impact you observed. We aim to acknowledge reports within 3 business
days and will keep you updated until a fix is released. We are happy to credit reporters in the
release notes unless you prefer to stay anonymous.

## Supported versions

Security fixes are made on the latest release. Please upgrade before reporting, if you can.

## Scope

In scope: the SignalDesk application as shipped in the delivery bundle, the default configuration
`install.sh` generates, and the online update mechanism.

Out of scope: deployments that changed the defaults insecurely (for example exposing the database
or Redis to the network, or weakening the generated secrets), and third-party services SignalDesk
integrates with.

---

# 安全策略

**安全问题请不要开公开 issue。** 请在本仓库的 **Security → Advisories → Report a vulnerability**
私下提交（链接见上），或发邮件至 security@reallysec.com。附上受影响的版本（设置 › 在线更新，或
`.env` 里的 `APP_IMAGE_TAG`）、复现步骤和影响。我们争取 3 个工作日内确认，并持续同步进展直到修复
发布；除非你希望匿名，我们会在发布说明里致谢。

安全修复发布在最新版本上。范围：交付包里的 SignalDesk 应用、`install.sh` 生成的默认配置、在线更新
机制；不含以不安全方式改动默认值的部署（如把数据库或 Redis 暴露到网络、削弱生成的密钥）以及
SignalDesk 所集成的第三方服务。
