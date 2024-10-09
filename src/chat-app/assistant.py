import os
from dotenv import load_dotenv
load_dotenv()

from langchain_openai import AzureChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema import StrOutputParser

class Assistant:
    def __init__(self):
        model = AzureChatOpenAI(
                streaming=True,
                api_version=os.getenv('AZURE_OPENAI_API_VERSION'),
                deployment_name=os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')
                )
        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    "You're a very knowledgeable financial analyst who provides accurate and eloquent answers to financial questions.",
                ),
                ("human", "{question}"),
            ]
        )
        self.runnable = prompt | model | StrOutputParser()
        
    def astream(self, content, config):
        return self.runnable.astream({ "question": content }, config)

    def invoke(self, content):
        return self.runnable.invoke({ "question": content })