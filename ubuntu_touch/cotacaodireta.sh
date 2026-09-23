#!/bin/sh
# Lançador do app dentro do click. É ele que o Exec do .desktop chama.
set -eu

# O Lomiri exporta APP_DIR com a raiz do pacote instalado; fora dele (um
# `clickable desktop`, por exemplo) o diretório do próprio script serve.
app_dir="${APP_DIR:-$(cd "$(dirname "$0")" && pwd)}"

# Não há servidor X no Ubuntu Touch: o compositor é o Mir, falando Wayland. Sem
# isso o GDK tentaria o backend X11 primeiro e o app não subiria.
export GDK_BACKEND=wayland

# O Lomiri informa a densidade da tela pelo GRID_UNIT_PX (8 px equivalem a 1x;
# num celular costuma ficar entre 16 e 24). O GTK3 não lê essa variável, só o
# GDK_SCALE, e é do fator de escala do GTK que o embedder do Flutter tira o
# devicePixelRatio: sem isso o app seria desenhado em 1x, minúsculo. O
# GDK_SCALE só aceita inteiros, então a sobra vai para o GDK_DPI_SCALE, que
# ajusta o tamanho do texto (com 18 px, por exemplo, fica escala 2 e texto
# 1.125x). Quem já definiu as duas por conta própria é respeitado.
if [ -n "${GRID_UNIT_PX:-}" ] && [ "$GRID_UNIT_PX" -gt 0 ] 2>/dev/null; then
  scale=$((GRID_UNIT_PX / 8))
  [ "$scale" -ge 1 ] || scale=1
  export GDK_SCALE="${GDK_SCALE:-$scale}"
  # Conta em milésimos, só com aritmética do shell: o confinamento não garante
  # acesso a awk/bc.
  dpi=$((GRID_UNIT_PX * 1000 / (8 * GDK_SCALE)))
  export GDK_DPI_SCALE="${GDK_DPI_SCALE:-$((dpi / 1000)).$(printf '%03d' $((dpi % 1000)))}"
fi

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
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$data_dir"
cd "$data_dir"

exec "$app_dir/bundle/cotacao_direta" "$@"
