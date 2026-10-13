"""Volume discount tiers, read from shop/data/tiers.csv."""
import csv
from pathlib import Path

TIERS_CSV = Path(__file__).parent / "data" / "tiers.csv"


def load_tiers(path=TIERS_CSV):
    """Return the tiers as (min_items, percent_off) pairs, smallest tier first."""
    with open(path, newline="") as f:
        rows = [(row["min_items"], row["percent_off"]) for row in csv.DictReader(f)]
    return sorted(rows, key=lambda tier: int(tier[0]))


def percent_off(quantity, tiers=None):
    """Percent off for an order of `quantity` items: the largest tier it reaches, else 0."""
    pct = 0
    for min_items, off in tiers if tiers is not None else load_tiers():
        if quantity >= int(min_items):
            pct = int(off)
    return pct
