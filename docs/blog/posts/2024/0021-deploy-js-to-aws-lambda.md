---
date: 2024-09-02
description: >-
  Learn to deploy NodeJS apps to AWS Lambda using OpenTofu for IaC and GitHub
  Actions for CI/CD. A comprehensive guide for engineers implementing GitOps.
categories:
  - AWS
  - AWS Lambda
  - Bun
  - CI/CD
  - Continuous Deployment
  - Continuous Integration
  - GitHub
  - GitHub Actions
  - IaC
  - Infrastructure as Code
  - JavaScript
  - NodeJS
  - OpenTofu
  - Serverless
  - Terraform
  - OpenID Connect
  - OIDC
# links:
# image: assets/images/social/2024/08/19/azure-bastion-host-secure-cloud-access-made-simple.png
---

# How to Deploy NodeJS to AWS Lambda with OpenTofu & GitHub Actions

If you're a software engineer in any tier, there's a good chance that you're
already familiar with the language and syntax of JavaScript. It has a very low
barrier for entry and that is one of its strongest suits and what makes it so
widely adopted and popular.

In this article, you'll learn how to deploy a JavaScript application to AWS
Lambda using the principles of GitOps and with the help of OpenTofu as the
Infrastructure as Code and GitHub Actions for the CI/CD pipeline.

Stick till the end to find out how.

<!-- more -->

<!--
1. Introduction

1.1 The Popularity of JavaScript in Software Engineering
1.2 Overview of the Deployment Process

2. Prerequisites

2.1 Required Tools and Technologies
2.2 Setting Up Your Development Environment

3. Building a NodeJS Application for AWS Lambda

3.1 Creating a Basic NodeJS Function
3.2 Best Practices for Lambda-Compatible NodeJS Code
3.3 Code Snippet: Example Lambda Function

4. Infrastructure as Code with OpenTofu

4.1 Introduction to OpenTofu
4.2 Defining AWS Lambda Resources
4.3 Code Snippet: OpenTofu Configuration for Lambda

5. Implementing GitOps Principles

5.1 Version Control for Infrastructure and Application Code
5.2 Pull Request Workflow for Changes

6. Setting Up GitHub Actions for CI/CD

6.1 Creating a GitHub Actions Workflow
6.2 Configuring AWS Credentials in GitHub Secrets
6.3 Code Snippet: GitHub Actions Workflow YAML

7. Deploying to AWS Lambda

7.1 Automated Deployment Process
7.2 Verifying the Deployment
7.3 Troubleshooting Common Deployment Issues

8. Performance Optimization and Monitoring

8.1 Lambda Function Optimization Techniques
8.2 Monitoring Tools and Best Practices

9. Security Considerations

9.1 IAM Roles and Permissions
9.2 Securing Your Lambda Function

10. Conclusion
- 10.1 Recap of the Deployment Process
- 10.2 Next Steps and Further Learning Resources
-->

## Introduction

### The Popularity of JavaScript in Software Engineering

Given the wide adoption of [JavaScript], it's no surprise that many developers
would opt-in to write their applications in this language. It's easy to learn,
and a lot of people financially benefit by employing their stack and deploying
their application written in JavaScript.

In hindsight, JavaScript is a great choice for its dynamism and flexibility.
You will likely find more JavaScript developers in the market when looking for
a new hire than you'd, for example, find Erlang developers! :nerd:

### Overview of the Deployment Process

Regardless of the choice for the programming language, you will need a hosting
environment to deploy your application and [AWS] comes really strong with its
full suite of services.

As an SRE, I can assure you that I am yet to see a reliable and scalable
platform as good as [AWS]. Financial wise, I believe that AWS is way too
expensive and not a good choice for small startups and solopreneurs.

However, when considering its serverless option, the [AWS Lambda], I think
there are only a few providers out there that can compete with its offering.

That's why in today's article, I aim to develop and deploy a JavaScript
application and deploy it using the [NodeJS] runtime in [AWS Lambda].

The agenda is straightforward:

- [x] Create a JavaScript application that can handle HTTP requests coming from
      the API Gateway.
- [x] Use [OpenTofu] to define the infrastructure as code for the Lambda
      function.
- [x] Implement GitOps principles to manage the continuous integration and
      continuous deployment pipeline within [GitHub Actions].

If any of these stages look a bit scary, fret not! I'll guide you through each
step and provide you with the necessary code snippets to provide a complete
understanding of what is happening under the hood.

## Prerequisites

### Required Tools and Technologies

Before we dive into the development and deployment process, let's make sure
that you have the necessary tools and technologies installed on your machine.

Here's a list of what you'll need:

- [x] Bun[^bun-install] or NPM[^npm-install] installed on your machine. Either
  works, at least one is required and I'll be using [Bun] in this article.
- [x] An AWS account with the necessary permissions to create and manage Lambda
  functions and API Gateway resources.
- [x] A [GitHub] account to create a new repository and set up the CI/CD pipeline
  using [GitHub Actions].
- [x] [OpenTofu] v1.8 installed[^opentofu-install].
- [x] [Terragrunt] v0.70 installed[^terragrunt-install].

### Setting Up Your Development Environment

The directory structure for this project is as follows:

```plaintext
.
├── application/
│   ├── index.js
│   ├── package.json
├── infra/
│   ├── aws-github-oidc/
│   ├── gateway/
│   ├── lambda/
│   └── repository/
└── terragrunt.hcl
```

## Building a NodeJS Application for AWS Lambda

At this point, we're ready to start creating our main application. The target
for this section is the `application/` directory, creating a [NodeJS] application
in [JavaScript].

### Creating a Basic NodeJS Function

Since we're using [Bun] for our development, we'll need it in our `package.json`
as you see below.

Be mindful of the `"type": "module"` in the definition which allows us to
import other JS files later on.

```json title="application/package.json" hl_lines="10"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/765285871571181ff3dc73b2707dacce9769af26/application/package.json"
```

### Best Practices for Lambda-Compatible NodeJS Code

When developing a NodeJS application for AWS Lambda, there are a few best
practices that you should follow to ensure that your code runs smoothly and
efficiently.

Here are some tips to keep in mind:

- [x] **Keep it small**: Lambda functions have a maximum size limit of 250MB,
  so make sure your code is as small as possible.
- [x] **Use async/await**: Use async/await instead of callbacks to handle
  asynchronous operations.
- [x] **Minimize dependencies**: Only include the dependencies that you need
  in your `package.json` file.
- [x] **Use environment variables**: Store sensitive information like API keys
  and database credentials in environment variables.
- [x] **Handle errors**: Make sure to handle errors properly in your code to
  prevent your Lambda function from crashing.

### Code Snippet: Example Lambda Function

We will be using ECMAScript to develop our application, but you're welcome to
try other alternatives.

```javascript title="application/index.js"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/765285871571181ff3dc73b2707dacce9769af26/application/index.js"
```

The main idea in this code is to have something ready that will respond with
200 on any request, regardless of the method or path. We'll extend this later
when setting up the CI/CD pipeline.

## Infrastructure as Code with OpenTofu

At this stage, we have what we need from an application perspective. Now, we
need to setup the infrastructure to host our application.

As you may have noticed in the directory structure earlier, we have four stacks
we'll be creating for this demo. Each of them serve a specific purpose and you
will be guided on each one of them.

### Introduction to OpenTofu

[OpenTofu] is a tool that allows you to define your infrastructure as code
using a simple and easy-to-understand configuration file. It's built on top of
[Terraform] and provides a more user-friendly interface for managing your
infrastructure.

The configurations in [OpenTofu] are written in the HCL language and stored in
`.tf` files. These files define the resources that you want to create in your
infrastructure, such as EC2 instances, S3 buckets, and Lambda functions.

### Establishing Trust Relationship Between AWS & GitHub

To make sure we do not need to store any hardcoded credentials in our [GitHub]
environment, we will establish a trust relationship between our [AWS] account
and the GitHub repository that will deploy our code to that account.

This is powered by [OpenID Connect] (OIDC) protocol and will allow us to
authenticate GitHub runners with AWS without the need to pass any access-key
and secret-key.

You can read more about it in the official [GitHub]
documentations[^github-aws-oidc] and [AWS] security blog[^aws-sec-blog-oidc].

```terraform title="infra/aws-github-oidc/versions.tf"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/aws-github-oidc/versions.tf"
```

```terraform title="infra/aws-github-oidc/variables.tf"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/aws-github-oidc/variables.tf"
```

```terraform title="infra/aws-github-oidc/main.tf"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/aws-github-oidc/main.tf"
```

```terraform title="infra/aws-github-oidc/outputs.tf"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/aws-github-oidc/outputs.tf"
```

```terraform title="infra/aws-github-oidc/terragrunt.hcl"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/aws-github-oidc/terragrunt.hcl"
```

For this, and all the rest of the [Terragrunt] stacks to follow, we'll use the
same method for provisioning of the resources as you see below.

```shell title="" linenums="0"
$ cd infra/aws-github-oidc
$ terragrunt init
$ terragrunt plan -out tfplan
$ terragrunt apply tfplan
```

### Preparing the GitHub Environment for CI/CD Pipeline

We are now equipped with the established trust between the providers. It's now
time to ensure the [GitHub] setup is ready to execute the pipelines in the
proper environment.

If you don't know much about [GitHub] Environments, you can read more about it
in the official documentations[^github-envs].

The gist of it is that Environment allows you to define specific policies on
which runners and which branches are allowed to access and execute their
pipeline on it and what kind of restrictions are in place, e.g., a certain
checks being passed, a reviewer approving the deployment, etc.

```terraform title="infra/repository/versions.tf"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/repository/versions.tf"
```

The following `terraform_cloud_token` will allow the GitHub runner to store the
remote state in the [Terraform] cloud.

```terraform title="infra/repository/variables.tf" hl_lines="11-16"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/repository/variables.tf"
```

The `AWS_ACCOUNT_ID` secret will ensure that your [AWS] account ID is redacted
in the [GitHub] runner logs. You can see a proof of that in the logs of the
deployment[^lambda-deployment-logs].

```terraform title="infra/repository/main.tf" hl_lines="52-58"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/repository/main.tf"
```

<figure markdown="span">
 ![GitHub runner Lambda Deployment Logs](../../static/img/2024/0021/gh-deploy-lambda-logs.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>GitHub runner Lambda Deployment Logs</figcaption>
</figure>

```terraform title="infra/repository/terragrunt.hcl"
-8<- "https://raw.githubusercontent.com/developer-friendly/aws-lambda-opentofu-github-actions/0b7f77849331dcde8d0411e851b490eef34711cb/infra/repository/terragunt.hcl"
```

We apply this stack just as we did before.

```shell title="" linenums="0"
$ cd infra/repository
$ terragrunt init
$ terragrunt plan -out tfplan
$ terragrunt apply tfplan
```

### Defining AWS Lambda Resources

In the `infra/lambda/` directory, you'll find the configuration file for the
Lambda function. This file defines the resources that are required to deploy
the function to AWS Lambda.

```hcl title="infra/lambda/main.tf"

[JavaScript]: /category/javascript/
[AWS]: /category/aws/
[GitHub]: /category/github/
[GitHub Actions]: /category/github-actions/
[OpenTofu]: /category/opentofu/
[Bun]: /category/bun/
[NodeJS]: /category/nodejs/
[AWS Lambda]: /category/aws-lambda/
[Terraform]: /category/terraform/
[OpenID Connect]: /category/openid-connect/

[^bun-install]: https://bun.sh/docs/installation
[^npm-install]: https://docs.npmjs.com/cli/v10/commands/npm-install
[^opentofu-install]: https://opentofu.org/docs/intro/install/
[^terragrunt-install]: https://terragrunt.gruntwork.io/docs/getting-started/install/
[^github-aws-oidc]: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
[^aws-sec-blog-oidc]: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
[^github-envs]: https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment
[^lambda-deployment-logs]: https://github.com/developer-friendly/aws-lambda-opentofu-github-actions/actions/runs/10627337889/job/29460327863#step:7:178
