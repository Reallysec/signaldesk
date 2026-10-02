#!/usr/bin/env bash
# SignalDesk 一行安装 / 升级。
#
#   curl -fsSL https://github.com/reallysec/signaldesk/releases/latest/download/install.sh | sudo bash
#
# 选项：--version <x.y.z>   装指定版本（默认最新版）
#       --dir <path>        安装目录（默认 /opt/signaldesk）
#       --mirror github|cn  github：只用 GitHub Releases；cn：先国内镜像（腾讯云 COS）再 GitHub。
#                           默认先 GitHub，失败再国内镜像。等价环境变量 SIGNALDESK_MIRROR。
#       --download-only     只下载并校验交付包到当前目录，不安装（拷到断网主机手动部署）
#
# 各版本是同一个交付包：不导入许可证是社区版，在 设置 › 许可证 导入后原地变企业版。
# 重复运行（装新版本）会保留安装目录里的 .env 与 data/（许可证激活状态、附件、更新暂存）。
set -euo pipefail

PRODUCT="SignalDesk"
STEM="SignalDesk"                                  # 交付包：<STEM>-<version>.tar.gz
GH_REPO="reallysec/signaldesk"
DIR="/opt/signaldesk"
# 国内镜像（腾讯云 COS）：<base>/signaldesk/<version>/<file> 与 .../latest/VERSION。
# 存储桶还没建，这个默认值是占位；没替换（也没设 SIGNALDESK_COS_BASE）时直接跳过镜像。
COS_PLACEHOLDER="https://signaldesk-releases-XXXXXXXX.cos.ap-shanghai.myqcloud.com"
COS_BASE="${SIGNALDESK_COS_BASE:-$COS_PLACEHOLDER}"
COS_PREFIX="signaldesk"
# GitHub 地址可覆盖，测试用 file:// 目录离线跑。
GH_BASE="${SIGNALDESK_GITHUB_BASE:-https://github.com/$GH_REPO/releases}"
# 容器以 UID 65532（distroless nonroot）运行，bind mount 的目录要归它。
APP_UID=65532

VERSION=""; DOWNLOAD_ONLY=0; MIRROR="${SIGNALDESK_MIRROR:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --download-only) DOWNLOAD_ONLY=1; shift ;;
    --version) VERSION="${2#v}"; shift 2 ;;
    --dir)     DIR="${2:?}"; shift 2 ;;
    --mirror)  MIRROR="${2:?}"; shift 2 ;;
    -h|--help) sed -n '2,14p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

case "$MIRROR" in
  "")     ORDER="github cn" ;;
  github) ORDER="github" ;;
  cn)     ORDER="cn github" ;;
  *) fail "--mirror must be github or cn" ;;
esac
[ -z "$VERSION" ] || printf '%s' "$VERSION" | grep -Eq '^[0-9]+(\.[0-9]+)*$' || fail "bad --version: $VERSION"

# ── 前置检查 ─────────────────────────────────────────────────────────────────
for c in curl tar sha256sum; do command -v "$c" >/dev/null || fail "missing command: $c"; done
if [ "$DOWNLOAD_ONLY" = 0 ]; then
  [ "$(uname -s)" = Linux ] || fail "Linux only."
  [ "$(id -u)" = 0 ] || fail "run as root: pipe to 'sudo bash'."
  command -v docker >/dev/null || fail "Docker Engine 24+ is required. Install it first, e.g.: curl -fsSL https://get.docker.com | sh"
  docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is required (the docker compose plugin)."
fi

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# 国内访问 GitHub 常见「连上了但几乎不动」：10 KB/s 以下持续 30 秒算失败，换下一个源。
CURL=(curl -fL --retry 2 --connect-timeout 15 --speed-limit 10240 --speed-time 30)

# 最新版本：GitHub 走 /releases/latest 重定向（不走 API，没有限流），COS 读 latest/VERSION。
github_latest() {
  local u; u="$("${CURL[@]}" -sS -o /dev/null -w '%{url_effective}' "$GH_BASE/latest" 2>/dev/null)" || return 1
  u="${u##*/}"
  case "$u" in v[0-9]*) printf '%s' "${u#v}" ;; *) return 1 ;; esac
}
cos_latest() { "${CURL[@]}" -sS "$COS_BASE/$COS_PREFIX/latest/VERSION" 2>/dev/null | tr -d ' \r\n'; }

dl_base() {  # src version
  case "$1" in
    github) printf '%s' "$GH_BASE/download/v$2" ;;
    cn)     printf '%s' "$COS_BASE/$COS_PREFIX/$2" ;;
  esac
}

# 从一个源下载 + 校验到当前目录。源不可达返回非零（调用方换源）；校验不过直接退出。
get_from() {  # github|cn
  local base v
  if [ "$1" = cn ] && [ "$COS_BASE" = "$COS_PLACEHOLDER" ]; then
    say "== 国内镜像尚未配置（可设 SIGNALDESK_COS_BASE），跳过"; return 1
  fi
  if [ -n "$VERSION" ]; then v="$VERSION"
  else
    case "$1" in github) v="$(github_latest)" ;; cn) v="$(cos_latest)" ;; esac || return 1
    [ -n "$v" ] || return 1
  fi
  base="$(dl_base "$1" "$v")"
  ARCHIVE="$STEM-$v.tar.gz"
  say "== $PRODUCT $v: downloading from $base"
  "${CURL[@]}" -o "$ARCHIVE.sha256" "$base/$ARCHIVE.sha256" || { rm -f "$ARCHIVE.sha256"; return 1; }
  "${CURL[@]}" -o "$ARCHIVE" "$base/$ARCHIVE" || { rm -f "$ARCHIVE" "$ARCHIVE.sha256"; return 1; }
  # .sha256 只写文件名，不带路径，所以在任何目录都能校验
  if ! sha256sum -c "$ARCHIVE.sha256" >/dev/null 2>&1; then
    rm -f "$ARCHIVE" "$ARCHIVE.sha256"
    fail "$ARCHIVE failed its sha256 check (corrupted or tampered download); deleted it. Nothing was installed."
  fi
  say "== $ARCHIVE: sha256 OK"
  VERSION="$v"
}
fetch_bundle() {
  local s
  for s in $ORDER; do
    get_from "$s" && return 0
    say "== download from $s failed"
  done
  fail "could not download $PRODUCT (tried: $ORDER). Check the version and the network."
}

if [ "$DOWNLOAD_ONLY" = 1 ]; then
  fetch_bundle
  say "== saved $PWD/$ARCHIVE and $ARCHIVE.sha256"
  say "   on the target host: sha256sum -c $ARCHIVE.sha256 && tar xzf $ARCHIVE && cd $STEM-$VERSION"
  say "   then: docker load -i $STEM-images-$VERSION.tar && cp .env.example .env && docker compose up -d"
  exit 0
fi

cd "$WORK"
fetch_bundle
say "== $PRODUCT $VERSION -> $DIR"

# ── 解压到固定目录 ────────────────────────────────────────────────────────────
# 包里没有 .env 和 data/，已有安装的这两样原样保留（data/license 丢了等于换机，离线证会失效）。
mkdir -p "$DIR"
rm -f "$DIR"/"$STEM"-images-*.tar
tar xzf "$ARCHIVE" -C "$DIR" --strip-components=1
cd "$DIR"

say "== loading images"
docker load -i "$STEM-images-$VERSION.tar" >/dev/null
rm -f "$STEM-images-$VERSION.tar"   # 已进本地镜像库，500 MB 的 tar 不用留

# ── .env：首次安装生成随机密钥；每次把 APP_IMAGE_TAG 钉到本次版本 ────────────
rand() { head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
FIRST_INSTALL=0
if [ ! -f .env ]; then
  FIRST_INSTALL=1
  ADMIN_EMAIL="${SIGNALDESK_ADMIN_EMAIL:-admin@example.com}"
  ADMIN_PASSWORD="$(head -c 18 /dev/urandom | base64 | tr -d '/+=' | head -c 20)"
  {
    grep -v '^\(DB_PASSWORD\|REDIS_PASSWORD\|JWT_SECRET\)=' .env.example
    echo
    echo "# generated by install.sh on $(date -u +%Y-%m-%dT%H:%MZ)"
    echo "DB_PASSWORD=$(rand)"
    echo "REDIS_PASSWORD=$(rand)"
    echo "JWT_SECRET=$(rand)"
    echo "SEED_ON_BOOT=1"
    echo "SEED_ADMIN_EMAIL=$ADMIN_EMAIL"
    echo "SEED_ADMIN_PASSWORD=$ADMIN_PASSWORD"
  } > .env
  chmod 600 .env
fi
if grep -q '^APP_IMAGE_TAG=' .env; then sed -i "s|^APP_IMAGE_TAG=.*|APP_IMAGE_TAG=$VERSION|" .env
else printf 'APP_IMAGE_TAG=%s\n' "$VERSION" >> .env; fi

mkdir -p data uploads backups
chown -R "$APP_UID:$APP_UID" data uploads

say "== starting (docker compose up -d)"
docker compose up -d

# ── 健康门禁 ─────────────────────────────────────────────────────────────────
PORT="$(sed -n 's/^APP_PORT=\(.*\)$/\1/p' .env | tail -1)"; PORT="${PORT:-3000}"
say "== waiting for http://127.0.0.1:$PORT/api/health/ready"
for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null "http://127.0.0.1:$PORT/api/health/ready" 2>/dev/null; then
    # 管理员已建好，关掉开机 seed，免得下次启动再跑一遍
    if [ "$FIRST_INSTALL" = 1 ]; then sed -i 's/^SEED_ON_BOOT=1$/SEED_ON_BOOT=0/' .env; fi
    say ""
    say "== $PRODUCT $VERSION is running: http://$(hostname -I 2>/dev/null | awk '{print $1}'):$PORT"
    if [ "$FIRST_INSTALL" = 1 ]; then
      say "   administrator: $ADMIN_EMAIL"
      say "   password:      $ADMIN_PASSWORD   (shown once; change it after signing in)"
    fi
    say "   install dir:   $DIR  (.env holds the secrets; data/ and uploads/ must be backed up)"
    say "   upgrade later: re-run this installer, or Settings > Online update in the app"
    exit 0
  fi
  sleep 3
done
docker compose logs --tail 40 app >&2 || true
fail "$PRODUCT did not become healthy in 180 s; see the logs above (docker compose logs app)."
