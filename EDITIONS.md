# SignalDesk Editions

[中文](./EDITIONS.zh-CN.md)

SignalDesk ships as a single self-hosted image. Every edition runs the same
build — an edition is a license, not a different download. Upgrading means
applying a license key, not migrating data or swapping images.

**Community Edition is free and self-hosted, for up to 5 active staff users.**
Enterprise adds every commercial feature and has no user limit. A 14-day trial
unlocks all of Enterprise.

| | **Community** | **Enterprise** |
|---|:---:|:---:|
| Price | Free | Quote |
| Active staff users | 5 | Unlimited |
| Tickets & alerts | Unlimited | Unlimited |
| Support | Community | Priority |

Legend: ● included · ○ not included · ◐ on the roadmap (not yet shipped)

## Ticketing & alerts

| | CE | Ent |
|---|:--:|:--:|
| Full ticket lifecycle — 7-state machine, bulk actions | ● | ● |
| Comments, timeline, ticket linking | ● | ● |
| Attachments (local disk or S3 / MinIO) | ● | ● |
| Ticket templates, CSV export, closing reports, favorites | ● | ● |
| Alert ingestion — Splunk, Elasticsearch, Wazuh, generic webhook | ● | ● |
| Alert deduplication, entity correlation, storm suppression | ● | ● |
| Public ticket intake API | ● | ● |

## SLA & assignment

| | CE | Ent |
|---|:--:|:--:|
| SLA rules, breach detection, breach warnings | ● | ● |
| Business calendars, clock pause while `PENDING` | ● | ● |
| Manual assignment, round-robin, least-loaded | ● | ● |
| Multi-level escalation (L1 → L2 → L3) with group targets | ○ | ● |
| Skill-matched & customer-owner assignment with load scoring | ○ | ● |
| Automation rule engine (7 trigger types) | ○ | ● |

## AI

| | CE | Ent |
|---|:--:|:--:|
| 11 built-in AI providers, plus any OpenAI-compatible endpoint | ● | ● |
| On-demand AI analysis and AI-drafted closing reports | ● | ● |
| AI call auditing | ● | ● |
| Automatic AI triage on ticket creation | ○ | ● |
| AI guardrails — output limits, sensitive-word masking, per-tenant quota | ○ | ● |

## Collaboration & knowledge

| | CE | Ent |
|---|:--:|:--:|
| 7 notification channels — Teams, Feishu, DingTalk, WeCom, Slack, email, webhook | ● | ● |
| In-app notifications, real-time SSE push, deduplication, per-user preferences | ● | ● |
| Knowledge base with article feedback | ● | ● |
| Playbooks — attach to tickets, track step completion | ● | ● |
| Outbound webhooks with secret rotation and delivery tests | ● | ● |

## Authentication, permissions & tenancy

| | CE | Ent |
|---|:--:|:--:|
| JWT session auth, CSRF protection, rate limiting | ● | ● |
| TOTP two-factor auth, enforced MFA, password policy, token revocation | ● | ● |
| 6 built-in SOC roles (L1 / L2 / L3 / Manager / Ops Admin / Customer) | ● | ● |
| Single tenant | ● | ● |
| Teams & user groups | ● | ● |
| SSO — SAML, OIDC, OAuth2, LDAP sync | ○ | ● |
| SCIM user provisioning | ○ | ● |
| Multi-tenant / MSSP — customer tenants, tenant switching, cross-tenant views | ○ | ● |
| Custom roles & fine-grained permissions | ○ | ◐ |

**Core security is never a paid feature.** Two-factor auth, password policy, CSRF
protection, rate limiting, and audit logging are in Community Edition and will
stay there.

## Reporting, audit & operations

| | CE | Ent |
|---|:--:|:--:|
| Dashboards — statistics and trends | ● | ● |
| Audit logging and audit UI (30-day retention in CE) | ● | ● |
| Configurable retention windows for audit, AI, and notification tables | ● | ● |
| High availability across multiple instances | ● | ● |
| White-labeling — product name | ● | ● |
| Unlimited audit retention and export | ○ | ● |
| Scheduled reports — CSV / JSON, email subscriptions | ○ | ● |
| In-product update channel | ● | ● |
| Asset CMDB with criticality weighting | ● | ● |
| API key management and raised rate limits | ● | ● |
| White-labeling — logo, theme, custom domain | ○ | ◐ |

---

## FAQ

**Is Community Edition open source?**
No. SignalDesk is proprietary and its source code is not published. Community
Edition is free of charge and free to run in production, including commercially,
under the [SignalDesk EULA](./LICENSE).

**Is there a user cap?**
Community Edition allows up to 5 active users; Enterprise is unlimited. Only **active staff** accounts count (L1 / L2 / L3,
managers, admins): customer portal users never use a seat, deactivated or deleted users
free theirs, and all tenants of a multi-tenant install count together.
Tickets, alerts, and notification channels are never capped. When Community Edition is full, adding
or re-activating a user prompts an upgrade; existing users keep working.

**What does ◐ mean?**
On the roadmap, not shipped yet. We mark these explicitly rather than listing
them as available. They are not billable until they ship.

**What happens if my commercial license expires?**
Paid capabilities switch off; everything else keeps running. Skill-matched and
customer-owner assignment rules are skipped and tickets fall through to your
round-robin or least-loaded rules (or the manual queue if none match),
automatic triage stops while manual AI
analysis stays available, no tickets are lost, no data is locked. You land
back on Community Edition behaviour.

**Can I move from Community to Enterprise without downtime?**
Yes. Same image, same database. Apply the license key and the paid
capabilities activate.

**Can I run Community Edition air-gapped?**
Yes. Community Edition never contacts a license server for licensing. Its only
outbound call is a daily download of the signed release manifest from GitHub
to check for a newer version, which sends nothing to Reallysec; set `SIGNALDESK_UPDATE_CHECK=0`
to turn it off and upgrade with the delivery bundle instead. Enterprise Edition
supports offline licensing; an offline-activated install never phones home.
