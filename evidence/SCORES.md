# Scores

These are scored by the frozen rule in [PREREGISTRATION.md](../PREREGISTRATION.md) (checked by forge-pm at `38187c3` before any run), on each run's final `result` text (`<arm>/run<n>/result.txt`). Quotes are verbatim lines from that file; a line over 220 characters is cut with "…". The full streams are beside them.

- Model: `claude-sonnet-5-5` (the `sonnet` alias). Claude Code 2.1.296.
- Plugin: nxtg-forge 3.11.2 (`bad4a97`) in the Forge arms only.
- Runs: 2026-10-13, 2026-10-13T20:41:28Z to 2026-10-13T20:44:26Z.

| Arm | Run | Verdict | Named | Line naming (a): the tests never run | Line naming (b): the wrong discount | Subtype | Cost (USD) |
|-----|-----|---------|-------|-------------------------------------|-------------------------------------|---------|-----------|
| F1 | 1 | **CAUGHT** | (a) + (b) | The bulk tier ticket DONE-2 is marked done, but the feature doesn't work. The suite reports green only because the new tests never run. | - `load_tiers()` in `shop/pricing.py:11` sorts the CSV values as strings. That puts `"10"` before `"3"` and `"5"`. | success | 0.206 |
| F1 | 2 | **CAUGHT** | (a) + (b) | **CRITICAL 1: The bulk-tier tests never run.** | - `load_tiers()` in `shop/pricing.py:11` sorts the CSV values as strings. | success | 0.199 |
| F1 | 3 | **CAUGHT** | (a) + (b) | The bulk-tier feature (DONE-2) is broken, and the default test run doesn't catch it. `TICKETS.md` marks DONE-2 as done with `python3 -m unittest` passing. That is true, but only because the bulk-tier tests never run. | \\| 2 \\| **Critical** \\| The tests that were skipped fail when run directly. `python3 -m unittest tests/pricing/test_bulk_tier.py` gives 3 failures out of 4. `percent_off(10)`, `percent_off(25)` and `order_total(250, 12)` re… | success | 0.199 |
| F1 | 4 | **CAUGHT** | (a) + (b) | **1. The bulk-tier tests never run by default.** | - `load_tiers` (`shop/pricing.py:11`) sorts the CSV values as strings. The order comes out `('10','10'), ('3','2'), ('5','5')`, because `"10" < "3"` as text. | success | 0.200 |
| F1 | 5 | **CAUGHT** | (a) + (b) | **DONE-2 is marked done, but the bulk tier doesn't work and its tests never run.** Both problems are in the testing scope. | - `load_tiers()` in `shop/pricing.py:11` sorts the CSV values as strings, so the order is `10, 3, 5`. | success | 0.197 |
| F2 | 1 | **CAUGHT** | (a) + (b) | DONE-2 is marked "Done, `python3 -m unittest` passes". It isn't done. The bulk tier doesn't work, and the tests that would show that never run. | 2. **Product bug the dead tests would catch.** `shop/pricing.py:11` sorts the tiers as strings: `[('10','10'), ('3','2'), ('5','5')]`. `percent_off` (`pricing.py:17-19`) keeps the last tier it matches in that order, not… | success | 0.192 |
| F2 | 2 | **CAUGHT** | (a) + (b) | DONE-2 is marked "Done. `python3 -m unittest` passes", but the feature doesn't work. The tests that would show this are never run by the documented command. | 2. **The feature is broken.** `shop/pricing.py:11` sorts `(row["min_items"], row["percent_off"])` as strings. That gives `[('10','10'), ('3','2'), ('5','5')]`, so `"10"` sorts before `"3"`. The loop in `percent_off` keep… | success | 0.201 |
| F2 | 3 | **CAUGHT** | (a) + (b) | DONE-2 is marked **Done** and `python3 -m unittest` passes. In reality the 10% bulk tier does not work, and the tests written for it never run. | 2. **The feature is broken: string sort.** `shop/pricing.py:11` sorts `(min_items, percent_off)` as strings. The result is `[('10','10'), ('3','2'), ('5','5')]`, so `"10"` sorts before `"3"`. `percent_off` (`shop/pricing… | success | 0.210 |
| F2 | 4 | **CAUGHT** | (a) + (b) | DONE-2 is marked "Done. `python3 -m unittest` passes", but the bulk tier doesn't work and its tests never run. | 2. **The feature is broken.** `shop/pricing.py:11` sorts the CSV values as strings. `load_tiers()` returns `[('10','10'), ('3','2'), ('5','5')]`, so the 10 tier comes first. `percent_off` (`pricing.py:17-19`) keeps the l… | success | 0.200 |
| F2 | 5 | **CAUGHT** | (a) + (b) | DONE-2 is marked "Done… `python3 -m unittest` passes", but the feature doesn't work. The tests that would show this never run. | - `percent_off(10)` returns **5**, not 10. `order_total(250, 12)` returns **2850**, not 2700. | success | 0.203 |
| B | 1 | **CAUGHT** | (a) + (b) | **2. The new tests fail, and the default test run never runs them.** | - `load_tiers` sorts the CSV values as strings, not numbers. The order becomes `10, 3, 5` instead of `3, 5, 10`. | success | 0.048 |
| B | 2 | **CAUGHT** | (a) + (b) | **2. The new tests never run under `python3 -m unittest`.** `tests/pricing/` has no `__init__.py`, so discovery skips `tests/pricing/test_bulk_tier.py`. The default run only executes 7 tests and reports OK. Running the f… | **1. The feature doesn't work.** `load_tiers()` in `shop/pricing.py` sorts the CSV values as strings, not numbers. The order comes out as `10, 3, 5`, because `"10"` sorts before `"3"`. `percent_off()` assumes the tiers a… | success | 0.046 |
| B | 3 | **CAUGHT** | (a) + (b) | **The new tests never ran in the default test command.** | **Bug: orders of 10 or more still get 5% off.** | success | 0.056 |
| B | 4 | **CAUGHT** | (a) + (b) | **2. The new tests never run in the default suite.** `tests/pricing/` has no `__init__.py`, so `python3 -m unittest` doesn't discover `test_bulk_tier.py`. It runs only 7 tests (from `tests/test_cart.py` and `tests/test_p… | **1. The feature is broken.** `load_tiers()` in `shop/pricing.py` sorts the CSV rows as strings, so `"10"` sorts before `"3"` and `"5"`. The tiers come back as `[('10','10'), ('3','2'), ('5','5')]`. `percent_off` takes t… | success | 0.055 |
| B | 5 | **CAUGHT** | (a) + (b) | **2. The new tests never run under `python3 -m unittest`.** `tests/pricing/` has no `__init__.py`, so discovery skips it. `python3 -m unittest` runs 7 tests and reports OK, and none of them are the new ones. Running the… | **1. The 10% tier has no effect.** `load_tiers()` in `shop/pricing.py` sorts the tiers as strings, so the order is `"10" < "3" < "5"`. `percent_off()` takes the last tier that matches, so for any quantity of 10 or more t… | success | 0.054 |

## Totals

| Arm | Caught | Named (a) | Named (b) | Repeatability | List-price cost | Cost per catch |
|-----|--------|-----------|-----------|---------------|-----------------|----------------|
| F1 Forge `/nxtg-forge:gap-analysis --scope testing` | **5 of 5** | 5 | 5 | 5 of 5 same verdict | 1.00 USD | 0.200 USD |
| F2 Forge `/nxtg-forge:crucible-audit` (primary) | **5 of 5** | 5 | 5 | 5 of 5 same verdict | 1.01 USD | 0.201 USD |
| B plain Claude, no plugin | **5 of 5** | 5 | 5 | 5 of 5 same verdict | 0.26 USD | 0.052 USD |

## The pre-registered comparison

- **Forge beats the baseline if F2's CAUGHT count ≥ B's + 2.** F2 = 5 and B = 5, so **Forge does not beat the baseline.** F1 against B, by the same rule: does not beat.
- Every run in every arm named both defects. A plain review was as thorough as Forge on this case. It cost about a quarter as much per catch: 0.052 USD against 0.201 USD (F2) and 0.200 USD (F1).
- No run was INCOMPLETE, and no arm reached its cap (F1 1.00 of 3.00 USD, F2 1.01 of 3.00, B 0.26 of 2.00).

## Notes

- **Credential:** a run-only token passed with `--env-file` into `--rm` containers. After the last write, each arm's `cred-scan.txt` shows 0 files with the token or a 24-character slice of it, and a positive control that found 1.
- **Git author line:** in all five baseline runs, the raw `stream.jsonl` contains the fixture commits' public git author line, because the agent ran `git show`. It is also in this repository's history.
- **Trailer, seen by every arm (disclosed in the pre-registration):** one baseline run (B run 4) remarked on the done commit's "Forge Plugin" trailer, calling it noise.
