#!/bin/bash
# 从 1.0.7 基础包构建 EazyBot-jiangnan mac x64 DMG。
# 用法: ./build-dmg.sh <基础1.0.7.app路径> <输出目录>
# 前置: 基础包需已完成 env 组装（agentscope 1.0.19.post1 + reme_ai 0.3.1.8），
#       且 Contents/Resources/env/bin/EazyBot-jiangnan（venv python 改名副本）已存在。
set -euo pipefail

SRC_APP="${1:?用法: build-dmg.sh <基础.app> <输出目录>}"
OUT_DIR="${2:-$(pwd)/dist}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

APP_NAME="EazyBot-jiangnan.app"
VOLNAME="Install EazyBot-jiangnan-1.0.7-x64"
STAGE="$(mktemp -d)/$APP_NAME"
TMP_DMG="$(mktemp -d)/EazyBot-jiangnan-1.0.7-mac-x64.tmp.dmg"

echo "[1/5] 复制基础包并应用 overlay"
mkdir -p "$STAGE"
ditto "$SRC_APP" "$STAGE"
cp -R "$REPO_ROOT/overlay/Contents/" "$STAGE/Contents/"

echo "[2/5] 编译并安装单进程启动器"
cc -arch x86_64 -O2 -Wall -o "$STAGE/Contents/MacOS/EazyBot" \
  "$REPO_ROOT/launcher/launcher.c"
cp "$STAGE/Contents/Resources/env/bin/EazyBot-jiangnan" \
   "$STAGE/Contents/MacOS/EazyBot-jiangnan"

echo "[3/5] 清理 console 预压缩缓存（保证补丁生效）"
CONSOLE="$STAGE/Contents/Resources/env/lib/python3.11/site-packages/eazybot/console"
rm -f "$CONSOLE/assets/index-BiWh193y.js.br" "$CONSOLE/assets/index-BiWh193y.js.gz"

echo "[4/5] 放入种子数据（首启播种智能体/技能/MCP，凭据零打包）"
mkdir -p "$STAGE/Contents/Resources/seed"
cp -R "$REPO_ROOT/seed/eazybot-data" "$STAGE/Contents/Resources/seed/eazybot-data"

echo "[5/5] 打包 DMG"
mkdir -p "$OUT_DIR"
hdiutil create -size 4g -fs HFS+ -volname "$VOLNAME" "$TMP_DMG" >/dev/null
hdiutil attach "$TMP_DMG" -nobrowse >/dev/null
V="/Volumes/$VOLNAME"
trap 'hdiutil detach "$V" >/dev/null 2>&1 || true' EXIT
ln -s /Applications "$V/Applications"
ditto "$STAGE" "$V/$APP_NAME"
hdiutil detach "$V" >/dev/null
trap - EXIT
hdiutil convert "$TMP_DMG" -format UDZO \
  -o "$OUT_DIR/EazyBot-jiangnan-1.0.7-mac-x64.dmg" >/dev/null

echo "完成: $OUT_DIR/EazyBot-jiangnan-1.0.7-mac-x64.dmg"
