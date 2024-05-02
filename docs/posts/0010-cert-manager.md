---
date: 2024-05-06
draft: true
description: >-
  TODO
---

# cert-manager: A Kubernetes Certificate Manager

Kubernetes is a great orchestration tool for managing your applications and all
its dependencies. However, it comes with an extendable architecture and with an
unopinionated approach to many of the day-to-day operational tasks.

One of these tasks is the management of TLS certificates. This includes issuing
as well as renewing certificates from a trusted Certificate Authority.
This CA may be a public internet-facing application or an internal service that
needs encrypted communication between parties.

In this post, we will introduce the industry de-facto tool of choice for
managing certificates in Kubernetes: `cert-manager`. We will walk you through
the installation, configuring the issuer(s), and receiving a TLS certificate
as a Kubernetes Secret for the [ingress] or [gateway] of your application.

<!--
SEO keywords:
 - cert-manager
 - kubernetes
 - certificate
 - TLS
 - HTTPS
 - ingress
 - gateway
 - cilium
 - AWS
 - Route53
 - Cloudflare
-->


<!-- more -->

## Introduction

If you have deployed any reverse proxy in the pre-Kubernetes era, you might
have, at some point or another, bumped into the issuance and renewal of TLS
certificates. The trivial approach, back in the days as well as even today,
was to use [certbot]. This command-line utility abstracts you away from the
complexity of the underlying CA APIs and deals with the certificate issuance
and renewal for you.

Certbot is created by the Electronic Frontier Foundation (EFF) and is a great
tool for managing certificates on a single server. However, when you're working
at scale with many applications and services, you will benefit from the
automation and integration that [cert-manager] provides.

Cert-manager is a Kubernetes-native tool that extends the Kubernetes API with
custom resources for managing certificates. It is built on top of the
[Operator pattern], and is a graduated project of the [CNCF].

With that introduction, let's kick off the installation of cert-manager.

## Pre-requisites

Before we start, make sure you have the following set up:

- [x] A Kubernetes cluster. We have a couple of guides in our archive if you
      need help setting up a cluster:
      - [Kubernetes the Hard Way](./0003-kubernetes-the-hard-way.md)
      - [Lightweight K3s installation on Ubuntu](./0005-install-k3s-on-ubuntu22.md)
      - [Azure AKS TF Module](./0009-external-secrets-aks-to-aws-ssm.md)
- [ ] Although not required, we will use FluxCD as a GitOps approach for our
      deployments. You can either follow along and use the Helm CLI, or follow
      our earlier guide for
      [introduction to FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md).
- [ ] Optionally, External Secrets Operator installed. We will use it in this
      guide to store the credentials for the DNS01 challenge.
      - We have covered the installation of ESO in our last week's guide if
        you're new to it:
        [External Secrets Operator](./0009-external-secrets-aks-to-aws-ssm.md)

## Installation

cert-manager comes with a first-class support for Helm chart installation.
This makes the installation rather straightforward.

As mentioned earlier, we will install the Helm chart using FluxCD CRDs.

```yaml title="cert-manager/namespace.yml"
-8<- "docs/codes/0010/cert-manager/namespace.yml"
```

```yaml title="cert-manager/repository.yml"
-8<- "docs/codes/0010/cert-manager/repository.yml"
```

```yaml title="cert-manager/release.yml"
-8<- "docs/codes/0010/cert-manager/release.yml"
```

Although not required, it is hugely beneficial to store the Helm values as it
is in your VCS. This makes your future upgrades and code reviews easier.

```shell title=""
helm show values jetstack/cert-manager > values.yml
```

```yaml title="cert-manager/values.yml"
-8<- "docs/codes/0010/cert-manager/values.yml"
```

Additionally, we will use [Kubernetes Kustomize]:

```yaml title="cert-manager/kustomizeconfig.yml"
-8<- "docs/codes/0010/cert-manager/kustomizeconfig.yml"
```

```yaml title="cert-manager/kustomization.yml" hl_lines="14"
-8<- "docs/codes/0010/cert-manager/kustomization.yml"
```

Notice the namespace we are instructing Kustomization to place the resources in.

Ultimately, to create this stack, we will create a [Kustomization resource]:

```yaml title="cert-manager/kustomize.yml"
-8<- "docs/codes/0010/cert-manager/kustomize.yml"
```

You may either advantage from the recursive reconciliation of FluxCD, add it
to your root Kustomization or apply the resources manually from your command line.

```shell title=""
kubectl apply -f cert-manager/kustomize.yml
```

??? example "Build Kustomization"

    A good practice is to build your resources locally and optionally apply
    them as a dry-run to debug any potential typo or misconfiguration.

    ```shell title="" linenums="0"
    kustomize build ./cert-manager
    ```

    And the output:

    ```yaml title=""
    -8<- "docs/codes/0010/junk/cert-manager/manifests.yml"
    ```

[certbot]: https://certbot.eff.org/
[ingress]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[gateway]: https://gateway-api.sigs.k8s.io/
[cert-manager]: https://cert-manager.io/
[Operator pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[CNCF]: https://www.cncf.io/
[Kustomization resource]: https://fluxcd.io/flux/components/kustomize/kustomizations/
[Kubernetes Kustomize]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/
