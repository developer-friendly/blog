---
date: 2024-04-29
draft: true
description: >-
  Securely fetch AWS SSM Parameters into Azure AKS Kubernetes cluster with
  External Secrets operator using OpenID Connect trust relationship to AWS IAM.
categories:
  - Kubernetes
  - AWS
  - AKS
  - OpenTofu
  - OpenID Connect
  - Azure
  - Ansible
  - Cilium
  - OAuth2
  - Authentication
  - OIDC
  - Security
  - Cloud Computing
  - IaC
links:
  - ./posts/0007-oidc-authentication.md
  - ./posts/0005-install-k3s-on-ubuntu22.md
  - ./posts/0003-kubernetes-the-hard-way.md
  - ./posts/0008-k8s-federated-oidc.md
  - ./posts/0002-external-secret-immutable-target.md
---

# Getting Started With External Secrets Operator in Kubernetes

How to pass your secrets to the Kubernetes cluster without hard-coding them
into your source code or manually creating the Kubernetes Secret resource.

<!-- more -->

<!--
high level overview:

1. setting up azure aks with TF module
2. establishing a trust relationship using OIDC with AWS IAM
3. creating two IAM roles for external secrets operator (read and write)
4. test the set up by creating ExternalSecret and PushSecrets
-->

## Introduction

Deploying an application rarely is just the application itself. It is usually
all the tooling and infrastructure around it that makes it work and produce
the value it was meant to.

One of the most common things that applications need is secrets. Secrets are
sensitive information that the application needs to function properly. This
can be database passwords, API keys, or any other sensitive information the
app uses to function and communicate with all the relevant external services.

In Kubernetes, the most common way to pass secrets to the application is by
creating a [Kubernetes Secret resource]. This resource is a Kubernetes object
that stores sensitive information in the cluster. The application can then
access this information by mounting the secret as a volume or by using
environment variables.

However, creating a Kubernetes Secret resource manually is a tedious task,
especially when working at scale. Not to mention the maintenance required to
rotate the secrets periodically and keep them in sync with the upstream.

On the other hand, passing secrets as hard-coded and plaintext value is a no-no
when it comes to security. As much of a common sense as it is, going around the
industry and seeing how people hard-code their secrets into the source code
pains my soul.

In this article, we will explore how to use the
[External Secrets Operator][external-secret] to
pass secrets to the Kubernetes cluster without hard-coding them into your
source code or manually creating the Kubernetes Secret resource.

## Roadmap

Before we start, let's set a clear objective of what we want to achieve in
this article.

First off, we'll create an Azure AKS Kubernetes cluster using the
[OpenTofu](/category/opentofu) module. The AKS cluster will have its OpenID
Connect endpoint exposed to the internet.

We will use that OpenID Connect endpoint to establish a trust relationship
between the Kubernetes cluster and the AWS IAM, leveraging
[OpenID Connect](/category/openid-connect). This trust relationship will
allow the Kubernetes cluster's Service Accounts to assume an IAM Role with
web identity to access AWS resources.

Afterwards, we will deploy the External Secrets operator in the Kubernetes
cluster passing the right Service Account to its running pod so that it can
assume the proper [AWS IAM Role].

With that set up, the External Secrets operator will be able to read the
secrets from the AWS SSM Parameter Store and create Kubernetes Secrets from
them.

At this point, any pod in the same namespace as the target Secret will be able
to mount and read its values business as usual.

Optionally, we'll also cover how to allow the External Secrets operator to
write back to the AWS SSM Parameter Store the values of the Kubernetes Secrets
we want it to. An example include deploying a database with a generated
password and storing that password back in the AWS SSM Parameter Store for
references by other services or applications.

!!! success "OpenID Connect"

      OpenID Connect, in simple terms, is a protocol that allows one service
      to authenticate and authorize another service, optionally on behalf of
      a user. It is an authentication layer on top of OAuth2.0 protocol.

      If you're new to the topic, we have a practical example to solidify your
      understanding in our guide on
      [OIDC Authentication](./0007-oidc-authentication.md).

With that said, let's get started!

## Prerequisites

Before we start, you need to have the following prerequisites:

<div class="annotate" markdown>
- [x] A Kubernetes cluster v1.29-ish. Feel free to follow earlier guides to
      set up the Kubernetes cluster [the Hard Way](./0003-kubernetes-the-hard-way.md)
      or [using k3s](./0005-install-k3s-on-ubuntu22.md). Although we'll spin
      up a new Kubernetes cluster using [Azure AKS TF module][aks-tf-mod].
- [x] Internet accessible endpoint to your Kubernetes API server (1). We have
      covered [how to expose your Kubernetes API server](./0008-k8s-federated-oidc.md)
      in last week's guide. Azure AKS, however, comes with a public
      [OpenID Connect](/category/openid-connect) endpoint [by default][aks-oidc].
- [x] An AWS account with the permissions to read and write SSM parameters and
      to create OIDC provider and IAM roles.
- [ ] Optionally, FluxCD installed in your cluster. Not required if you aim to
      use bare Helm commands for installations. There is a beginner friendly
      [guide to FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md)
      in our archive if you're new to the topic.
</div>

1. You're free to run a local Kubernetes cluster and expose it to the internet
   using tools like [ngrok][ngrok] or [telepresence][telepresence].

## Step 0: Setting up Kubernetes and Establishing Trust with AWS IAM

First things first, let's set up the Azure AKS Kubernetes cluster using the
official TF module.

```shell title="" linenums="0"
export ARM_SUBSCRIPTION_ID=159f2485-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export ARM_TENANT_ID=72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

<!--
## Step 1: Creating an AWS IAM Role for External Secrets Operator

The External Secrets operator will require some permissions to be able to read
and possibly write the [AWS SSM Parameters][aws-ssm]. Although AWS SSM is not
the only backend supported by the External Secrets operator, it is one we'll
cover today as it is easy to setup, free to use, and has the least amount of
drama around it! For a full list of supported backends, refer to the
[External Secrets documentation][external-secret].

We will cover two cases today. One for the External Secrets operator to only
fetch the AWS SSM Parameter values and create Kubernetes Secrets from them.

The other will be to allow the External Secrets operator to write back to the
AWS SSM Parameters the Secrets created inside the cluster. This is useful when
those values are first initialized inside the cluster and need to be stored
back in the AWS SSM Parameter Store, possibly used by other services or
applications.
-->

[external-secret]: https://external-secrets.io/v0.9.16/
[telepresence]: https://www.telepresence.io/
[ngrok]: https://ngrok.com/
[aws-ssm]: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
[aks-tf-mod]: https://registry.terraform.io/modules/Azure/aks/azurerm/8.0.0
[aks-oidc]: https://learn.microsoft.com/en-us/azure/aks/use-oidc-issuer
[Kubernetes Secret resource]: https://kubernetes.io/docs/concepts/configuration/secret/
[AWS IAM Role]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
