import os

from sqlmodel import SQLModel, Session, select
from sqlmodel import create_engine

from models import User, HistoricPrice, Portfolio

# Get the database URL from the environment variable or default to in-memory SQLite
sqlite_url = os.getenv("MOCKSTOCK_DATABASE_URL", "sqlite:///file::memory:?cache=shared")

engine = create_engine(sqlite_url)

def create_db_and_tables():
    print("Creating database and tables")
    SQLModel.metadata.create_all(engine)

def create_default_user_with_portfolio():
    with Session(engine) as session:
        # Check if the user already exists
        existing_user = session.exec(select(User).where(User.username == "dummy")).first()
        if not existing_user:
            user = User(username="dummy", funding_account=10000.0)
            portfolio = Portfolio(user=user)
            session.add(user)
            session.add(portfolio)
            session.commit()

def load_default_stocks_prices():
    from datetime import datetime
    from sqlmodel import Session, select
    from models import Stock, HistoricPrice
    
    # Define a list of stock data
    stock_data = [
        {"symbol": "AAPL", "name": "Apple Inc.", "current_price": 125.0},
        {"symbol": "GOOGL", "name": "Alphabet Inc.", "current_price": 1750.0},
        {"symbol": "MSFT", "name": "Microsoft Corporation", "current_price": 250.0},
        {"symbol": "AMZN", "name": "Amazon.com Inc.", "current_price": 320.0},
        {"symbol": "INTC", "name": "Intel Corporation", "current_price": 50.0},
        {"symbol": "NVDA", "name": "NVIDIA Corporation", "current_price": 400.0},
        {"symbol": "TSLA", "name": "Tesla Inc.", "current_price": 700.0},
        {"symbol": "V", "name": "Visa Inc.", "current_price": 210.0},
        {"symbol": "JNJ", "name": "Johnson & Johnson", "current_price": 160.0},
        {"symbol": "WMT", "name": "Walmart Inc.", "current_price": 140.0},
        {"symbol": "JPM", "name": "JPMorgan Chase & Co.", "current_price": 150.0},
        {"symbol": "PG", "name": "Procter & Gamble Co.", "current_price": 130.0},
        {"symbol": "DIS", "name": "The Walt Disney Company", "current_price": 180.0},
        {"symbol": "MA", "name": "Mastercard Inc.", "current_price": 350.0},
        {"symbol": "UNH", "name": "UnitedHealth Group Inc.", "current_price": 400.0},
        {"symbol": "GME", "name": "GameStop Corp.", "current_price": 150.0},
    ]
    
    with Session(engine) as session:
        existing_stocks = session.exec(select(Stock)).all()
        if len(existing_stocks) < len(stock_data):
            # Create stock records for missing stocks
            existing_symbols = {stock.symbol for stock in existing_stocks}
            new_stocks = [
                Stock(symbol=data["symbol"], name=data["name"], current_price=data["current_price"])
                for data in stock_data if data["symbol"] not in existing_symbols
            ]
            session.add_all(new_stocks)
            session.commit()
    
            # Record the initial prices as historic prices
            for stock in new_stocks:
                historic_price = HistoricPrice(stock_id=stock.id, price=stock.current_price, timestamp=datetime.now())
                session.add(historic_price)
    
            session.commit()