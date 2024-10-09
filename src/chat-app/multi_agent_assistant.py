import os
from dotenv import load_dotenv
load_dotenv()

from langchain_openai import AzureOpenAIEmbeddings, AzureChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_community.vectorstores import AzureSearch
from typing import Annotated, Sequence
from pydantic import BaseModel, Field
from typing_extensions import TypedDict
from langchain_core.messages import BaseMessage
from langchain_core.runnables import RunnableLambda, RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import PromptTemplate
from langchain_community.retrievers import AzureAISearchRetriever
from langchain_openai import AzureChatOpenAI
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages
from langgraph.prebuilt import tools_condition
from langgraph.graph import StateGraph, END
from urllib.parse import quote_plus 
from sqlalchemy import create_engine
from langchain_community.agent_toolkits.sql.base import create_sql_agent
from langchain_community.agent_toolkits.sql.toolkit import SQLDatabaseToolkit
from langchain_community.utilities import SQLDatabase
from langchain.prompts.chat import ChatPromptTemplate

import pyodbc
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

from its_a_rag import ingestion

class AgentState(TypedDict):
    # The add_messages function defines how an update should be processed
    # Default is to replace. add_messages says "append"
    messages: Annotated[Sequence[BaseMessage], add_messages]

llm = AzureChatOpenAI(api_key = os.getenv("AZURE_OPENAI_API_KEY"),  
                    api_version = "2024-06-01",
                    azure_endpoint =  os.getenv("AZURE_OPENAI_ENDPOINT"),
                    model= os.getenv("AZURE_OPENAI_MODEL"),
                    streaming=True)

def start_agent(state):
    global llm
    start_agent_llm = llm
    prompt = PromptTemplate.from_template("""
    You are an agent that needs analyze the user question. \n
    Question : {input} \n
    if the question is related to stock prices answer with "stock". \n
    if the question is related to information about financial results answer with "rag". \n
    if the question is unclear or you cannot decide answer with "rag". \n
    only answer with one of the word provided.
    Your answer (stock/rag):
    """)
    chain = prompt | start_agent_llm
    response = chain.invoke({"input": state["input"]})
    decision = response.content.strip().lower()
    return {"decision": decision, "input": state["input"]}

def stock_agent(state):
    global llm
    stock_agent_llm = llm
    connection_string = f"Driver={os.getenv('SQL_DRIVER')};Server=tcp:{os.getenv('SQL_SERVER')},1433;Database={os.getenv('SQL_DB')};Uid={os.getenv('SQL_USERNAME')};Pwd={os.getenv('SQL_PWD')};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    quoted_conn_str = quote_plus(connection_string)
    engine = create_engine('mssql+pyodbc:///?odbc_connect={}'.format(quoted_conn_str))
    db = SQLDatabase(engine=engine)
    stock_toolkit = SQLDatabaseToolkit(db=db, llm=stock_agent_llm)
    stock_agent = create_sql_agent(
        toolkit=stock_toolkit,
        llm=stock_agent_llm,
        agent_type="openai-tools",
        agent_name="StockAgent",
        agent_description="Stock Agent",
        agent_version="0.1",
        agent_author="Francesco Sodano",
        #verbose=True,
        agent_executor_kwargs=dict(handle_parsing_errors=True))
    final_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", 
            """
            You are a helpful AI assistant expert in querying SQL Database to find answers to user's question about stock prices. \n
            If you can't find the answer, say 'I am unable to find the answer.'
            """
            ),
            ("user", "{question}\n ai: "),
        ]
    )
    response = stock_agent.invoke(final_prompt.format(question=state["input"]))
    return {"output": response['output'], "input": state["input"]}

def rag_agent(state):
    # Define the LLM
    global llm
    rag_agent_llm = llm
    # Define the index
    retriever_multimodal = AzureAISearchRetriever(
        index_name=os.getenv('AZURE_SEARCH_INDEX'), 
        api_key=os.getenv('AZURE_SEARCH_API_KEY'), 
        service_name=os.getenv('AZURE_SEARCH_ENDPOINT'),
        top_k=5
    )
    # Define the chain
    chain_multimodal_rag = (
    {
        "context": retriever_multimodal | RunnableLambda(ingestion.get_image_description),
        "question": RunnablePassthrough(),
    }
    | RunnableLambda(ingestion.multimodal_prompt)
    | llm
    | StrOutputParser()
)
    response = chain_multimodal_rag.invoke({"input": state["input"]})
    return {"output": response}


class MultiAgentAssistant:
    def __init__(self):
        class AgentState(TypedDict):
            input: str
            output: str
            decision: str

        workflow = StateGraph(AgentState)

        workflow.add_node("start", start_agent)
        workflow.add_node("stock_agent", stock_agent)
        workflow.add_node("rag_agent", rag_agent)
        workflow.add_conditional_edges(
            "start",
            lambda x: x["decision"],
            {
                "stock": "stock_agent",
                "rag": "rag_agent"
            }
        )
        workflow.set_entry_point("start")
        workflow.add_edge("stock_agent", END)
        workflow.add_edge("rag_agent", END)
        self.runnable = workflow.compile()

    def astream(self, content, config):
        return self.runnable.astream({"input": content}, config)

    def invoke(self, content):
        return self.runnable.invoke({"input": content})['output']

