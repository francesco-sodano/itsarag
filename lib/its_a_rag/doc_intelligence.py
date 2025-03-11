#-----------------------------------------------------------------------------------------------------------
# IT'S A RAG - Hackathon
# Name: itsarag_doc_intelligence.py
# Description: Costumized Langchain Azure AI Document Loader for multimodal content. 
# Version: 2025-02-03
# Author: Francesco Sodano
# Reference: https://github.com/monuminu/AOAI_Samples
#-----------------------------------------------------------------------------------------------------------

import logging
from typing import Any, Iterator, List, Optional
import os
import re
from langchain_core.documents import Document
from langchain_community.document_loaders.base import BaseLoader
from langchain_community.document_loaders.base import BaseBlobParser
from langchain_community.document_loaders.blob_loaders import Blob
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.ai.documentintelligence.models import DocumentAnalysisFeature, AnalyzeDocumentRequest
from azure.ai.documentintelligence.models import DocumentContentFormat
from azure.core.credentials import AzureKeyCredential
from PIL import Image
import pymupdf
import mimetypes
import base64
from mimetypes import guess_type
from openai import AzureOpenAI
from urllib.parse import urlparse

MAX_TOKENS = 2000

SYSTEM_CONTEXT = "You are a helpful assistant that describe images in in vivid, precise details. Focus on the graphs, charts, tables, and any flat images, providing clear descriptions of the data they represent. Specify the type of graphs (e.g., bar, line, pie), their axes, colors used, and any notable trends or patterns. Mention the key figures, values, and labels. For each chart, describe how data points change over time or across categories, pointing out any significant peaks, dips, or anomalies. If there are legends, footnotes, or annotations, detail how they contribute to understanding the data."

IMAGE_STORE_FOLDER = "ingestion/images"

logger = logging.getLogger(__name__)

# Function to encode a local image into data URL 
def local_image_to_data_url(image_path):
    # Guess the MIME type of the image based on the file extension
    mime_type, _ = guess_type(image_path)
    if mime_type is None:
        mime_type = 'application/octet-stream'  # Default MIME type if none is found

    # Read and encode the image file
    with open(image_path, "rb") as image_file:
        base64_encoded_data = base64.b64encode(image_file.read()).decode('utf-8')

    # Construct the data URL
    return f"data:{mime_type};base64,{base64_encoded_data}"

####################################################################
# Crop an image from a TIFF file
# Args:
#    - image_path (str): Path to the image file.
#    - page_number (int): The page number of the image to crop (for TIFF format).
#    - bounding_box (tuple): A tuple of (left, upper, right, lower) coordinates for the bounding box.
# Returns:
#    - cropped_image (PIL.Image.Image): The cropped image.
###################################################################

def crop_image_from_image(image_path, page_number, bounding_box):
    with Image.open(image_path) as img:
        if img.format == "TIFF":
            # Open the TIFF image
            img.seek(page_number)
            img = img.copy()
            
        # The bounding box is expected to be in the format (left, upper, right, lower).
        cropped_image = img.crop(bounding_box)
        return cropped_image


###################################################################
# Crop an image from a PDF page
# Args:
#    - pdf_path (str): Path to the PDF file.
#    - page_number (int): The page number to crop from (0-indexed).
#    - bounding_box (tuple): A tuple of (x0, y0, x1, y1) coordinates for the bounding box.
# Returns:
#    - cropped_image (PIL.Image.Image): The cropped image.
###################################################################

def crop_image_from_pdf_page(pdf_path, page_number, bounding_box):
    doc = pymupdf.open(pdf_path)
    page = doc.load_page(page_number)
    
    # Cropping the page. The rect requires the coordinates in the format (x0, y0, x1, y1).
    bbx = [x * 72 for x in bounding_box]
    rect = pymupdf.Rect(bbx)
    pix = page.get_pixmap(matrix=pymupdf.Matrix(300/72, 300/72), clip=rect)
    
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    
    doc.close()

    return img


###################################################################
# Crop an image from a file (calling the appropriate function based on the file type).
# Args:
#    - file_path (str): The path to the file.
#    - page_number (int): The page number (for PDF and TIFF files, 0-indexed).
#    - bounding_box (tuple): The bounding box coordinates in the format (x0, y0, x1, y1).
# Returns:
#    - A PIL Image of the cropped area.
###################################################################

def crop_image_from_file(file_path, page_number, bounding_box):
    mime_type = mimetypes.guess_type(file_path)[0]
    if mime_type == "application/pdf":
        return crop_image_from_pdf_page(file_path, page_number, bounding_box)
    else:
        return crop_image_from_image(file_path, page_number, bounding_box)


###################################################################
# Generate a description for an image using the GPT-4 family model
# Args:
#    - api_base (str): The base URL of the API.
#    - api_key (str): The API key for authentication.
#    - deployment_name (str): The name of the deployment.
#    - api_version (str): The version of the API.
#    - image_path (str): The path to the image file.
#    - caption (str): The caption for the image.
# Returns:
#    - img_description (str): The generated description for the image.
###################################################################

def understand_image_with_gptv(image_path, caption):
    client = AzureOpenAI(
        api_key=os.getenv('AZURE_OPENAI_API_KEY'),  
        api_version=os.getenv('AZURE_OPENAI_API_VERSION'),
        base_url=f"{os.getenv('AZURE_OPENAI_ENDPOINT')}/openai/deployments/{os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')}"
    )
    data_url = local_image_to_data_url(image_path)
    response = client.chat.completions.create(
                model=os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME'),
                messages=[
                    { "role": "system", "content": SYSTEM_CONTEXT },
                    { "role": "user", "content": [  
                        { 
                            "type": "text", 
                            "text": f"Describe this image (note: it has image caption: {caption}):" if caption else "Describe this image:"
                        },
                        { 
                            "type": "image_url",
                            "image_url": {
                                "url": data_url
                            }
                        }
                    ] } 
                ],
                max_tokens=MAX_TOKENS
            )
    img_description = response.choices[0].message.content
    return img_description, data_url


###################################################################
# Add figure description to the markdown content
# Args:
#  - md_content (str): The original Markdown content.
#  - img_description (str): The new description for the image.
#  - idx (int): The index of the figure.
# Returns:
#  - new_md_content (str): The updated Markdown content.
###################################################################

def update_figure_description(md_content, img_description, idx):
    print(f"Updating figure description {idx}...")
    # The substring you're looking for
    start_substring = "<figure>"
    end_substring = "</figure>"
    new_string = f"\n![](figures/{idx})\n{img_description}\n"
    new_md_content = md_content
    # Find the start and end indices of the part to replace
    start_index = 0
    for i in range(idx + 1):
        start_index = md_content.find(start_substring, start_index)
        if start_index == -1:
            break
        else:
            start_index += len(start_substring)
    if start_index != -1:  # if start_substring is found
        end_index = md_content.find(end_substring, start_index)
        if end_index != -1:  # if end_substring is found
            # Replace the old string with the new string
            new_md_content = md_content[:start_index] + new_string + md_content[end_index:]
    return new_md_content


###################################################################
# Include figure description in the Markdown content
# Args:
#  - input_file_path (str): The path to the input file.
#  - result (DocumentAnalysisResult): The result of the document analysis.
#  - output_folder (str): The folder where the cropped images will be saved.
# Returns:
#  - md_content (str): The updated Markdown content.
#  - fig_metadata (dict): The metadata of the figures.
###################################################################

def include_figure_in_md(input_file_path, result, output_folder = IMAGE_STORE_FOLDER):
    print(f"Processing figures in {input_file_path}...")

    base_name = os.path.basename(input_file_path)
    file_name_without_extension = os.path.splitext(base_name)[0]

    md_content = result.content

    # Dumping the initial Markdown we got from Document Intelligence
    output_file = f"{file_name_without_extension}_init.md"
    os.makedirs(output_folder, exist_ok=True)
    with open(os.path.join(output_folder, output_file), "w") as f:
        f.write(md_content)

    fig_metadata = {}
    # if output folder does not exist, create it
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    if result.figures:
        for idx, figure in enumerate(result.figures):
            figure_content = ""
            img_description = ""
            for i, span in enumerate(figure.spans):
                figure_content += md_content[span.offset:span.offset + span.length]
            # Note: figure bounding regions currently contain both the bounding region of figure caption and figure body
            if figure.caption:
                caption_region = figure.caption.bounding_regions
                for region in figure.bounding_regions:
                    if region not in caption_region:
                        boundingbox = (
                                region.polygon[0],  # x0 (left)
                                region.polygon[1],  # y0 (top)
                                region.polygon[4],  # x1 (right)
                                region.polygon[5]   # y1 (bottom)
                            )
                        cropped_image = crop_image_from_file(input_file_path, region.page_number - 1, boundingbox) # page_number is 1-indexed
                        # Get the base name of the file
                        base_name = os.path.basename(input_file_path)
                        # Remove the file extension
                        file_name_without_extension = os.path.splitext(base_name)[0]
                        output_file = f"{file_name_without_extension}_cropped_image_{idx}.png"
                        cropped_image_filename = os.path.join(output_folder, output_file)
                        cropped_image.save(cropped_image_filename)
                        img_desc, image_url = understand_image_with_gptv(cropped_image_filename, figure.caption.content)
                        img_description += f"<figcaption>{figure.caption.content}</figcaption>\n{img_desc}"
            else:
                for region in figure.bounding_regions:
                    boundingbox = (
                            region.polygon[0],  # x0 (left)
                            region.polygon[1],  # y0 (top
                            region.polygon[4],  # x1 (right)
                            region.polygon[5]   # y1 (bottom)
                        )
                    cropped_image = crop_image_from_file(input_file_path, region.page_number - 1, boundingbox) # page_number is 1-indexed
                    
                    output_file = f"{file_name_without_extension}_cropped_image_{idx}.png"
                    cropped_image_filename = os.path.join(output_folder, output_file)
                    cropped_image.save(cropped_image_filename)

                    img_desc, image_url = understand_image_with_gptv(cropped_image_filename, "")
                    img_description += img_desc
            fig_metadata[idx] = image_url
            md_content = update_figure_description(md_content, img_description, idx)
            output_file = f"{file_name_without_extension}_cropped_image_{idx}.txt"
            with open(os.path.join(output_folder, output_file), "w") as f:
                f.write(img_description)

    # Dumping the updated Markdown after inserting LLM computed image descriptions
    output_file = f"{file_name_without_extension}.md"
    with open(os.path.join(output_folder, output_file), "w") as f:
        f.write(md_content)

    return md_content, fig_metadata


####################################################################
# Class: Customized Azure AI Document Intelligence Parser
####################################################################

class AzureAIDocumentIntelligenceParser(BaseBlobParser):
    def __init__(
        self,
        api_endpoint: str,
        api_key: str,
        api_version: Optional[str] = None,
        api_model: str = "prebuilt-layout",
        mode: str = "markdown",
        analysis_features: Optional[List[str]] = None,
    ):
        kwargs = {}
        if api_version is not None:
            kwargs["api_version"] = api_version

        if analysis_features is not None:
            _SUPPORTED_FEATURES = [
                DocumentAnalysisFeature.OCR_HIGH_RESOLUTION,
            ]

            analysis_features = [
                DocumentAnalysisFeature(feature) for feature in analysis_features
            ]
            if any(
                [feature not in _SUPPORTED_FEATURES for feature in analysis_features]
            ):
                logger.warning(
                    f"The current supported features are: "
                    f"{[f.value for f in _SUPPORTED_FEATURES]}. "
                    "Using other features may result in unexpected behavior."
                )

        self.client = DocumentIntelligenceClient(
            endpoint=api_endpoint,
            credential=AzureKeyCredential(api_key),
            headers={"x-ms-useragent": "langchain-parser/1.0.0"},
            features=analysis_features,
            
            **kwargs,
        )
        self.api_model = api_model
        self.mode = mode
        assert self.mode in ["single", "markdown"]

    def _generate_docs_single(self, file_path: str, result: Any) -> Iterator[Document]:
        md_content, fig_metadata = include_figure_in_md(file_path, result)
        yield Document(page_content=md_content, metadata={"images": fig_metadata})

    def lazy_parse(self, file_path: str) -> Iterator[Document]:
        """Lazily parse the blob."""
        blob = Blob.from_path(file_path)
        with blob.as_bytes_io() as file_obj:
            poller = self.client.begin_analyze_document(
                self.api_model,
                file_obj,
                content_type="application/octet-stream",
                output_content_format=DocumentContentFormat.MARKDOWN if self.mode == "markdown" else "text",
            )
            result = poller.result()

            if self.mode in ["single", "markdown"]:
                yield from self._generate_docs_single(file_path, result)
            else:
                raise ValueError(f"Invalid mode: {self.mode}")


####################################################################
# Customized Azure AI Document Intelligence Loader
####################################################################

class AzureAIDocumentIntelligenceLoader(BaseLoader):
    def __init__(
        self,
        api_endpoint: str,
        api_key: str,
        file_path: Optional[str] = None,
        api_version: Optional[str] = None,
        api_model: str = "prebuilt-layout",
        *,
        analysis_features: Optional[List[str]] = None,
    ) -> None:
        assert (
            file_path is not None
        ), "file_path must be provided"
        self.file_path = file_path

        self.parser = AzureAIDocumentIntelligenceParser(
            api_endpoint=api_endpoint,
            api_key=api_key,
            api_version=api_version,
            api_model=api_model,
            mode="markdown",
            analysis_features=analysis_features,
        )

    def lazy_load(
        self,
    ) -> Iterator[Document]:
        """Lazy load given path as pages."""
        if self.file_path is not None:
            yield from self.parser.parse(self.file_path)
        else:
            raise ValueError(f"Only local path is supported for now.")
