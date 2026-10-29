#!/usr/bin/env bash
# verify.sh - Validate the Free Meal Planning Kit
# Checks HTML structure and required credit/license strings.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

FAIL=0

echo "==> Checking HTML files for well-formed structure"
for html in *.html; do
  python3 - "$html" <<'PY'
import sys
from html.parser import HTMLParser

class Checker(HTMLParser):
    def __init__(self, name):
        super().__init__()
        self.name = name
        self.stack = []
        self.void = {"area","base","br","col","embed","hr","img","input","link","meta","param","source","track","wbr"}
        self.errors = []
    def handle_starttag(self, tag, attrs):
        if tag not in self.void:
            self.stack.append(tag)
    def handle_endtag(self, tag):
        if tag in self.void:
            return
        if self.stack and self.stack[-1] == tag:
            self.stack.pop()
        else:
            top = self.stack[-1] if self.stack else None
            self.errors.append(f"unexpected close </{tag}>, stack top={top}")
    def finish(self):
        for tag in reversed(self.stack):
            self.errors.append(f"unclosed <{tag}>")

with open(sys.argv[1], encoding="utf-8") as f:
    c = Checker(sys.argv[1])
    c.feed(f.read())
    c.finish()
if c.errors:
    print(f"  FAIL {sys.argv[1]}")
    for e in c.errors:
        print(f"    {e}")
    sys.exit(1)
else:
    print(f"  OK   {sys.argv[1]}")
PY
  if [ $? -ne 0 ]; then FAIL=1; fi
done

echo "==> Checking required credit and license strings"
check_string() {
  local path="$1" needle="$2"
  if grep -qF "$needle" "$path"; then
    echo "  OK   $path contains '$needle'"
  else
    echo "  FAIL $path missing '$needle'"
    FAIL=1
  fi
}
check_string LICENSE "Copyright (c) 2026 Asdale Dynamics, LLC"
check_string README.md "Asdale Dynamics, LLC"

echo "==> Checking for forbidden files"
if [ -d .github/workflows ]; then
  echo "  FAIL .github/workflows exists (must not be added)"
  FAIL=1
else
  echo "  OK   no .github/workflows"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "==> VERIFICATION FAILED"
  exit 1
fi
echo "==> VERIFICATION PASSED"
