#!/bin/sh
# Build do lado Ubuntu Touch: compila o app Linux do Flutter e monta, em
# ${BUILD_DIR}/click, tudo que o Clickable copia para a raiz do pacote .click.
#
# Chamado pelo `build:` de ubuntu_touch/clickable.yaml, de dentro do contêiner
# do Clickable, que é quem exporta ROOT, BUILD_DIR, ARCH e ARCH_TRIPLET (ver
# https://clickable-ut.dev/en/latest/project-config.html#placeholders).
# FLUTTER_VERSION vem do `env_vars` do mesmo arquivo.
set -eu

for var in ROOT BUILD_DIR ARCH FLUTTER_VERSION; do
  eval "value=\${$var:-}"
  if [ -z "$value" ]; then
    echo "erro: $var não está definida; rode este script pelo \`clickable build\`." >&2
    exit 1
  fi
done

# O embedder Linux do Flutter existe para x64, arm64 e riscv64 — não para
# armhf. A OpenStore aceita as três arquiteturas, mas o click de armhf não tem
# como ser gerado.
case "$ARCH" in
  amd64) target_platform=linux-x64;   flutter_out=x64 ;;
  arm64) target_platform=linux-arm64; flutter_out=arm64 ;;
  *)
    echo "erro: arquitetura $ARCH sem suporte no desktop Linux do Flutter (use amd64 ou arm64)." >&2
    exit 1
    ;;
esac

host_arch=$(uname -m)
sdk_dir="$ROOT/.flutter-sdk/$FLUTTER_VERSION-$host_arch"
flutter="$sdk_dir/bin/flutter"

# O SDK precisa ficar dentro do projeto para entrar no bind mount do
# contêiner. O diretório é oculto de propósito: o analisador do Dart pula
# diretórios que começam com ponto, e um SDK inteiro dentro da árvore faria o
# `flutter analyze` do CI encontrar dezenas de milhares de apontamentos que não
# são do app.
if [ ! -x "$flutter" ]; then
  echo "==> baixando o SDK do Flutter $FLUTTER_VERSION ($host_arch)"
  rm -rf "$sdk_dir"
  mkdir -p "$(dirname "$sdk_dir")"

  if [ "$host_arch" = "x86_64" ]; then
    # O tarball oficial só existe para x64; é bem mais leve que o clone.
    archive="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz"
    tmp="$(mktemp -d)"
    curl -fsSL "$archive" -o "$tmp/flutter.tar.xz"
    tar -xf "$tmp/flutter.tar.xz" -C "$tmp"
    mv "$tmp/flutter" "$sdk_dir"
    rm -rf "$tmp"
  else
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$sdk_dir"
  fi
fi

# O contêiner roda com um usuário diferente do dono dos arquivos baixados, e
# sem isso o git (que o flutter chama para se identificar) recusa o diretório.
git config --global --add safe.directory "$sdk_dir" || true

echo "==> compilando o app Linux para $target_platform"
"$flutter" config --no-analytics --enable-linux-desktop
"$flutter" pub get
# Sem --target-platform o Flutter compila para o host. Com ela, quando o host
# é x64 e o alvo é arm64, o próprio Flutter passa o --target e o sysroot para
# o clang (ver o bloco FLUTTER_TARGET_PLATFORM_SYSROOT em linux/CMakeLists.txt).
"$flutter" build linux --release --target-platform "$target_platform"

bundle="$ROOT/build/linux/$flutter_out/release/bundle"
if [ ! -x "$bundle/cotacao_direta" ]; then
  echo "erro: o build não produziu $bundle/cotacao_direta." >&2
  exit 1
fi

echo "==> montando a raiz do click em $BUILD_DIR/click"
staging="$BUILD_DIR/click"
rm -rf "$staging"
mkdir -p "$staging"

# O bundle inteiro vai para um subdiretório: o executável procura as próprias
# bibliotecas em $ORIGIN/lib, e deixá-lo na raiz colidiria com o lib/ que o
# Clickable usa para as bibliotecas do sistema (lib/${ARCH_TRIPLET}).
cp -a "$bundle" "$staging/bundle"

# A versão do pacote sai do pubspec.yaml, sem o build number (que é do
# Android). Uma versão nova é obrigatória a cada envio para a OpenStore.
version=$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' "$ROOT/pubspec.yaml" | head -n 1)
if [ -z "$version" ]; then
  echo "erro: não consegui ler a versão do pubspec.yaml." >&2
  exit 1
fi
# Os placeholders $ENV{...} que sobram no manifesto são resolvidos pelo próprio
# Clickable na hora de empacotar.
sed "s/@VERSION@/$version/" "$ROOT/ubuntu_touch/manifest.json.in" > "$staging/manifest.json"

# O ícone da loja e do drawer é a mesma arte do ícone do Android e da PWA (ver
# a seção "Ícone do app" do README). É o `Icon=` do .desktop.
cp "$ROOT/assets/launcher/icon.png" "$staging/icon.png"

# O GTK3 lê alguns ajustes (org.gtk.Settings.*) via GSettings e aborta se o
# esquema não estiver compilado em lugar nenhum. O rootfs do Ubuntu Touch não
# tem os esquemas do GTK, então o cache do contêiner de build viaja junto — o
# formato é independente de arquitetura entre alvos little-endian.
schemas=/usr/share/glib-2.0/schemas/gschemas.compiled
if [ -f "$schemas" ]; then
  mkdir -p "$staging/glib-2.0/schemas"
  cp "$schemas" "$staging/glib-2.0/schemas/"
else
  echo "aviso: $schemas não existe no contêiner; o app pode reclamar de esquema do GSettings faltando." >&2
fi

echo "==> pronto: $staging"
