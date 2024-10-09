<div style="text-align: center;">
  <img src="./assets/images/ITSARAG-Logo.jpg" alt="It's a RAG!">
</div>

# IT'S A RAG Hackathon

Welcome to **IT'S A RAG** Hackathon.

🛠️ Build, innovate, and Hack together! 🛠️ It's time to start building AI applications using the power of RAG (Retrieval Augmented Generation). 🤖 + 📚 = 🔥

Large language models are powerful language generators, but they don't know everything about the world. RAG (Retrieval Augmented Generation) combines the power of large language models with the knowledge of a search engine. This allows you to ask questions of your own data, and get answers that are relevant to the context of your question.

**IT'S A RAG** Hackathon is your opportunity to get deep into RAG and start building RAG yourself: The challenges are designed to be completed in order and their increase their complexity as you progress through them.

This hackathon is designed to help you learn and grow your skills in the field of AI and RAGs: you will learn how to build RAG apps on top of Azure AI in multiple models (Open AI / Phi-3.5) with multiple retrievers (AI Search, Azure SQL) with a defined Dataset or even your own data sources! 

You'll learn about a popular framework, LangChain, plus the latest technology, like agents and multi modal.

> This Hackathon is providing a selection of datasets to be used BUT you can bring your own data instead.

A bit more of a deep-dive on topics? Through the course of the hackathon, you will learn how to:

- Connect with LLMs (Open AI / Microsoft Phi3.5)
- Ingest your Docs in Azure AI Search
- Prepare your unstructured data (Azure Document intelligence) and add different data sources (PDFs, Databases) with Langchain
- Create your first multi-agent solution
- Create your first agent calling an API to complete an action
- Deploy everything in Azure using Azure Container Apps.

-----------------------------------------------------------------
## Getting Started

the repository is organized in the following way:

- **.devcontainer**: Contains the configuration to create a development container with all the necessary tools to complete the challenges.
- **assets**: Contains images and other assets used for the documentation and challenges instructions.
- **challenges**: Each challenge is a folder with a markdown file that contains the instructions to complete the challenge.
- **data**: Contains the datasets you will use during in the challenges.
- **infra**: Contains the infrastructure as code to deploy the necessary resources to complete the challenges.
- **lib**: Contains custom libraries you will use during the challenges.
- **scripts**: Contains scripts to help you to complete the challenges.
- **src**: Contains the source code to complete during the challenges.

### Prerequisites

#### Azure Subscription
This Hackathon is designed to be run on Azure. Each participant needs an Azure subscription to complete the challenges.

> [!NOTE] 
> To complete the challenges you need to have at least the following roles assigned:
> * Contributor
> * User Access Administrator
> * Storage Blob Data Contributor

#### Development Environment

This Hackathon requires you develop in Python. You can use any IDE you prefer, but we recommend using Visual Studio Code.

**We strongly recommend using the provided development container. This container has all the necessary tools to complete the challenges.**

Here the minimal list of tools you need to have installed:

* Visual Studio Code
* Python 3.12
* Azure CLI 2.63.0
* Azure Developer CLI extension 1.9.7
* Windows Subsystem Linux 2
* Docker Desktop 4.34 with WSL2 Engine

We also suggest to add the following extensions to your Visual Studio Code:

* GitHub Copilot
* GitHub Copilot Chat
* GitHub Repositories
* Jupyter
* Docker
* Postman
* PowerShell
* Python Environment Manager
* Azure Storage Explorer
* Remote Development
* vscode-pdf
* Bicep
* YAML

Feel free to use any other tools/extensions you think are necessary for your development environment and could help you to complete the challenges.

Have fun! 🚀🚀
