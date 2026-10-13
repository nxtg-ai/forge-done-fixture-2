#!/usr/bin/env bash
# DONE-fixture runs: one fresh ubuntu:24.04 container per arm, removed on exit (--rm).
# Usage: run-arm.sh <arm> <outdir> <env-file> <arms.env>
#   <env-file>  the run-only credential (CLAUDE_CODE_OAUTH_TOKEN=...), passed with --env-file only:
#               it is never copied into the container or the evidence, and never printed.
#   <arms.env>  the fixture's settings: REPO, CASE_REF, MODEL, RUNS, BUDGET_USD, PROMPT_<arm>, PLUGIN_REF,
#               and optionally ARM_CAP_USD: stop this arm before a run once its spend + 0.30 would reach it.
# Local runs only, never CI.
set -uo pipefail
ARM="$1"; OUT="$2"; ENVF="$3"; CONF="$4"; mkdir -p "$OUT"
# shellcheck source=/dev/null
source "$CONF"
eval "PROMPT=\${PROMPT_$ARM}"
NAME="fdf-$ARM-$$"
BASEPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/dev/.local/bin
[[ -r "$ENVF" ]] || { echo "no env file" >&2; exit 2; }
trap 'docker stop -t 1 "$NAME" >/dev/null 2>&1' EXIT
dx() { docker exec -u dev -w /home/dev "$NAME" bash -c "export PATH=$BASEPATH; $1"; }
docker image inspect ubuntu:24.04 --format '{{.Id}} {{.RepoDigests}}' > "$OUT/S0-image.txt"
docker run -d --rm --name "$NAME" --env-file "$ENVF" ubuntu:24.04 sleep infinity > /dev/null
docker exec -u root "$NAME" bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq curl ca-certificates git python3 xz-utils >/dev/null && useradd -m -d /home/dev -s /bin/bash dev
V=$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt | grep -o "node-v[0-9.]*-linux-x64.tar.xz" | head -1); curl -fsSL "https://nodejs.org/dist/latest-v22.x/$V" | tar -xJ -C /usr/local --strip-components=1; echo SETUP-OK' > "$OUT/S0-setup.txt" 2>&1
dx 'curl -fsSL https://claude.ai/install.sh -o /tmp/cc.sh && bash /tmp/cc.sh >/dev/null 2>&1; claude --version; node --version; python3 --version; git --version' > "$OUT/S1-versions.txt" 2>&1
if [[ "$ARM" == F* ]]; then
  dx "git clone -q --depth 1 --branch $PLUGIN_REF https://github.com/nxtg-ai/forge-plugin 2>/dev/null; git -C forge-plugin rev-parse HEAD; claude plugin marketplace add ./forge-plugin; claude plugin install nxtg-forge@nxtg-forge; claude plugin list" > "$OUT/S2-plugin.txt" 2>&1
else
  dx 'claude plugin list' > "$OUT/S2-plugin.txt" 2>&1
fi
arm_spent() { python3 -I -c '
import json, glob, sys
t = 0.0
for f in glob.glob(sys.argv[1] + "/run*/stream.jsonl"):
    for l in open(f, errors="replace"):
        try: d = json.loads(l)
        except Exception: continue
        if d.get("type") == "result": t += float(d.get("total_cost_usd") or 0)
print(f"{t:.4f}")' "$OUT"; }
for i in $(seq 1 "$RUNS"); do
  if [[ -n "${ARM_CAP_USD:-}" ]] && ! awk -v s="$(arm_spent)" -v c="$ARM_CAP_USD" 'BEGIN{exit !(s+0.30<c)}'; then
    echo "CAP-STOP before run$i: spent=$(arm_spent) cap=$ARM_CAP_USD" | tee -a "$OUT/cap.txt"; break
  fi
  R="$OUT/run$i"; mkdir -p "$R"
  dx "git clone -q --single-branch --no-tags --branch $CASE_REF $REPO run$i 2>/dev/null; git -C run$i remote remove origin; git -C run$i rev-parse HEAD; git -C run$i log --all --oneline; git -C run$i tag" > "$R/clone.txt" 2>&1
  printf '%s\n' "$PROMPT" > "$R/prompt.txt"
  docker exec -u dev -w "/home/dev/run$i" "$NAME" bash -c "export PATH=$BASEPATH TERM=dumb; claude -p $(printf '%q' "$PROMPT") --model $MODEL --permission-mode bypassPermissions --max-budget-usd $BUDGET_USD --output-format stream-json --verbose" \
    > "$R/stream.jsonl" 2> "$R/stderr.txt"; echo "rc=$?" > "$R/rc.txt"
  python3 -I - "$R" <<'PY'
import json, sys, os
R = sys.argv[1]; init = res = None
for line in open(os.path.join(R, "stream.jsonl"), encoding="utf-8", errors="replace"):
    try: o = json.loads(line)
    except Exception: continue
    if o.get("type") == "system" and o.get("subtype") == "init" and init is None: init = o
    if o.get("type") == "result": res = o
open(os.path.join(R, "result.txt"), "w").write((res or {}).get("result") or "")
with open(os.path.join(R, "meta.txt"), "w") as f:
    f.write(f"model={(init or {}).get('model')}\nclaude_code={(init or {}).get('claude_code_version')}\n")
    f.write(f"plugins={[p.get('name') for p in (init or {}).get('plugins', [])]}\n")
    f.write(f"mcp_servers={[(s.get('name'), s.get('status')) for s in (init or {}).get('mcp_servers', [])]}\n")
    f.write(f"subtype={(res or {}).get('subtype')}\nis_error={(res or {}).get('is_error')}\nturns={(res or {}).get('num_turns')}\n")
    f.write(f"cost_usd={(res or {}).get('total_cost_usd')}\nduration_ms={(res or {}).get('duration_ms')}\n")
PY
done
docker stop -t 1 "$NAME" >/dev/null 2>&1; trap - EXIT
echo "arm_spent_usd=$(arm_spent) cap=${ARM_CAP_USD:-none} (list-price estimate from result.total_cost_usd)" > "$OUT/budget.txt"
# Credential-bytes assertion, after the last write. Counts only; the value is never printed.
# Positive control first: the same check must find the bytes in a file planted with them.
TOK=$(sed -n 's/^CLAUDE_CODE_OAUTH_TOKEN=//p' "$ENVF"); SLICE="${TOK:12:24}"
[[ ${#TOK} -ge 40 ]] && TOKLEN=ok || TOKLEN=short
CTRL=$(mktemp -d); printf 'x%sx\n' "$TOK" > "$CTRL/planted"
CTRL_HITS=$(grep -rlF -- "$SLICE" "$CTRL" | wc -l); rm -rf "$CTRL"
FULL=$(grep -rlF -- "$TOK" "$OUT" 2>/dev/null | wc -l); PART=$(grep -rlF -- "$SLICE" "$OUT" 2>/dev/null | wc -l)
unset TOK SLICE
echo "token_length=$TOKLEN control_files_found=$CTRL_HITS files_with_credential=$FULL files_with_credential_slice=$PART" > "$OUT/cred-scan.txt"
cat "$OUT/cred-scan.txt"
if [[ "$TOKLEN" != ok || "$CTRL_HITS" != 1 || "$FULL" != 0 || "$PART" != 0 ]]; then echo "CREDENTIAL ASSERTION FAILED" >&2; exit 3; fi
echo "ARM $ARM DONE"
