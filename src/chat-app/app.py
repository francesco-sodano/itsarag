import sys, os
from langchain.schema.runnable.config import RunnableConfig
from typing import cast

import chainlit as cl

from typing import cast

# Add the its_a_rag module to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../lib')))

from assistant import Assistant

@cl.set_starters
async def set_starters():
    return [
        cl.Starter(
            label="Google revenue 2000",
            message="What are the revenues of GOOGLE in the year 2000?",
            ),
        cl.Starter(
            label="Revenue and operating margins",
            message="What are the revenues and the operative margins of ALPHABET Inc. in 2022 and how it compares with the previous year?",
            ),
        cl.Starter(
            label="FY23 highlights",
            message="Can you give me the Fiscal Year 2023 Highlights for APPLE, MICROSOFT, NVIDIA and GOOGLE?",
            ),
        cl.Starter(
            label="Stocks on 23/07/2024",
            message="What was the price of APPLE, NVIDIA and MICROSOFT stock in 23/07/2024?",
            )
        ]

@cl.on_chat_start
async def on_chat_start():
    cl.user_session.set("assistant", Assistant())

@cl.on_message
async def on_message(message: cl.Message):
    assistant = cast(Assistant, cl.user_session.get("assistant"))  # type: Assistant

    msg = cl.Message(content="")

    async for chunk in assistant.astream(
        message.content,
        config=RunnableConfig(callbacks=[cl.LangchainCallbackHandler()]),
    ):
        await msg.stream_token(chunk)

    await msg.send()
