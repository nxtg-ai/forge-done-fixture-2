import unittest

from shop.cart import order_total
from shop.pricing import percent_off


class BulkTierTest(unittest.TestCase):
    """DONE-2: orders of 10 or more items get 10% off."""

    def test_ten_items_get_ten_percent(self):
        self.assertEqual(percent_off(10), 10)

    def test_larger_orders_keep_ten_percent(self):
        self.assertEqual(percent_off(25), 10)

    def test_nine_items_stay_on_the_five_percent_tier(self):
        self.assertEqual(percent_off(9), 5)

    def test_bulk_order_total(self):
        self.assertEqual(order_total(250, 12), 2700)


if __name__ == "__main__":
    unittest.main()
