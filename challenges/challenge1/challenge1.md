# Challenge 1: Establish Your Plan

## Introduction

After you learn the basics about generative AI, tools, and models, it's time to start building AI applications using the power of RAG (Retrieval Augmented Generation). 🤖 + 📚 = 🔥

In this Hackathon, you will go through a series of challenges to learn how to build RAG apps on top of the Azure platform. At the end, you will produce a complete application ready to scale using an agentic multi-modal RAG.

The final architecture should be similar to the one included in the following diagram:

![Application Architecture](../../assets/images/architecture.drawio.png)

The challenges are designed to be completed in order with increasing complexity: We will start using the Azure portal and the Azure AI Studio, then we will move to Jupyter Notebooks and finally we will deploy the application using Azure Container Apps.

The list of the challenges is the following:

- **Challenge 0: Learn the Basics**: You will understand the basics of generative AI including tools and models. (Already completed)
- **Challenge 1: Establish the Plan**: You will prepare your development environment, deploy the infrastructure, establish the team plan and roles. (this challenge)
- **Challenge 2: Play with Azure AI Studio**: Connect to an LLM for chat completion, ingest your docs in AzureSearch, play with the APIs.
- **Challenge 3: Start Coding**: Use Jupyter Notebook to connect with LLM and ingest the first documents.
- **Challenge 4: Advanced RAG**: You will ingest documents using the most advanced techniques (Advanced RAG) that take into account tables and images.
- **Challenge 5: Multi-Source, Multi-Agent RAG**: You will add additional sources to your RAG and create a multi-agent architecture.
- **Challenge 6: Add Actions**: You will add actions to your RAG to perform API calls to external services.
- **Challenge 7: Deploy your App**: You will develop and deploy your application using Azure Container Apps based on the Jupyter Notebooks you developed.
- **Challenge 8: Evaluation**: You will evaluate your application using an evaluation framework.

For the dataset, you can use the provided datasets or bring your own data.

The provided datasets contain the Annual (10-K) SEC reports in PDF format for the years 2019-2023 for Apple, Microsoft, Amazon, Nvidia, and Intel.
You can have a look at the datasets in the following path: `./data/fsi/pdf/`

---

## Challenge

This challenge is composed by two parts:

- **Part 1**: Prepare your development environment and Deploy your initial infrastructure
- **Part 2**: Establish the Team plan and roles.

## Part 1: Deploy your infrastructure and prepare your development environment

### Step 1. Prepare your development environment

> [!NOTE] 
> We **Strongly** recommend using devcontainer as your development environment. The devcontainer is a Docker container that has all the necessary tools and libraries pre-installed. It will help you to have a consistent development environment across all team members and avoid any issues related to the installation of the required tools and libraries.
> The devcontainer is already included in the repository. You can use it by opening the repository in Visual Studio Code and clicking on the "Reopen in Container" button that appears in the bottom right corner of the window. This will open the repository in a Docker container with all the necessary tools and libraries pre-installed.

#### Dev Container setup

Make sure you have the following elements installed:

* [Visual Studio Code](https://code.visualstudio.com/)
* [Git](https://git-scm.com/downloads)
* [Windows Subsystem Linux 2](https://learn.microsoft.com/en-us/windows/wsl/install)
* [Docker Desktop 4.34 (or newer) with WSL2 Engine](https://docs.docker.com/desktop/windows/install/)
* [Visual Studio Code Dev Container extension](https://code.visualstudio.com/docs/devcontainers/tutorial#_install-the-extension)

If you are on Windows open PowerShell and execute the following command to disable automatic line ending transformation:

```bash
git config --global core.autocrlf false
```

You can set it back to it's initial value after the workshop:
```bash
git config --global core.autocrlf true
```

Clone the repository: 
```bash
git clone https://github.com/francesco-sodano/itsarag.git
```

Open Visual Studio Code and:
1. Go to `File` > `Open Folder...` and open the cloned folder. 
2. Open the command palette with `Ctrl + Shift + P` and run the `Dev Containers: Reopen in Container` command on the repository. This command will create a Dev Container from your repository with every dependency and extension needed to finish the challenges.

If you want to know more click on [Dev Containers](https://containers.dev/) or [Create a Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container).

#### Manual setup

If you want to set-up your development environment manually follow the instructions below. You do not need to follow those steps if you use the Dev Container method above. In that case jump straight to [Azure Subscription Preparation](#azure-subscription-preparation).

##### IDE Preparation

For the development environment, you need to have the following tools installed to perform all the challenges of this hackathon:

* [Visual Studio Code](https://code.visualstudio.com/)
* [Git](https://git-scm.com/downloads)
* [Python 3.10](https://www.python.org/downloads)
* [Azure CLI 2.63.0 or newer](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Azure Developer CLI extension 1.9.7 or newer](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)
* [Windows Subsystem Linux 2](https://learn.microsoft.com/en-us/windows/wsl/install)
* [Docker Desktop 4.34 (or newer) with WSL2 Engine](https://docs.docker.com/desktop/windows/install/)
* [ODBC Driver 18 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver16)

For Visual Studio Code, we also suggest to install the following extensions:

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
Be sure also that your docker is running with WSL2 engine and it's able to download images from the Docker Hub.

##### Create a New Environment in Python

After you clone the repository, our suggestion is to create a new virtual environment (using [venv](https://docs.python.org/3/library/venv.html)) in Python and install the required libraries.

The reasons to use a virtual environment are mainly the following:

- **Preventing version conflicts**: A virtual environment fixes this problem by isolating your project from other projects and system-wide packages. You install packages inside this virtual environment specifically for the project you are working on.
- **Reproducibility**: Virtual environments make it easy to define and install the packages specific to your project. Using a requirements.txt file, you can define exact version numbers for the required packages to ensure your project will always work with a version tested with your code. This also helps other users of your software since a virtual environment helps others reproduce the exact environment for which your software was built.
- **Works everywhere, even when not administrator**: Virtual environments are easy to create and use. They work on all operating systems and do not require administrator rights to create or use. This makes them a great choice for working on shared systems or in environments where you do not have administrator rights.

Be sure to use the right version of the Python interpreter (3.10) and update pip before installing the required libraries.

After the virtual environment is created, you can install the required libraries using the provided `requirements.txt` file included in the challenge folder.

#### <a name="az-subscription-preparation"></a>Azure Subscription Preparation

This Hackathon is designed to be run on Azure. Each participant needs an Azure subscription to complete the challenges.

You need to have at least the following roles assigned:

* Contributor
* User Access Administrator
* Storage Blob Data Contributor

Be also sure that the following providers are registered in your subscription:

Register the subscription providers to be able to deploy the infrastructure (after running az login):
```powershell
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.ContainerService --wait
```

### Step 2. Deploy Azure AI Studio resources

For the next challenges, you need to deploy Azure AI Studio in your subscription.
Although it is possible to deploy it using the Azure Portal, we recommend using the Azure CLI as it gives you more control over the deployment.

At the following path ```./infra/aistudio/```, you will find the necessary files to deploy the Azure AI Studio using the Azure CLI (either the one integrated into the portal or your development environment). Before running the deployment, we suggest creating an empty resource group in Central Sweden and using that as a parameter for the deployment.

> [!NOTE] 
> The deployment will take up to 12 minutes to complete.

After the deployment is completed, check the resources created.

**Q:** *Can you explain what the resources are and how they interact with Azure AI Studio?*


### Step 3. Deploy the final infrastructure

As we want you concentrate on the AI App and not infrastructure, we have prepared a Bicep template that will deploy the necessary resources for the final architecture.

In the following path ```./infra/rag/```, you will find the necessary files to deploy the final infrastructure using ````azd up``` command.

> [!NOTE] 
> The deployment will work only when you will have a valid installation of your development environment as it use Docker to build the container images.

## Part 2: Establish the Team Plan and Roles

To be successful in this Hackathon, your team needs to have a plan.

Establishing a common plan for communication and collaboration is one of the main aspects of any collective work.

Task boards are used to manage tasks better, prevent omissions, and provide project visibility to team members and management. The task board is a centralized information hub that provides a complete picture of your project. A task can be tracked from inception to completion.

**Resist the initial temptation to rush to the keyboard! Now is the time to pause and think as a team about the end-to-end project that you would implement.**

---

## Success Criteria

### Part 1

- You have prepared your development environment.
- You have created a new environment in Python and installed the required libraries.
- You have deployed Azure AI Studio resources.
- You have answered all the questions provided and are able to explain the behavior of the coaches.

### Part 2

- Explain to your coach your Application Architecture. Then, be ready to answer the following questions:
  - What building blocks are you implementing?
  - How are you splitting work amongst the team (who is going to be responsible for what)?
  - How will you communicate among the team (Teams, verbal, ...)?

- Demonstrate to your coach that you have implemented a basic task board to track work in progress that meets the organizational requirements.

> **NOTE**
>
> In some challenges, you need to implement solutions also in building blocks that are not part of your plan: This is to permit experimentation with different approaches and not to focus on one single technology.

---

## FAQ
### PasswordNotComplex issue while running azd up
Just insert a manual safe password.

## Resources
- [Python environments (venv)](https://docs.python.org/3/library/venv.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Developer CLI extension](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)
- [Windows Subsystem Linux 2](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Docker Desktop](https://docs.docker.com/desktop/windows/install/)
- [ODBC Driver 18 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver16)
- [Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/overview)
- [Azure AI Studio resources](https://learn.microsoft.com/en-us/azure/ai-studio/overview#resources)
