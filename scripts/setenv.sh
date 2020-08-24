#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
echo "Script absolute path is $SCRIPT_DIR"
PROJ_ROOT="$(dirname "$SCRIPT_DIR")"
echo "Project root path is $PROJ_ROOT"

if [ -z "${ANDROID_KEY_STORE_PWD}" ]; then
  echo "ANDROID_KEY_STORE_PWD not found, abort"
  exit 1
else
  echo "ANDROID_KEY_STORE_PWD detected, proceeding..."
fi

if [ -z "${ANDROID_KEY_PWD}" ]; then
  echo "ANDROID_KEY_PWD not found, abort"
  exit 1
else
  echo "ANDROID_KEY_PWD detected, proceeding..."
fi

# Create the keystore for signing the Android app.
rm -f "${PROJ_ROOT}"/android/key.properties
{
  echo "storePassword=${ANDROID_KEY_STORE_PWD}"
  echo "keyPassword=${ANDROID_KEY_PWD}"
  echo "keyAlias=key"
  echo "storeFile=key.jks"
} >>"$PROJ_ROOT"/android/key.properties

echo "${RELEASE_KEYSTORE}" > release.keystore.asc
gpg -d --passphrase "${RELEASE_KEYSTORE_PASSPHRASE}" --batch release.keystore.asc >"${PROJ_ROOT}"/android/app/key.jks


mkdir -p "$PROJ_ROOT"/keys
echo "${RELEASE_SERVICE_ACCOUNT_KEYSTORE}" > service_account.keystore.asc
gpg -d --passphrase "${RELEASE_KEYSTORE_PASSPHRASE}" --batch service_account.keystore.asc >"${PROJ_ROOT}"/keys/android/service_account.json
