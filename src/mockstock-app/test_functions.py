import unittest
from unittest.mock import patch
from datetime import datetime

from sqlalchemy import delete
from sqlmodel import Session, SQLModel, create_engine, select

from database import create_db_and_tables, engine, load_default_stocks_prices, create_default_user_with_portfolio
from models import Stock, HistoricPrice, User, Portfolio, Transaction
from functions import update_stock_prices, buy_stock, get_price_from_internet, sell_stock


class TestStockFunctions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create an in-memory SQLite database for testing
        create_db_and_tables()
        load_default_stocks_prices()
        create_default_user_with_portfolio()

    def setUp(self):
        pass

    def test_buy_stock(self):
        with Session(engine) as session:
            user = session.exec(select(User)).first()
            stock = session.exec(select(Stock)).first()
            buy_stock(user.username, stock.symbol, 10)

        # Verify that the user's funding account was updated
        # Assert: Check the results
        with Session(engine) as session:
            user = session.exec(select(User)).first()
            self.assertEqual(user.funding_account, 8750.0)

            # Verify that the transaction was recorded
            transactions = session.exec(select(Transaction)).all()
            self.assertEqual(len(transactions), 1)
            self.assertEqual(transactions[0].quantity, 10)
            self.assertEqual(transactions[0].purchase_price, 125.0)
            self.assertIsInstance(transactions[0].timestamp, datetime)


    def test_sell_stock_more_than_owned(self):
        initial_funding = 10000.0
        stock_id = 1
        with Session(engine) as session:
            user = session.exec(select(User)).first()
            initial_funding = user.funding_account
            stock = session.exec(select(Stock).where(Stock.symbol == "MSFT")).first()
            buy_stock(user.username, stock.symbol, 10)  # Buy stock first to sell later

        with Session(engine) as session:
            user = session.exec(select(User)).first()
            stock = session.exec(select(Stock).where(Stock.symbol == "MSFT")).first()
            sell_stock(user.username, stock.symbol, 15)  # Attempt to sell more than owned

        # Verify that the user's funding account was updated correctly
        with Session(engine) as session:
            user = session.exec(select(User)).first()
            self.assertEqual(user.funding_account, initial_funding)  # Should only sell 10 stocks

            # Verify that the transaction was recorded
            stock = session.exec(select(Stock).where(Stock.symbol == "MSFT")).first()
            transactions = session.exec(select(Transaction).where(Transaction.stock_id == stock.id)).all()
            self.assertEqual(2, len(transactions))  # One buy and one sell transaction
            self.assertEqual(transactions[-1].quantity, -10)
            self.assertEqual(transactions[-1].purchase_price, 250.0)
            self.assertIsInstance(transactions[1].timestamp, datetime)
            
    def test_get_price_from_internet_success(self):
        # Mock the history method to return a DataFrame with a specific closing price
        price = get_price_from_internet("AAPL")
        self.assertGreater(price, 150.0)
    
    def test_update_stock_prices_success(self):
        # check how many historic prices are there
        with Session(engine) as session:
            historic_prices = session.exec(select(HistoricPrice)).all()
            self.assertEqual(len(historic_prices), 16)

        update_stock_prices()

        # check how many historic prices are there
        with Session(engine) as session:
            historic_prices = session.exec(select(HistoricPrice)).all()
            self.assertEqual(len(historic_prices), 32)

if __name__ == "__main__":
    unittest.main()