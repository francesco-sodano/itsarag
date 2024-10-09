# Challenges Summary

## Challenge 0 – Learn the Basics

### Content

* Understand the basic for generative AI including tools and models

## Challenge 1 – Establish the Plan

### Content

 * Prepare your development environment
 * Deploy the infrastructure
 * Establish the Team plan and roles

## Challenge 2 – Play with Azure AI Studio

### Content

 * Connect to a LLM for chat completion
 * Ingest your Docs in AzureSearch
 * Play with the two APIs

## Challenge 3 – Start Coding

### Content

* Open the Jupyter Notebook provided.
* Follow the instructions in the notebook to complete the challenge.
    * Play with the vanilla models.
    * Add some of the data provided in the dataset and perform some queries to the models.

## Challenge 4 – Advanced RAG with Azure AI Document intelligence

### Content

* Extract information from unstructured data (Azure Document Intelligence)

## Challenge 5 – Multi-Source, Multi-Agent

### Content

* Create a Multi-Agent Architecture
  * Agent 1: Datasource PDF
  * Agent 2: Datasource Databases

## Challenge 6 – Actions

### Content

* Enhance the Multi-Agent Architecture
  * Agent 1: Datasource PDF
  * Agent 2: Datasource Databases
  * Agent 3: Action Agent (calling external API)

## Challenge 7 – Deploy your App (ACA)

### Content

 * Deploy your App (Chainlit / another)
   * Provision and deploy by executing `azd up`
 * Connect your LLM (OpenAI/Phi3)
   * Deploy by executing `azd deploy`
 * Connect your Data (AzureSearch)
   * Deploy by executing `azd deploy`
 * Connect your Evaluation framework
 * Collect your History
   * Evaluation: use collected history for evaluation

## Challenge 8 – Evaluate your application

### Content
 * Evaluate using Azure AI Studio
 * Introduce an evaluation framework (prompt flow)
 * Introduce simple unit tests (pytest)
 * Responsible AI (protection from bias)
   * Activate content safety and & prompt shield
   * Test it
 * Learn about code coverage and AI Apps
 * Generate synthetic tests
