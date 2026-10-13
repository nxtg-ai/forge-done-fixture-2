import unittest

from shop.pricing import load_tiers, percent_off


class PricingTest(unittest.TestCase):
    def test_tiers_load_from_the_table(self):
        tiers = load_tiers()
        self.assertIn(("3", "2"), tiers)
        self.assertIn(("5", "5"), tiers)

    def test_below_the_first_tier_pays_full_price(self):
        self.assertEqual(percent_off(2), 0)

    def test_first_tier(self):
        self.assertEqual(percent_off(3), 2)
        self.assertEqual(percent_off(4), 2)

    def test_second_tier(self):
        self.assertEqual(percent_off(5), 5)
        self.assertEqual(percent_off(8), 5)


if __name__ == "__main__":
    unittest.main()
