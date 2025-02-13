#-----------------------------------------------------------------------------------------------------------
# IT'S A RAG - Hackathon
# Name: itsarag_ingestion.py
# Description: Support functions and Classes for Multimodal Ingestion System. 
# Version: 2025-02-03
# Author: Francesco Sodano
# Reference: https://github.com/monuminu/AOAI_Samples
#-----------------------------------------------------------------------------------------------------------

from __future__ import annotations
import re
import json
from typing import Any, List
from langchain_text_splitters.base import TextSplitter
from langchain_community.vectorstores import AzureSearch
from langchain_openai import AzureOpenAIEmbeddings
from langchain.text_splitter import MarkdownHeaderTextSplitter
from langchain.schema import Document
from langchain_core.messages import HumanMessage, SystemMessage
from langchain.prompts.chat import ChatPromptTemplate, HumanMessagePromptTemplate, SystemMessagePromptTemplate
from azure.search.documents.indexes.models import SearchableField, SearchField, SearchFieldDataType, SimpleField

AZURE_OPENAI_SYSTEM_MESSAGE = ("You are an assistant for question-answering tasks. "
                               "Use the context provided with the question to answer. "
                               "If you have figures, try to extract information from them even it it is not explicitly text. "
                               "If the answer is not in the context, just say I don't know. "
                               "Keep the answer concise."
                               )

#########################################################
# Create the multimodal vector store
# Args:
#   - index_name: name of the index
#   - azure_openai_api_key: azure openai api key
#   - azure_openai_endpoint: azure openai endpoint
#   - azure_openai_api_version: azure openai api version
#   - azure_openai_embedding_deployment: azure openai embedding deployment
#   - azure_search_endpoint: azure search endpoint
#   - azure_search_api_key: azure search api key
# Returns:
#   - AzureSearch object, 
#   - AzureOpenAIEmbeddings object
#########################################################
def create_multimodal_vector_store(index_name: str, azure_openai_api_key: str, azure_openai_endpoint: str, azure_openai_api_version: str, azure_openai_embedding_deployment: str, azure_search_endpoint: str, azure_search_api_key: str) -> AzureSearch:
    # Create the embedding client
    aoai_embeddings = AzureOpenAIEmbeddings(
    api_key= azure_openai_api_key,
    azure_deployment=azure_openai_embedding_deployment,
    openai_api_version=azure_openai_api_version,
    azure_endpoint = azure_openai_endpoint
    )
    
    # Create Additional Fields for the Azure Search Index    
    embedding_function = aoai_embeddings.embed_query
    fields = [
        SimpleField(
            name="id",
            type=SearchFieldDataType.String,
            key=True,
            filterable=True,
        ),
        SearchableField(
            name="content",
            type=SearchFieldDataType.String,
            searchable=True,
        ),
        SearchField(
            name="content_vector",
            type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
            searchable=True,
            vector_search_dimensions=len(embedding_function("Text")),
            vector_search_profile_name="myHnswProfile",
        ),
        SearchableField(
            name="metadata",
            type=SearchFieldDataType.String,
            searchable=False,
        ),
        # Additional field to store the title
        SearchableField(
            name="header",
            type=SearchFieldDataType.String,
            searchable=True,
        ),
        # Additional field for filtering on document source
        SimpleField(
            name="image",
            type=SearchFieldDataType.String,
            filterable=False,
            searchable=False,
        ),
    ]
    
    # if the index does not exist it will be automatically created.
    vector_store_multi_modal: AzureSearch = AzureSearch(
    azure_search_endpoint= azure_search_endpoint,
    azure_search_key= azure_search_api_key,
    index_name=index_name,
    embedding_function=embedding_function,
    fields=fields,
    )
    
    return vector_store_multi_modal, aoai_embeddings

#########################################################
# Find the indices of the figures in the text
# Args:
#   - text: text to search for the figures
# Returns:
#   - list of indices of the figures
#########################################################
def find_figure_indices(text):
    pattern = r'!\[\]\(figures/(\d+)\)'
    matches = re.findall(pattern, text)
    indices = [int(match) for match in matches]
    return indices


#########################################################
# Get the text from the documents related to images coming from the retriver
# Args:
#   - docs: list of documents
# Returns:
#   - dictionary containing the images and the texts
#########################################################
def get_image_description(docs: List[Document]) -> dict:
    images_data_urls = []
    texts = []
    for doc in docs:
        if doc.metadata['image']:
            print()
            images_data_urls.append(doc.metadata['image'])
        else:
            texts.append(doc.page_content)
    return {"images": images_data_urls, "texts": texts}


#########################################################
# Generate the multimodal prompt including system message, text, table and image
# Args:
#   - data_dict: dictionary containing the system message, context, question
# Returns:
#   - list of messages
#########################################################
def multimodal_prompt(data_dict) -> List:
    system_message = AZURE_OPENAI_SYSTEM_MESSAGE
    formatted_texts = "\n".join(data_dict["context"]["texts"])
    messages = []
    # Adding the text for analysis
    text_message = {
        "type": "text",
        "text": ( f"{system_message}"
            f"User-provided question: {data_dict['question']}\n\n"
            "Text and / or tables:\n"
            f"{formatted_texts}"
        ),
    }
    messages.append(text_message)
    # Adding image(s) to the messages if present
    if data_dict["context"]["images"]:
        for image in data_dict["context"]["images"]:
            image_message = {
                "type": "image_url",
                "image_url": {"url": f"{image}"},
            }
            messages.append(image_message)
    return [HumanMessage(content=messages)]


class CustomCharacterTextSplitter(TextSplitter):
    """Splitting text that looks at characters."""

    def __init__(
        self, separator: str = "\n\n", is_separator_regex: bool = False, **kwargs: Any
    ) -> None:
        super().__init__(**kwargs)
        self._separator = separator
        self._is_separator_regex = is_separator_regex

    def split_text(self, text: str) -> List[str]:
        separator = (
            self._separator if self._is_separator_regex else re.escape(self._separator)
        )
        splits = re.split(separator, text, flags=re.DOTALL) 
        splits = [part for part in splits if part.strip()]
        return splits

#########################################################
# Split the text on the headers and the figures
# Args:
#   - docs: list of documents
#   - pdf_file_name: name of the pdf file
# Returns:
#   - list of documents
#########################################################
def advanced_text_splitter(docs: List[Document], pdf_file_name: str) -> List[Document]:
    # Define the headers to split on
    headers_to_split_on = [
    ("#", "Header 1"),
    ("##", "Header 2"),
    ("###", "Header 3"),
    ("####", "Header 4"),
    ("#####", "Header 5"),
    ("######", "Header 6"),
    ("#######", "Header 7"),
    ("########", "Header 8"),
    ]
    # Use the markdownHeader Spliter from langchain
    text_splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
    docs_string = docs[0].page_content
    docs_result = text_splitter.split_text(docs_string)
    # Split the text on the figure tags
    text_splitter = CustomCharacterTextSplitter(separator=r'(<figure>.*?</figure>)', is_separator_regex=True)
    child_docs  = text_splitter.split_documents(docs_result)
    # Extract the image metadata
    image_metadata = docs[-1].metadata['images']
    lst_docs = []
    # For each child document,
    for doc in child_docs:
        # Find all the figures
        figure_indices = find_figure_indices(doc.page_content)
        if figure_indices:
            for figure_indice in figure_indices:
                # get the image metadata
                image = image_metadata[figure_indice]
                # Create a new document with the image metadata
                doc_result = Document(page_content = doc.page_content, metadata={"header": json.dumps(doc.metadata), "source": pdf_file_name, "image": image})
                # Append the document to the list
                lst_docs.append(doc_result)
        # If there are no figures
        else:
            # Create a new document with no image metadata
            doc_result = Document(page_content = doc.page_content, metadata={"header": json.dumps(doc.metadata), "source": pdf_file_name, "image": None})
            # Append the document to the list
            lst_docs.append(doc_result)
    # Return the list of documents
    return lst_docs
