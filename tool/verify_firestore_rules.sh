#!/bin/sh
# Verifica las reglas de seguridad de Firestore contra el emulador.
#
# Una revisión visual de firestore.rules no sustituye esto: las reglas son el
# único mecanismo que protege el progreso de un estudiante frente a otro, y su
# comportamiento solo se conoce ejecutándolas.
#
# Uso:
#   firebase emulators:start --only firestore --project languages-buildlark
#   sh tool/verify_firestore_rules.sh
#
# El emulador acepta JWT **sin firmar**, que es la forma documentada de probar
# reglas por HTTP sin depender de las bibliotecas de JavaScript.

set -e

PROJ="${FIREBASE_PROJECT:-languages-buildlark}"
HOST="${FIRESTORE_EMULATOR:-localhost:8080}"
BASE="http://$HOST/v1/projects/$PROJ/databases/%28default%29/documents"
BODY='{"fields":{"xp":{"integerValue":"10"}}}'

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

mktoken() {
  user="$1"
  now=$(date +%s)
  header=$(printf '{"alg":"none","typ":"JWT"}' | b64url)
  payload=$(printf '{"iss":"https://securetoken.google.com/%s","aud":"%s","sub":"%s","user_id":"%s","email":"%s@test.com","email_verified":true,"iat":%s,"exp":%s,"firebase":{"identities":{},"sign_in_provider":"password"}}' \
    "$PROJ" "$PROJ" "$user" "$user" "$user" "$now" "$((now + 3600))" | b64url)
  printf '%s.%s.' "$header" "$payload"
}

status() { # method url [token]
  if [ -n "$3" ]; then
    curl -s -o /dev/null -w '%{http_code}' -X "$1" "$2" \
      -H "Authorization: Bearer $3" -H 'Content-Type: application/json' -d "$BODY"
  else
    curl -s -o /dev/null -w '%{http_code}' -X "$1" "$2" \
      -H 'Content-Type: application/json' -d "$BODY"
  fi
}

check() { # descripción esperado real
  if [ "$2" = "$3" ]; then
    printf '  OK   %s (%s)\n' "$1" "$3"
  else
    printf '  FALLA %s: esperaba %s, obtuvo %s\n' "$1" "$2" "$3"
    FAILED=1
  fi
}

T1=$(mktoken u1)
T2=$(mktoken u2)
DOC="$BASE/users/u1/courses/en"
FAILED=0

echo "Reglas de Firestore contra $HOST (proyecto $PROJ)"
check "u1 escribe su propio progreso"        200 "$(status PATCH "$DOC" "$T1")"
check "u1 lee su propio progreso"            200 "$(status GET   "$DOC" "$T1")"
check "u2 NO puede leer el de u1"            403 "$(status GET   "$DOC" "$T2")"
check "u2 NO puede escribir el de u1"        403 "$(status PATCH "$DOC" "$T2")"
check "sin sesión NO puede leer"             403 "$(status GET   "$DOC")"
check "ninguna otra ruta queda abierta"      403 "$(status PATCH "$BASE/admin/secrets" "$T1")"

if [ "$FAILED" = "1" ]; then
  echo "Hay reglas que no se comportan como deben."
  exit 1
fi
echo "Las seis comprobaciones pasan."
