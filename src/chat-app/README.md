# Chat App

## Building

```shell
cp -r ../../lib/its_a_rag ./
docker build . -t chat-app:latest
```

## Running

```shell
docker run -it --rm -p 8000:8000 --env-file ../../.env --name chat-app chat-app:latest
```

# Chatbot Application

This project is a chatbot application built with Python and Chainlit. It uses Azure OpenAI for natural language processing.

## Prerequisites

- Python 3.11
- Docker
- `pip` for Python package management

## Setup


2. Create a virtual environment and activate it:
    ```sh
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3. Install the required Python packages:
    ```sh
    pip install -r requirements.txt
    ```

4. Create a `.env` file in the root directory. 

To use OpenAI,  add your Azure OpenAI credentials:

    ```env
    AZURE_OPENAI_API_KEY=<your-api-key>
    AZURE_OPENAI_ENDPOINT=<your-endpoint>
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT_VERSION=<your-embedding-deployment-version>
    AZURE_OPENAI_API_VERSION=<your-chat-deployment-version>
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME=<your-embedding-deployment-name>
    AZURE_OPENAI_DEPLOYMENT_NAME=<your-chat-deployment-name>
    ```

If you want to use Phi-3, use following env variables (values just examples)
```env
   AZURE_MAAS_ENDPOINT=https://Phi-3-medium-128k-instruct-XXXXXX.REGION.models.ai.azure.com
   AZURE_MAAS_KEY=my-api-key-from-ai-azure-com
```
   
or just copy the .env.template as .env file and fill in the values.

## Running the Application

To run the application locally, use the following command:
```sh
chainlit run app.py
```
