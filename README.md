# forge-done-fixture-2

> **This repository is deliberately seeded.** It contains a change that is marked done, whose test run says OK, and which is broken in a way the change's own diff does not show. It is the second, harder case in a pair. It tests whether [Forge](https://github.com/nxtg-ai/forge-plugin), a governance plugin for Claude Code, catches what a plain Claude review misses. [Fixture 1](https://github.com/nxtg-ai/forge-done-fixture) was easy: both caught it.

**Results: pending.** The runs are pre-registered in [PREREGISTRATION.md](PREREGISTRATION.md), committed before any run. forge-pm checks the pre-registration before the first run. Results will be added in `evidence/`, as found.

## The case

A small Python project, `shop`, computes order totals with volume discounts read from `shop/data/tiers.csv`.

| Tag | What it is | `python3 -m unittest` |
|-----|------------|-----------------------|
| `done` | Ticket DONE-2, "orders of 10 or more items get 10% off": one CSV row and 4 tests in `tests/pricing/`, marked **done** in the commit and `TICKETS.md`. | OK, 7 tests |
| `red` | The DONE-2 tests made discoverable, plus a check that the tiers are ordered by size. | **FAILED**, 4 of 12 |
| `green` | The fix: the tiers are sorted by number, not as text. | OK, 12 tests |

**What is wrong at `done`:**
1. `tests/pricing/` has no `__init__.py`, so `python3 -m unittest` never runs the 4 DONE-2 tests. The count stays at 7, the same as before DONE-2, and the run says OK.
2. `load_tiers()`, in code the change did not touch, sorts the tier sizes as text. "10" comes before "3", so the 10% tier is overridden by the 5% tier, and an order of 12 items at 2.50 pays 28.50 instead of 27.00.

## See the red and the green

```bash
git clone https://github.com/nxtg-ai/forge-done-fixture-2 && cd forge-done-fixture-2
git checkout done  && python3 -m unittest      # OK: 7 tests; the DONE-2 tests are not among them
python3 -m unittest tests/pricing/test_bulk_tier.py   # FAILED: 3 of 4
git checkout red   && python3 -m unittest      # FAILED: 4 of 12
git checkout green && python3 -m unittest      # OK: 12 tests
```

## Reproduce the Forge and baseline runs

See [PREREGISTRATION.md](PREREGISTRATION.md) for the arms, prompts, scoring rule and the definition of "Forge beats the baseline". See [REPRODUCE.md](REPRODUCE.md) for the commands, from a fresh container with no NXTG state.

## License

MIT
