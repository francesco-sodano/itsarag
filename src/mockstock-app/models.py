from datetime import datetime
from typing import List, Optional

from sqlalchemy import Column, String
from sqlmodel import Field, SQLModel, Relationship


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(default="dummy", max_length=255, index=True, unique=True)
    funding_account: float = Field(default=100000.0)
    portfolios: List["Portfolio"] = Relationship(back_populates="user")

class Stock(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    symbol: str = Field(default=None, max_length=255, index=True, unique=True)
    name: str
    current_price: float
    historic_prices: List["HistoricPrice"] = Relationship(back_populates="stock")


class HistoricPrice(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    stock_id: int = Field(foreign_key="stock.id")
    price: float
    timestamp: datetime

    stock: Stock = Relationship(back_populates="historic_prices")


class Portfolio(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")

    user: User = Relationship(back_populates="portfolios")
    transactions: List["Transaction"] = Relationship(back_populates="portfolio")


class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    portfolio_id: int = Field(foreign_key="portfolio.id")
    stock_id: int = Field(foreign_key="stock.id")
    quantity: int
    purchase_price: float
    timestamp: datetime

    portfolio: Portfolio = Relationship(back_populates="transactions")
    stock: Stock = Relationship()