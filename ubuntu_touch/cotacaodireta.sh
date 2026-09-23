#!/bin/sh
# Lançador do app dentro do click. É ele que o Exec do .desktop chama.
set -eu

# O Lomiri exporta APP_DIR com a raiz do pacote instalado; fora dele (um
# `clickable desktop`, por exemplo) o diretório do próprio script serve.
app_dir="${APP_DIR:-$(cd "$(dirname "$0")" && pwd)}"

# Não há servidor X no Ubuntu Touch: o compositor é o Mir, falando Wayland. Sem
# isso o GDK tentaria o backend X11 primeiro e o app não subiria.
export GDK_BACKEND=wayland

# O GTK3 lê ajustes em org.gtk.Settings.* pelo GSettings, e o rootfs do sistema
# não tem esses esquemas: os compilados viajam no click (ver ubuntu_touch/build.sh).
if [ -f "$app_dir/glib-2.0/schemas/gschemas.compiled" ]; then
  export GSETTINGS_SCHEMA_DIR="$app_dir/glib-2.0/schemas"
fi

# O executável do Flutter acha as próprias bibliotecas por RPATH ($ORIGIN/lib);
# o que está aqui é a pilha do GTK3 que o click carrega, em lib/<triplet>. O
# sistema já costuma colocá-la no LD_LIBRARY_PATH, mas repetir não custa e
# cobre o caso de rodar o binário fora do lançador do Lomiri.
arch_triplet=$(ls "$app_dir/lib" 2>/dev/null | grep -- '-linux-gnu' | head -n 1 || true)
if [ -n "$arch_triplet" ]; then
  export LD_LIBRARY_PATH="$app_dir/lib/$arch_triplet${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

# O sqflite_common_ffi resolve getDatabasesPath() como
# `.dart_tool/sqflite_common_ffi/databases` *relativo ao diretório atual* (ver
# lib/util/database_platform_io.dart). O diretório do click é somente leitura,
# então o processo precisa começar na área de dados do app — que é justamente
# onde o AppArmor deixa escrever.
#
# Essa área não é o $XDG_DATA_HOME inteiro, e sim o subdiretório com o nome do
# pacote (~/.local/share/cotacaodireta.hhldiniz): fora dele o perfil de
# confinamento nega a escrita. O nome sai do APP_ID que o Lomiri exporta
# (<pacote>_<hook>_<versão>); fora dele vale o `name` do manifest.json.
app_id="${APP_ID:-cotacaodireta.hhldiniz}"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/${app_id%%_*}"
mkdir -p "$data_dir"
cd "$data_dir"

exec "$app_dir/bundle/cotacao_direta" "$@"
