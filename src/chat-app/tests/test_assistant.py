import sys
import os
import re
import pytest
from pprint import pformat

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from assistant import Assistant

@pytest.fixture(scope="class")
def assistant():
    return Assistant()

class TestAssistant:
    @pytest.mark.asyncio
    async def test_ceo_of_intel(self, assistant):
        answer = assistant.invoke("Who is the CEO of Nvidia?")
        assert re.match(r".*(Jensen|Jen-Hsun) Huang.*", answer)