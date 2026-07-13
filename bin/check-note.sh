#!/usr/bin/env bash
# Backstop scan before a note goes public. Catches the obvious; you are
# responsible for the rest. See SANITIZING.md.
#
#   bin/check-note.sh notes/some-note.md
#   bin/check-note.sh              # scans every note
#
# A noisy gate is a gate you learn to ignore, so false positives are treated
# as bugs here, not as caution.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

if [ "$#" -gt 0 ]; then
  targets=("$@")
else
  mapfile -t targets < <(find notes -name '*.md' ! -name '_*')
fi
[ ${#targets[@]} -eq 0 ] && { echo "no notes to check"; exit 0; }

fail=0

# flag <grep-flags> <pattern> <why>
flag() {
  local flags="$1" pattern="$2" why="$3" hits
  hits=$(grep -rn $flags "$pattern" "${targets[@]}" 2>/dev/null) || return 0
  echo "✗ $why"
  echo "$hits" | cut -c1-140 | sed 's/^/    /'
  echo
  fail=1
}

# ── Credentials. Case-sensitive: these have fixed casing, and -i invents ghosts.
flag -E  'xox[baprs]-[A-Za-z0-9-]{10,}'                     "Slack token"
flag -E  'sk-(ant-)?[A-Za-z0-9_-]{20,}'                     "API key (OpenAI / Anthropic shape)"
flag -E  'AKIA[0-9A-Z]{16}'                                 "AWS access key"
flag -E  'gh[pousr]_[A-Za-z0-9]{20,}'                       "GitHub token"
flag -E  '\-\-\-\-\-BEGIN [A-Z ]*PRIVATE KEY'               "private key"
flag -iE '(postgres|postgresql|mysql|redis|amqp|mongodb)://[^[:space:]]*:[^[:space:]@]+@' "connection string with a password"
flag -iE '(secret|password|passwd|api[_-]?key|auth[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}' "hardcoded secret"

# ── My own machine. Not hypothetical: I shipped my laptop path in boorails 2.0.0.
flag -E  '/Users/[A-Za-z0-9._-]+/'                          "absolute local path"
flag -E  '/home/[A-Za-z0-9._-]+/'                           "absolute local path"

# ── The business. None of these belong in a note about agents.
flag -iE '\b(coba|cobapay|opensop|ddqpro|influapp|icalia)\b' "internal project or company name"
flag -iE '\b(chargeback|remittance|underwriting)\b'          "money-path vocabulary — is this a business fact rather than an agent lesson?"

# ── People and infrastructure. Slack IDs are UPPERCASE — do NOT use -i here,
#    or D-plus-letters matches ordinary words like "differently".
flag -E  '\b[UCDGW][0-9A-Z]{8,}\b'                          "Slack user/channel ID"
flag -E  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'   "email address (allowed: example.com — check the hit)"
flag -E  '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'                  "IP address"
flag -iE '\b[a-z0-9-]+\.(internal|local|fly\.dev)\b'        "internal hostname"
flag -iE '\b[a-z0-9-]+\.ts\.net\b'                          "tailnet hostname"

if [ "$fail" -eq 0 ]; then
  echo "✓ clean — now read it back as a competitor before you publish. See SANITIZING.md."
else
  echo "Fix these, or reconstruct the snippet in a neutral domain. Never scrub — rebuild."
  exit 1
fi
