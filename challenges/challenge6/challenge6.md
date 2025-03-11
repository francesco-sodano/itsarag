# Challenge 6: Add Actions

## Introduction

In this challenge we will add an addtional agent to our multi-agent solution: **the Stock Action** agent.

The Stock Action agent will be the first agent in this solution to not retrieve informtion but to perform action on behalf of the user.

the high level logical architecture for the multi-agent solution we are going to create is the following:

<div style="text-align: center;">
  <img src="../../assets/images/itsarag-multiagent-action.png" alt="ITSARAG Multi-Agent with Action">
</div>

To help you with this challenge, we provide a simple application that mimic the behivour of the Bank agency that permit you to buy/sell stocks.

Here you can find the API information: 

### MockStock API Documentation

The MockStock API provides endpoints for a simulated stock trading platform where users can buy and sell stocks with virtual money and track their portfolio.

#### Authentication

API requests require an `auth-user` header. By default, the system uses "dummy" as the username if none is provided.

#### Endpoints

##### Get All Stocks
`GET /api/stocks/`

Returns a list of all available stocks in the system.

**Response:**
```json
[
  {
    "id": 1,
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "current_price": 150.5
  },
  ...
]
```

##### Refresh Stock Prices
`POST /api/refresh_prices/`

Updates all stock prices in the system, either from internet sources or by applying random fluctuations if internet connectivity is unavailable.

**Response:**
No content, returns status code 200 on success.

##### Buy Stock
`POST /api/buy/`

Purchases a specified quantity of a stock for the authenticated user.

**Parameters:**
- `stock_symbol`: Stock ticker symbol (string)
- `quantity`: Number of shares to buy (integer)

**Response:**
```json
{
  "message": "Bought 10 shares of AAPL"
}
```

**Error:**
Returns an error if the user has insufficient funds.

##### Sell Stock
`POST /api/sell/`

Sells a specified quantity of a stock from the authenticated user's portfolio.

**Parameters:**
- `stock_symbol`: Stock ticker symbol (string)
- `quantity`: Number of shares to sell (integer)

**Response:**
```json
{
  "message": "Sold 5 shares of AAPL"
}
```

##### View Portfolio
`GET /api/portfolio/`

Returns the authenticated user's portfolio information, including transactions, total value, and available funds.

**Response:**
```json
{
  "portfolio": {
    "id": 1,
    "user_id": 1
  },
  "transactions": [
    {
      "id": 1,
      "portfolio_id": 1,
      "stock_id": 1,
      "quantity": 10,
      "purchase_price": 150.0,
      "timestamp": "2023-01-01T12:00:00Z"
    },
    ...
  ],
  "portfolio_value": 1500.0,
  "funding_account": 85000.0
}
```

**Error:**
Returns a 404 error if the portfolio is not found.

#### Models

##### Stock
- `id`: Unique identifier
- `symbol`: Unique stock ticker symbol (e.g., "AAPL")
- `name`: Company name
- `current_price`: Current stock price

##### User
- `id`: Unique identifier
- `username`: Unique username
- `funding_account`: Available funds for trading
- `portfolios`: List of user's portfolios

##### Transaction
- `id`: Unique identifier
- `portfolio_id`: Associated portfolio ID
- `stock_id`: Associated stock ID
- `quantity`: Number of shares (positive for purchase, negative for sale)
- `purchase_price`: Price per share at transaction time
- `timestamp`: Date and time of the transaction

##### Portfolio
- `id`: Unique identifier
- `user_id`: Associated user ID

## Challenge

## Step 1. Deploy the final architecture

If you didn't perform the final architecture deployment in Challenge 1 (Step 4), now it's time to do it.

You can deploy the final architecture by executing the following command in the root of your repository:

In the root of your repository execute the following command: 
```bash
azd auth login
azd up
```

While [AZD](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/) provisions your Azure infrastructure and the sample application, let's have a look at the actual code.

## Step 2. Build the Stock Action agent

You will now continue to build on top of what you did in the previous challenge.

You will now create a new agent, the Stock Action agent, that will be responsible for performing actions on the Stock API.
You need also to modify the Assistant agent to be able to send the question to the Stock Action agent if the question is related to the Stock API and consequently also the langgraph workflow.

Be sure that the Stock Action agent is able only to perform actions on the defined stocks.

## Success Criteria

- You have a working Multi-Agent solution that includes the Stock Action agent.
- You are able to provide the answer for the proposed questions to the coach using your solution.

## Resources
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [LangChain Tools](https://python.langchain.com/docs/how_to/#tools)
- [OpenAI Tools](https://python.langchain.com/v0.1/docs/modules/agents/agent_types/openai_tools/)
- [Building a simple Agent with Tools](https://towardsdatascience.com/building-a-simple-agent-with-tools-and-toolkits-in-langchain-77e0f9bd1fa5#:~:text=Let%E2%80%99s%20build%20a%20simple%20agent%20in%20LangChain%20to)
