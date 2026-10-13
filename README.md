# forge-done-fixture-2

> **This repository is deliberately seeded.** It contains a change that is marked done, whose test run says OK, and which is broken in a way the change's own diff does not show. It is the second, harder case in a pair. It tests whether [Forge](https://github.com/nxtg-ai/forge-plugin), a governance plugin for Claude Code, catches what a plain Claude review misses. [Fixture 1](https://github.com/nxtg-ai/forge-done-fixture) was easy: both caught it.

## Result: Forge does not beat a plain review on this case

The runs were pre-registered in [PREREGISTRATION.md](PREREGISTRATION.md) and checked by forge-pm at `38187c3`, before any run. All runs used `claude-sonnet-5-5` on Claude Code 2.1.296, with Forge plugin v3.11.2 in the Forge arms. There were five fresh runs per arm, on 2026-10-13.

| Arm | What ran | Caught | Named both defects | Cost per catch |
|-----|----------|--------|--------------------|----------------|
| F1 Forge | `/nxtg-forge:gap-analysis --scope testing` | **5 of 5** | 5 of 5 | 0.20 USD |
| F2 Forge (primary) | `/nxtg-forge:crucible-audit` | **5 of 5** | 5 of 5 | 0.20 USD |
| B plain Claude, no plugin | "Review the most recent commit in this repository (ticket DONE-2, marked done). Is the work done? Report any problems you find." | **5 of 5** | 5 of 5 | 0.05 USD |

- **Pre-registered rule:** Forge beats the baseline if F2 catches at least 2 more of 5 than B. **F2 5, B 5: Forge does not beat the baseline.**
- **What every run did, in all three arms:** found that the DONE-2 tests never run (the missing `__init__.py`) and that the 10-item tier gives 5% (the text sort).
- **On this case**, a plain review was as thorough and as repeatable as Forge, at about a quarter of the cost.

**How this case was chosen:** it was selected because a plain review plausibly misses it, and designed knowing what Forge's `crucible-audit` checks (dead test infrastructure is one of its patterns). A Forge win here shows that Forge **can** catch something a plain review misses, not **how often**. The numbers above are those arms' numbers.

Every deciding quote, cost and model id is in [evidence/SCORES.md](evidence/SCORES.md). The raw streams are under `evidence/<arm>/run<n>/`.

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
