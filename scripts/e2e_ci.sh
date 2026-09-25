#!/usr/bin/env bash
# E2E CI entry — satu-satunya skrip E2E yang dijalankan lewat alur ini.
# Setara `npm run test:e2e:ci` (headless); repo ini Flutter tanpa
# package.json, jadi tidak ada npm script — CI memanggil file ini.
# Dijalankan di dalam android-emulator-runner (emulator sudah headless).
# Retry 3x di sini (hemat: tanpa action retry tambahan).
set -u

ATTEMPTS=3
n=1
while [ "$n" -le "$ATTEMPTS" ]; do
  echo "E2E attempt $n/$ATTEMPTS"
  if flutter test integration_test --reporter github; then
    echo "E2E passed on attempt $n"
    exit 0
  fi
  n=$((n + 1))
  sleep 10
done
echo "E2E failed after $ATTEMPTS attempts"
exit 1
