#!/bin/sh
# detect-asan.sh: detect if a binary is instrumented with AddressSanitizer
# and print which symbol or library caused detection.

BIN=${1:-./sshd}
[ -x "$BIN" ] || { echo "no such executable: $BIN" >&2; exit 2; }

ASAN_SYMS='__asan_init|__asan_version_mismatch_check|__asan_report_|__asan_handle_no_return'

found=0

# Helper: print if matches
check_symbols() {
  tool=$1
  shift
  if command -v "$tool" >/dev/null 2>&1; then
    matches=$($tool "$@" 2>/dev/null | grep -E "$ASAN_SYMS")
    if [ -n "$matches" ]; then
      echo "ASan: detected in $BIN"
      echo "Matched via $tool:"
      echo "$matches"
      exit 0
    fi
  fi
}

# 1) nm
check_symbols nm -an "$BIN"

# 2) readelf
check_symbols readelf -s "$BIN"

# 3) objdump
check_symbols objdump -t "$BIN"

# 4) ldd (look for ASan runtime lib)
if command -v ldd >/dev/null 2>&1; then
  libs=$(ldd "$BIN" 2>/dev/null | grep 'libclang_rt\.asan')
  if [ -n "$libs" ]; then
    echo "ASan: detected in $BIN"
    echo "Matched via ldd: $libs"
    exit 0
  fi
fi

# 5) strings fallback
if command -v strings >/dev/null 2>&1; then
  matches=$(strings -a "$BIN" 2>/dev/null | grep -E 'AddressSanitizer|asan_runtime')
  if [ -n "$matches" ]; then
    echo "ASan: detected in $BIN"
    echo "Matched via strings:"
    echo "$matches" | head -n 5   # show first few hits
    exit 0
  fi
fi

echo "ASan: not detected in $BIN"
exit 1

