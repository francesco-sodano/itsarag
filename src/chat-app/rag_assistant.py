import os
from dotenv import load_dotenv
load_dotenv()

from langchain_openai import AzureOpenAIEmbeddings, AzureChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_community.vectorstores import AzureSearch

class RagAssistant:
    def __init__(self):
        embeddings = AzureOpenAIEmbeddings(
            azure_deployment = os.getenv("AZURE_OPENAI_EMBEDDING"),
            openai_api_version = os.getenv("AZURE_OPENAI_API_VERSION"),
            azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
            api_key = os.getenv("AZURE_OPENAI_API_KEY")
        )
        vector_store= AzureSearch (
            azure_search_endpoint=os.getenv("AZURE_SEARCH_ENDPOINT"),
            azure_search_key=os.getenv("AZURE_SEARCH_API_KEY"),
            index_name=os.getenv("AZURE_SEARCH_INDEX"),
            embedding_function=embeddings.embed_query,
            # Configure max retries for the Azure client
            additional_search_client_options={"retry_total": 4},
        )
        retriever = vector_store.as_retriever(
            search_type="similarity_score_threshold", 
            search_kwargs={"score_threshold": 0.5}
        )
        llm = AzureChatOpenAI(
            azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            temperature=0,
            max_retries=2
        )

        def format_docs(docs):
            return "\n\n".join(doc.page_content for doc in docs)

        # Use the ChatPromptTemplate to define the prompt that will be sent to the model (Human) remember to include the question and the context
        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are an assistant for question-answering tasks. Use the following pieces of retrieved context to answer the question. If you don't know the answer, just say that you don't know. Use three sentences maximum and keep the answer concise. "),
            ("user", "Question: {question}"),
            ("system", "Context: {context} Answer:"),
            ]
        )

        # Define the Chain to get the answer
        self.runnable = (
            {'context': retriever | format_docs, 'question': RunnablePassthrough() }
            | prompt
            | llm
            | StrOutputParser()
        )

    def astream(self, content, config):
        return self.runnable.astream(content, config)

    def invoke(self, content):
        return self.runnable.invoke(content)