---
date: 2024-04-29
draft: true
categories:
  - Kubernetes
  - AWS
  - OpenID Connect
  - OpenTofu
  - Ansible
  - Cilium
  - OAuth2
  - Authentication
  - OIDC
  - Security
  - Cloud Computing
  - Hetzner
  - IaC
links:
  - ./posts/0007-oidc-authentication.md
  - ./posts/0005-install-k3s-on-ubuntu22.md
  - ./posts/0003-kubernetes-the-hard-way.md
  - ./posts/0008-k8s-federated-oidc.md
---

# Getting Started With External Secrets Operator in Kubernetes

How to pass your secrets to the Kubernetes cluster without hard-coding them
into your source code or manually creating the Kubernetes Secret resource.

<!-- more -->

## Introduction

Deploying an application rarely is just the application itself. It is usually
all the tooling and infrastructure around it that makes it work and produce
the value it was meant to.

One of the most common things that applications need is secrets. Secrets are
sensitive information that the application needs to function properly. This
can be database passwords, API keys, or any other sensitive information the
app needs to function correctly.

In Kubernetes, the most common way to pass secrets to the application is by
creating a Kubernetes Secret resource. This resource is a Kubernetes object
that stores sensitive information in the cluster. The application can then
access this information by mounting the secret as a volume or by using
environment variables.

However, creating a Kubernetes Secret resource manually is a tedious task,
especially when working at scale. Not to mention the maintenance required to
rotate the secrets periodically and keep them in sync with the upstream.

Passing secrets as hard-coded and plaintext value is a no-no when it comes to
security. As much of a common sense as it is, going around the industry and
seeing how people hard-code their secrets into the source code pains my soul.

In this article, we will explore how to use the
[External Secrets Operator][external-secret] to
pass secrets to the Kubernetes cluster without hard-coding them into your
source code or manually creating the Kubernetes Secret resource.

## Roadmap

Before we start, let's set a clear objective of what we want to achieve in
this article.

We aim to create a couple of AWS SSM Parameters in an AWS account. Having our
Kubernetes cluster's OpenID Configuration URL exposed to the internet, we will
leverage the trust relationship between the Kubernetes cluster and the AWS
IAM to assume an IAM Role with web identity to read those Parameters and
create Kubernetes Secrets from them as instructed by the External Secret CRD.

If that interests you, let's get started.

## Prerequisites

Before we start, you need to have the following prerequisites:

- [x] A Kubernetes cluster ~v1.29-v1.30
- [x] Internet accessible endpoint to your Kubernetes cluster
- [x] An AWS account with the permissions to read and write SSM parameters and
      to create OIDC provider and IAM roles.
- [ ] Optionally, FluxCD installed in your cluster. Not required if you aim to
      use bare Helm commands for installations.


[external-secret]: https://external-secrets.io/v0.9.16/
