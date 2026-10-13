# shop

Order totals for a small online shop, with volume discounts read from a tier table.

```bash
python3 -m unittest -v
```

Python 3.10 or newer, standard library only.

- `shop/data/tiers.csv`: the discount tiers. An order gets the discount of the largest tier whose `min_items` it reaches.
- `shop/pricing.py`: loads the tiers and picks the discount.
- `shop/cart.py`: computes order totals in integer cents.
