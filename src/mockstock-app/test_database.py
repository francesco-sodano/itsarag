import unittest
from datetime import datetime

from sqlmodel import Session, SQLModel, create_engine, select

from database import load_default_stocks_prices, create_db_and_tables, engine
from models import Stock, HistoricPrice


class TestLoadDefaultStocksPrices(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create an in-memory SQLite database for testing
        create_db_and_tables()

    def setUp(self):
        # Clear the database before each test, not requires, it's in memory
        pass

    def test_load_default_stocks_prices(self):
        # Call the function to load default stock prices
        load_default_stocks_prices()

        # Verify that the stocks were added
        with Session(engine) as session:
            stocks = session.exec(select(Stock)).all()
            self.assertEqual(len(stocks), 16)
            self.assertEqual(stocks[0].symbol, "AAPL")
            self.assertEqual(stocks[1].symbol, "GOOGL")
            self.assertEqual(stocks[2].symbol, "MSFT")

            # Verify that historic prices were recorded
            historic_prices = session.exec(select(HistoricPrice)).all()
            self.assertEqual(len(historic_prices), 16)
            for historic_price in historic_prices:
                self.assertIsInstance(historic_price.timestamp, datetime)

if __name__ == "__main__":
    unittest.main()
