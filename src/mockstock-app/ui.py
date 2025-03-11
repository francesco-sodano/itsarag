# Streamlit UI setup
import requests
import streamlit as st
import pandas as pd
import plotly.express as px

def run_streamlit_ui():
    st.title("Stock Portfolio Management")

    # Refresh Stock Prices
    st.subheader("Stock List")
    if st.button("Refresh Stock Prices"):
        response = requests.post("http://127.0.0.1:8000/api/refresh_prices/", headers={"Content-Type": "application/json"})
        if response.status_code == 200:
            st.success("Stock prices refreshed successfully")
        else:
            st.error("Failed to refresh stock prices")

    # Display Stocks
    response = requests.get("http://127.0.0.1:8000/api/stocks/")
    if response.status_code == 200:
        stocks = response.json()
        for stock in stocks:
            st.write(f"Stock: {stock['symbol']} - {stock['name']} | Price: ${stock['current_price']:.2f}")
    else:
        st.error("Failed to load stock list")

    # User Selection
    st.subheader("Select User")
    response = requests.get("http://127.0.0.1:8000/api/portfolio/")
    users = ["dummy", "user1", "user2"]  # Replace with a call to your API to fetch actual users
    selected_user = st.selectbox("Choose a user", users)

    # Display Portfolio
    if selected_user:
        headers = {"auth-user": selected_user, "Content-Type": "application/json"}
        response = requests.get("http://127.0.0.1:8000/api/portfolio/", headers=headers)
        if response.status_code == 200:
            portfolio_data = response.json()
            portfolio = portfolio_data["portfolio"]
            transactions = portfolio_data["transactions"]
            funding_account = portfolio_data["funding_account"]
            st.subheader(f"{selected_user}'s Portfolio")
            st.write(f"Total Funds: ${funding_account:.2f}")
            st.write("Transactions:")
            for transaction in transactions:
                st.write(
                    f"Stock: {transaction['stock_symbol']}, Quantity: {transaction['quantity']}, Purchase Price: ${transaction['purchase_price']:.2f}")

            # Portfolio Visualization
            st.subheader("Portfolio Visualization")
            df = pd.DataFrame(transactions)
            if not df.empty:
                df['Total Value'] = df['quantity'] * df['purchase_price']
                fig = px.pie(df, values='Total Value', names='stock_symbol', title='Portfolio Distribution')
                st.plotly_chart(fig)
            else:
                st.write("No transactions to display.")

            # Buy Stocks
            st.subheader("Buy Stocks")
            with st.form(key='buy_form'):
                stock_symbol = st.selectbox("Select Stock", [stock['symbol'] for stock in stocks])
                quantity = st.number_input("Quantity", min_value=1)
                submit_button = st.form_submit_button(label='Buy')
                if submit_button:
                    buy_response = requests.post("http://127.0.0.1:8000/api/buy/", headers=headers, data={"stock_symbol": stock_symbol, "quantity": quantity})
                    if buy_response.status_code == 200:
                        st.success("Stock bought successfully")
                    else:
                        st.error("Failed to buy stock: " + buy_response.text)

            # Sell Stocks
            st.subheader("Sell Stocks")
            with st.form(key='sell_form'):
                stock_symbol = st.selectbox("Select Stock to Sell", [stock['symbol'] for stock in stocks])
                quantity = st.number_input("Quantity to Sell", min_value=1)
                submit_button = st.form_submit_button(label='Sell')
                if submit_button:
                    sell_response = requests.post("http://127.0.0.1:8000/api/sell/", headers=headers, json={"stock_symbol": stock_symbol, "quantity": quantity})
                    if sell_response.status_code == 200:
                        st.success("Stock sold successfully")
                    else:
                        st.error("Failed to sell stock")
        else:
            st.error("Failed to load portfolio")


if __name__ == "__main__":
    run_streamlit_ui()