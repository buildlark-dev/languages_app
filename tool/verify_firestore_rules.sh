#!/bin/sh
# Verifies the Firestore security rules against the emulator.
#
# Reading firestore.rules is no substitute for this: the rules are the only mechanism
# protecting one student's progress from another, and their behaviour is only known by
# running them.
#
# Usage:
#   firebase emulators:start --only firestore --project languages-buildlark
#   sh tool/verify_firestore_rules.sh
#
# The emulator accepts **unsigned** JWTs, which is the documented way to test rules over
# HTTP without depending on the JavaScript libraries.

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

check() { # description expected actual
  if [ "$2" = "$3" ]; then
    printf '  OK    %s (%s)\n' "$1" "$3"
  else
    printf '  FAIL  %s: expected %s, got %s\n' "$1" "$2" "$3"
    FAILED=1
  fi
}

T1=$(mktoken u1)
T2=$(mktoken u2)
DOC="$BASE/users/u1/courses/en"
FAILED=0

echo "Firestore rules against $HOST (project $PROJ)"
check "u1 writes its own progress"           200 "$(status PATCH "$DOC" "$T1")"
check "u1 reads its own progress"            200 "$(status GET   "$DOC" "$T1")"
check "u2 can NOT read u1's"                 403 "$(status GET   "$DOC" "$T2")"
check "u2 can NOT write u1's"                403 "$(status PATCH "$DOC" "$T2")"
check "signed out can NOT read"              403 "$(status GET   "$DOC")"
check "no other path is left open"           403 "$(status PATCH "$BASE/admin/secrets" "$T1")"

if [ "$FAILED" = "1" ]; then
  echo "Some rules do not behave as they must."
  exit 1
fi
echo "All six checks pass."
