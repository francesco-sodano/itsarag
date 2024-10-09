from contextlib import asynccontextmanager
from typing import List

from dotenv import load_dotenv
from fastapi import Depends, Header, FastAPI, HTTPException
from sqlmodel import Session, select
from starlette.responses import RedirectResponse

from database import load_default_stocks_prices, create_db_and_tables, engine, create_default_user_with_portfolio
from functions import update_stock_prices, buy_stock, sell_stock
from models import Stock, Transaction, Portfolio, User

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    load_default_stocks_prices()
    update_stock_prices()
    create_default_user_with_portfolio()
    yield
    # Clean up the ML models and release the resources
    pass


def get_auth_user(auth_user: str = Header(default="dummy")):
    return auth_user

app = FastAPI(
    title="MockStock API",
    description="A simple API to manage a mock stock trading platform.",
    lifespan=lifespan
    )

@app.get("/api/stocks/", response_model=List[Stock])
def read_stocks():
    with Session(engine) as session:
        stocks = session.exec(select(Stock)).all()
        return stocks

@app.post("/api/refresh_prices/")
def refresh_prices():
    update_stock_prices()

@app.post("/api/buy/")
def buy(stock_symbol: str, quantity: int, auth_user: str = Depends(get_auth_user)):
    buy_stock(auth_user, stock_symbol, quantity)
    return {"message": f"Bought {quantity} shares of {stock_symbol}"}

@app.post("/api/sell/")
def sell(stock_symbol: str, quantity: int, auth_user: str = Depends(get_auth_user)):
    sell_stock(auth_user, stock_symbol, quantity)
    return {"message": f"Sold {quantity} shares of {stock_symbol}"}

@app.get("/api/portfolio/")
def view_portfolio(auth_user: str = Depends(get_auth_user)):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.username == auth_user)).first()
        portfolio = session.exec(select(Portfolio).where(Portfolio.user_id == user.id)).first()
        if portfolio is None:
            raise HTTPException(status_code=404, detail="Portfolio not found")
        transactions = session.exec(select(Transaction).where(Transaction.portfolio_id == portfolio.id)).all()
        portfolio_value = sum(t.quantity * t.purchase_price for t in transactions)
        return {"portfolio": portfolio, "transactions": transactions, "portfolio_value": portfolio_value, "funding_account": user.funding_account}

@app.get("/")
def redirect_to_docs():
    return RedirectResponse(url="/docs")