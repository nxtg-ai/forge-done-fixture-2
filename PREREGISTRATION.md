# Pre-registration: does Forge beat a plain review on the DONE-2 case?

Written 2026-10-13T20:35Z. Committed before any run, and checked by forge-pm before the first run (DIRECTIVE-NXTG-20261013-12). No run starts until that check passes. Nothing below changes after the first run.

This is fixture 2. Fixture 1 (https://github.com/nxtg-ai/forge-done-fixture) showed parity: Forge caught its case 6 of 6, and plain Claude 3 of 3, because that defect could be read straight from the code. This case is built so that reading the diff is not enough.

## The case (frozen)

- Repository: https://github.com/nxtg-ai/forge-done-fixture-2, tag `done` = commit `22a37e30e4fe819751f22a98f7e2203bacf97745`.
- Ticket DONE-2: "orders of 10 or more items get 10% off". The commit message and `TICKETS.md` say it is done and that `python3 -m unittest` passes, which it does (7 tests, OK).
- **The defects, two of them, neither visible in the DONE-2 diff alone:**
  1. **The new tests never run.** They are in `tests/pricing/`, which has no `__init__.py`, so `python3 -m unittest` discovery skips them. The run still says 7 tests, OK, the same count as before DONE-2. Run directly, 3 of the 4 new tests fail.
  2. **The 10-item tier never applies.** `load_tiers()` in `shop/pricing.py`, which the diff does not touch, sorts `min_items` as text. "10" sorts before "3" and "5", so the 10% tier is overridden by the 5% tier: `percent_off(10)` returns 5, and `order_total(250, 12)` returns 2850 instead of 2700. With the tiers before DONE-2 (3 and 5), the text sort happened to be correct.
- **Why a plain review may miss it** (stated before any run):
  - The DONE-2 diff is one CSV row, a new test file whose assertions are correct, and a ticket entry.
  - The bug is in unchanged code, and it only shows with the new data.
  - Running the suite prints OK.
  - Catching the case takes either running the new test file directly or computing a discount, or noticing that the test count did not change, or that `tests/pricing/` is not a package.
  - A reviewer who does any of these will catch it. This is a test of whether they do.

## The tool (frozen)

- Forge plugin `nxtg-forge` **v3.11.2**, pinned to the tag (forge-plugin `bad4a97`). It is installed from a clone of that tag as a local marketplace, the same as fixture 1. The `forge` orchestrator binary is not installed.
- Claude Code from the official installer, model alias `sonnet`. Each run records `claude --version`, the resolved model id, `node --version` and `claude plugin list`.
- Neither the fixture nor the plugin changes after the first run.

## Arms (5 runs each; a fresh clone of only the `done` tag per run)

| Arm | Plugin | Prompt, exactly |
|-----|--------|-----------------|
| F1 | nxtg-forge v3.11.2 | `/nxtg-forge:gap-analysis --scope testing` |
| F2 | nxtg-forge v3.11.2 | `/nxtg-forge:crucible-audit` |
| B | none | `Review the most recent commit in this repository (ticket DONE-2, marked done). Is the work done? Report any problems you find.` |

The arms are the same as fixture 1's, with only the ticket id changed, so the two fixtures compare directly.

**Environment:**
- Run with `harness/run-arm.sh <arm> <out> <env-file> harness/arms.env`: one fresh `ubuntu:24.04` `--rm` container per arm, with git, python3, curl and Node 22, as a non-root user.
- The credential is a run-only env file passed with `--env-file`. After the last write, the evidence is checked for its bytes, with a positive control.
- `claude -p <prompt> --model sonnet --permission-mode bypassPermissions --max-budget-usd 5 --output-format stream-json --verbose`.
- The case clone is `git clone --single-branch --no-tags --branch done <repo>`, with `origin` removed.

**Budget:** each arm stops before a run once its spend, as `total_cost_usd` list-price estimates, plus 0.30 would reach its cap: F1 3.00 USD, F2 3.00 USD, B 2.00 USD (`ARM_CAP_USD`). A cap stop is reported as such.

## Scoring (frozen)

Each run is scored on its final `result` text.
- **CAUGHT** if the final answer does either of these:
  - **(a)** says the DONE-2 tests in `tests/pricing/` are not run by `python3 -m unittest` (not discovered or collected; for example, the missing `__init__.py`);
  - **(b)** says the 10-item tier gives the wrong discount: an order of 10 or more items gets 5% (or not 10%), or the tiers are sorted as text and not by number.
- **MISSED** otherwise. Generic advice ("add more tests", "consider edge cases") that names neither (a) nor (b) is a MISS. So is a run that says the work is done.
- **INCOMPLETE** if the run ends with an error subtype. It is counted separately and rerun once, inside the arm's cap; both runs are published.

Each run is also tagged with which of (a) and (b) it named. The scorer quotes the deciding line from the final answer. All raw output is published.

## "Forge beats the baseline" (frozen)

- **Primary: catch rate, F2 against B.**
  - F2 is the primary Forge arm. `/nxtg-forge:crucible-audit` is Forge's test-quality audit: it counts tests collected and checks for dead test infrastructure (its pattern 4), which is what defect 1 is.
  - **Forge beats the baseline if F2's CAUGHT count is at least B's plus 2, out of 5.**
  - Otherwise it does not. That includes a tie, a 1-run edge and a B win.
- **Secondary**, reported but not used for the claim:
  - F1 against B, by the same rule.
  - Repeatability: how many of 5 runs per arm reach the same verdict.
  - Which defects each arm names, (a), (b) or both.
  - List-price cost per CAUGHT run.
- **If F2 does not beat B,** that is a product finding for the Forge build, reported to forge-pm. It is not fixed in copy.

With 5 runs per arm this is a small sample. The rule is a pre-stated threshold, not a significance test.

## Publication

All runs are published as found, whatever the counts, with the result stated at the top of this repository's README.
