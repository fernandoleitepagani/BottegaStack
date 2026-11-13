#!/usr/bin/env bash
# Small assertions shared by the scenarios' expect scripts. Source this file;
# it defines helpers and runs nothing on its own.

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

# assert <label> <command...>
assert() {
  local label="$1"
  shift
  if "$@"; then
    printf 'ok %s\n' "$label"
  else
    fail "$label"
  fi
}

# assert_eq <label> <expected> <actual>
assert_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    printf 'ok %s\n' "$label"
  else
    fail "$label (want '$want', got '$got')"
  fi
}
