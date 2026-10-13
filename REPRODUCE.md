# Reproduce the runs

Everything below runs from a fresh machine with no NXTG state. You need Docker and a Claude account that can run Claude Code (`claude login`, or an API key in `ANTHROPIC_API_KEY`). The runs use model `sonnet` at a budget cap of 5 USD each, five runs per arm.

The run commands use `--permission-mode bypassPermissions`, so run them in a throwaway container, not on your own machine.

## 1. A clean container

```bash
docker run -it --rm ubuntu:24.04 bash
# inside the container, as root:
apt-get update && apt-get install -y curl ca-certificates git python3 xz-utils
V=$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt | grep -o "node-v[0-9.]*-linux-x64.tar.xz" | head -1)
curl -fsSL "https://nodejs.org/dist/latest-v22.x/$V" | tar -xJ -C /usr/local --strip-components=1
useradd -m dev && su - dev
# as dev:
curl -fsSL https://claude.ai/install.sh | bash && export PATH="$HOME/.local/bin:$PATH"
claude login            # or: export ANTHROPIC_API_KEY=...
```

Node 22 is what Forge's health tools need. The baseline arm does not need Node, but the runs here had it in every arm so the machines were the same.

## 2. The Forge plugin, pinned to v3.11.2 (Forge arms only)

```bash
git clone --depth 1 --branch v3.11.2 https://github.com/nxtg-ai/forge-plugin
claude plugin marketplace add ./forge-plugin
claude plugin install nxtg-forge@nxtg-forge
claude plugin list      # nxtg-forge@nxtg-forge, Version: 3.11.2
```

For the baseline arm, skip this step, so `claude plugin list` shows no plugins.

## 3. A clone of the case that cannot see the answer

```bash
git clone --single-branch --no-tags --branch done https://github.com/nxtg-ai/forge-done-fixture-2 case
git -C case remote remove origin
git -C case log --all --oneline   # exactly 2 commits; the red, green and evidence commits are not reachable
cd case
```

## 4. One run

```bash
# F1 (Forge)
claude -p '/nxtg-forge:gap-analysis --scope testing' --model sonnet --permission-mode bypassPermissions --max-budget-usd 5 --output-format stream-json --verbose > stream.jsonl
# F2 (Forge)
claude -p '/nxtg-forge:crucible-audit' --model sonnet --permission-mode bypassPermissions --max-budget-usd 5 --output-format stream-json --verbose > stream.jsonl
# B (no plugin)
claude -p 'Review the most recent commit in this repository (ticket DONE-2, marked done). Is the work done? Report any problems you find.' --model sonnet --permission-mode bypassPermissions --max-budget-usd 5 --output-format stream-json --verbose > stream.jsonl
```

The final answer is the `result` field of the last line: `tail -1 stream.jsonl | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"])'`. Score it with the rule in [PREREGISTRATION.md](PREREGISTRATION.md). Use a fresh clone (step 3) for each run.

## The harness

**Use [harness/run-arm.sh](harness/run-arm.sh) for any new run:** `ARM_CAP_USD=$(sed -n 's/^CAP_F1=//p' harness/caps.env) harness/run-arm.sh F1 <out-dir> <env-file> harness/arms.env` (and the same for F2 and B, with their caps).
- `<env-file>` holds one line, `CLAUDE_CODE_OAUTH_TOKEN=...`. It is passed with `docker run --env-file` into a `--rm` container: never copied into the container, never written to the evidence, never printed.
- After the last write, the harness checks that no evidence file holds the token, in full or as a 24-character slice. It prints counts only, and first proves the check can find planted bytes.
- Run it locally only, never in CI.
