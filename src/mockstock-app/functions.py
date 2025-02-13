from datetime import datetime

from sqlalchemy import Engine
from sqlmodel import Session, select
import random  # Add this line to import the random module

from models import HistoricPrice, Stock, User, Transaction, Portfolio
from database import engine
import yfinance as yf

def buy_stock(username: str, stock_ticker: str, quantity: int):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.username == username)).first()
        stock = session.exec(select(Stock).where(Stock.symbol == stock_ticker)).first()
        # Ensure the user has enough funds
        total_cost = stock.current_price * quantity
        if user.funding_account >= total_cost:
            user.funding_account -= total_cost

            # Record the transaction
            transaction = Transaction(
                portfolio_id=user.portfolios[0].id,  # Assuming the user has one portfolio
                stock_id=stock.id,
                quantity=quantity,
                purchase_price=stock.current_price,
                timestamp=datetime.now()
            )
            session.add(transaction)
            session.commit()
            return quantity
        else:
            raise ValueError("Insufficient funds to purchase stock.")


def sell_stock(username: str, stock_ticker: str, quantity: int):
    with Session(engine) as session:
        # Find the user's portfolio
        user = session.exec(select(User).where(User.username == username)).first()
        stock = session.exec(select(Stock).where(Stock.symbol == stock_ticker)).first()
        portfolio = session.exec(select(Portfolio).where(Portfolio.user_id == user.id)).first()

        # Calculate total shares owned of this stock
        total_owned = sum(t.quantity for t in portfolio.transactions if t.stock_id == stock.id)
        # quantity to sell should be whatever is less: total_owned or quantity
        quantity_to_sell = min(total_owned, quantity)
        # Calculate the amount to credit to the user's account
        total_sale_amount = stock.current_price * quantity_to_sell
        user.funding_account += total_sale_amount

        # Record the sale by creating a negative transaction
        transaction = Transaction(
            portfolio_id=portfolio.id,
            stock_id=stock.id,
            quantity=-quantity_to_sell,
            purchase_price=stock.current_price,
            timestamp=datetime.now()
        )
        session.add(transaction)
        session.add(user)
        session.commit()
        print(f"Sold {quantity_to_sell} shares of {stock.symbol} at ${stock.current_price} each.")
        return quantity_to_sell


def update_stock_prices() -> None:
    with Session(engine) as session:
        stocks = session.exec(select(Stock)).all()
        for stock in stocks:
            try:
                # Attempt to get the price from the internet (you'd use an actual API here)
                new_price = get_price_from_internet(stock.symbol)  # Placeholder function
            except Exception:
                # If the internet is not reachable, randomly adjust the price by +/- 5%
                new_price = stock.current_price * (1 + random.uniform(-0.05, 0.05))

            stock.current_price = new_price
            
            # Record the historic price
            historic_price = HistoricPrice(stock_id=stock.id, price=new_price, timestamp=datetime.now())
            session.add(historic_price)
        
        session.commit()

def get_price_from_internet(symbol: str) -> int:
    stock = yf.Ticker(symbol)
    price = stock.history(period="1d")["Close"].iloc[-1]
    return int(price)
