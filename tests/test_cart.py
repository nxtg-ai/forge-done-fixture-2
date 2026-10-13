import unittest

from shop.cart import order_total


class OrderTotalTest(unittest.TestCase):
    def test_small_order_pays_full_price(self):
        self.assertEqual(order_total(250, 2), 500)

    def test_tiered_order(self):
        self.assertEqual(order_total(250, 6), 1425)

    def test_negative_quantity_is_rejected(self):
        with self.assertRaises(ValueError):
            order_total(250, -1)


if __name__ == "__main__":
    unittest.main()
