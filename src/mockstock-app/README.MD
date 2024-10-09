# Mock Stock API Application

This project is a mock stock API application that provides stock data and allows users to buy and sell stocks. The application is built using Python and Flask.

## Prerequisites

- Python 3.11
- Docker
- `pip` for Python package management

## Setup

1. Clone the repository:
    ```sh
    git clone <repository-url>
    cd <repository-directory>
    ```

2. Create a virtual environment and activate it:
    ```sh
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3. Install the required Python packages:
    ```sh
    pip install -r requirements.txt
    ```

## Running the Application

To run the application locally, use the following command:
```sh
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Docker

### Building the Docker Image

To build the Docker image, run the following script:
```sh
docker build -t mockstock-app .
```

## Run docker

To run the Docker container, use the following command:
```sh
./run-docker.sh
```