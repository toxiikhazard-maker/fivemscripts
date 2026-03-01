#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <fxserver_root> <mysql_connection_string> [server_name] [max_clients]"
  echo "Env overrides: QB_CORE_REF, OXMYSQL_REF, OX_LIB_REF, OX_INVENTORY_REF"
  exit 1
fi

FX_ROOT="$1"
MYSQL_CONN="$2"
SERVER_NAME="${3:-ZRP Extraction PvE}"
MAX_CLIENTS="${4:-32}"

QB_CORE_REF="${QB_CORE_REF:-main}"
OXMYSQL_REF="${OXMYSQL_REF:-main}"
OX_LIB_REF="${OX_LIB_REF:-master}"
OX_INVENTORY_REF="${OX_INVENTORY_REF:-main}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "$FX_ROOT/resources/[zrp]" "$FX_ROOT/resources/[core]" "$FX_ROOT/resources/[ox]"

# Copy ZRP modules + SQL
cp -r "$REPO_ROOT/resources/[zrp]/." "$FX_ROOT/resources/[zrp]/"
cp "$REPO_ROOT/sql/zrp_schema.sql" "$FX_ROOT/zrp_schema.sql"

# Clone dependencies (full bootstrap)
if ! command -v git >/dev/null 2>&1; then
  echo "[ZRP] git is required for full bootstrap dependency download."
  exit 1
fi

git clone --depth 1 --branch "$QB_CORE_REF" https://github.com/qbcore-framework/qb-core "$FX_ROOT/resources/[core]/qb-core"
git clone --depth 1 --branch "$OXMYSQL_REF" https://github.com/overextended/oxmysql "$FX_ROOT/resources/[ox]/oxmysql"
git clone --depth 1 --branch "$OX_LIB_REF" https://github.com/overextended/ox_lib "$FX_ROOT/resources/[ox]/ox_lib"
git clone --depth 1 --branch "$OX_INVENTORY_REF" https://github.com/overextended/ox_inventory "$FX_ROOT/resources/[ox]/ox_inventory"

CFG_SRC="$REPO_ROOT/template/fxserver/server.cfg.template"
CFG_DST="$FX_ROOT/server.cfg"

sed \
  -e "s|{{SERVER_NAME}}|$SERVER_NAME|g" \
  -e "s|{{MAX_CLIENTS}}|$MAX_CLIENTS|g" \
  -e "s|{{STEAM_WEB_API_KEY}}||g" \
  -e "s|{{LICENSE_KEY}}|change_me|g" \
  -e "s|{{MYSQL_CONNECTION}}|$MYSQL_CONN|g" \
  "$CFG_SRC" > "$CFG_DST"

echo "[ZRP] Full bootstrap complete at: $FX_ROOT"
echo "[ZRP] Dependencies installed: qb-core, oxmysql, ox_lib, ox_inventory"
echo "[ZRP] Import SQL with: source $FX_ROOT/zrp_schema.sql"
echo "[ZRP] Edit server.cfg license/admin/icon/endpoints before first start."
