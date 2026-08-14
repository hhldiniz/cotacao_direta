#!/usr/bin/env bash
#
# Gera um certificado auto assinado para assinar o APK de release e grava as
# credenciais em android/key.properties, que é o arquivo lido por
# android/app/build.gradle. Nem a keystore nem o key.properties entram no
# repositório (ver .gitignore).
#
# Uso:
#   tool/generate_keystore.sh
#
# Dá para ajustar o resultado por variáveis de ambiente:
#   KEYSTORE_FILE      nome do arquivo, relativo a android/ (padrão: release.keystore)
#   KEY_ALIAS          apelido da chave dentro da keystore (padrão: cotacao_direta)
#   KEYSTORE_PASSWORD  senha da keystore e da chave (padrão: uma senha aleatória)
#   VALIDITY_DAYS      validade do certificado em dias (padrão: 10000, ~27 anos)
#   KEY_DNAME          o titular do certificado, no formato do keytool
#   FORCE              se "1", sobrescreve uma keystore que já exista

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
android_dir="$repo_root/android"

keystore_file=${KEYSTORE_FILE:-release.keystore}
key_alias=${KEY_ALIAS:-cotacao_direta}
validity_days=${VALIDITY_DAYS:-10000}
key_dname=${KEY_DNAME:-"CN=Cotacao Direta, OU=Desenvolvimento, O=Cotacao Direta, C=BR"}
keystore_path="$android_dir/$keystore_file"
properties_path="$android_dir/key.properties"

if [ -e "$keystore_path" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "Já existe uma keystore em $keystore_path." >&2
  echo "Apague o arquivo ou rode de novo com FORCE=1 para sobrescrever." >&2
  echo "Atenção: trocar a chave impede atualizar um app já instalado com a antiga." >&2
  exit 1
fi

keystore_password=${KEYSTORE_PASSWORD:-}
generated_password=0
if [ -z "$keystore_password" ]; then
  # Sem senha informada, uma aleatória serve: ela fica guardada no
  # key.properties, que nunca sai da máquina.
  # cut lê a entrada inteira, ao contrário de `head -c`, que fecharia o cano
  # no meio e derrubaria o pipefail.
  keystore_password=$(head -c 48 /dev/urandom | base64 | LC_ALL=C tr -dc 'A-Za-z0-9' | cut -c1-32)
  generated_password=1
fi

rm -f "$keystore_path"
keytool -genkeypair \
  -keystore "$keystore_path" \
  -storetype PKCS12 \
  -alias "$key_alias" \
  -keyalg RSA \
  -keysize 4096 \
  -validity "$validity_days" \
  -storepass "$keystore_password" \
  -keypass "$keystore_password" \
  -dname "$key_dname"

# O keytool cria o arquivo com permissão de leitura para todo mundo; a chave
# privada e a senha ao lado dela merecem coisa melhor.
umask 077
cat > "$properties_path" <<PROPERTIES
# Gerado por tool/generate_keystore.sh. Não versionar: contém a senha da chave.
storeFile=$keystore_file
storePassword=$keystore_password
keyAlias=$key_alias
keyPassword=$keystore_password
PROPERTIES
chmod 600 "$properties_path" "$keystore_path"

echo
echo "Keystore criada em  $keystore_path"
echo "Credenciais em      $properties_path"
if [ "$generated_password" = "1" ]; then
  echo "A senha foi sorteada e está no key.properties."
fi
echo
echo "Para assinar também no CI, cadastre estes secrets no repositório"
echo "(Settings > Secrets and variables > Actions):"
echo "  ANDROID_KEYSTORE_BASE64    saída de: base64 -w0 $keystore_path"
echo "  ANDROID_KEYSTORE_PASSWORD  a senha da keystore"
echo "  ANDROID_KEY_ALIAS          $key_alias"
echo "  ANDROID_KEY_PASSWORD       a senha da chave (a mesma, aqui)"
