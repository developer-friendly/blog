---
date: 2024-03-24
title: "GitOps Demystified: Introduction to FluxCD for Kubernetes"
description: Explore the fundamentals of GitOps with FluxCD in our beginner-friendly guide. Learn how to automate Kubernetes deployments and enhance your delivery pipeline.
icon: fontawesome/arrows-rotate
draft: true
categories:
  - Kubernetes
  - FluxCD
  - GitOps
---

# Getting Started with GitOps and FluxCD

Learn how to leverage your Git repository, the GitOps style, to manage your
Kubernetes cluster with FluxCD. Enhance your delivery and reduce deployment
frictions with GitOps.

<!-- more -->

## Introduction

GitOps is a modern approach to managing infrastructure and applications. It
leverages Git repositories as the source of truth for your infrastructure and
application configurations. By using GitOps, you can automate your deployment
processes, enhance your delivery pipeline, and reduce deployment frictions.

In this guide, we will explore the fundamentals of GitOps and FluxCD. We will
learn how to set up FluxCD in your Kubernetes cluster and automate your
deployments.

## Prerequisites

Before we start, you need to have the following prerequisites:

- [x] A Kubernetes cluster up and running

    * If you feel nerdy and don't mind getting your hands dirty with a bit of
       complexity, you shall find the [Kubernetes the Hard Way][k8s-the-hard-way]
       very helpful.

    * If you don't have the time or the mood to setup a full-fledged Kubernetes
       cluster, you can either use a managed cluster on a cloud provider, spin up
       any of the easy solutions e.g. [Minikube][minikube], [Kind][kind], or
       follow our previous guide to [Setup a production-ready Kubernetes cluster
       using K3s][k3s-setup].

- [x] A Git repository to store your Kubernetes manifests
- [x] FluxCD[^1] binary installed in your `PATH` (`v2.2.3` at the time of writing)
- [ ] Optionally, the GitHub CLI (`gh`)[^2] for easier GitHub operations

## What is GitOps?

GitOps is a modern approach to managing infrastructure and applications. It
leverages Git repositories as the source of truth for your infrastructure and
application configurations. By using GitOps, you can automate your deployment
processes, enhance your delivery pipeline, and reduce deployment frictions.

## What is FluxCD?

FluxCD is a popular GitOps operator for Kubernetes. It automates the deployment
of your applications and infrastructure configurations by syncing them with your
Git repository. FluxCD watches your Git repository for changes and applies them
to your Kubernetes cluster.

## Bootstrap FluxCD

Bootstrap refers to the initial setup of FluxCD in your Kubernetes cluster.
After which, FluxCD will continuously watch your Git repository for changes and
apply them to your cluster.

One of the benefits of using FluxCD itself for during the bootstrap phase is
that you can even upgrade FluxCD itself using the same GitOps approach, as you
would do for your applications.

That means less manual intervention and more automation, especially if you opt
for an automated FluxCD upgrade process[^3].

???+ info "Automated FluxCD Upgrade"

    Since this will not be the topic of today's post, it's worth mentioning
    as a side note that you can automated the FluxCD upgrade process using the
    power of your CI/CD pipelines.

    For example, you can see a `step` of a GitHub Action workflow that upgrades
    FluxCD to the latest version below (source[^4]):

    ```yaml title=""
    - name: Setup Flux CLI
      uses: fluxcd/flux2/action@main
      with:
        # Flux CLI version e.g. 2.0.0.
        # Defaults to latest stable release.
        version: 'latest'

        # Alternative download location for the Flux CLI binary.
        # Defaults to path relative to $RUNNER_TOOL_CACHE.
        bindir: ''
    ```

### Step 1: Install FluxCD

The FluxCD official documentation recommends the usage of `bootstrap` subcommand.
However, as easy as it may sound, it abstracts you away way too much in my
opinion in that it will commit a couple of resources to your cluster, creates
some Kubernetes CRD resources and returns back a successful message. You generally
don't get to see what has really happened under the hood unless you investigate
on your own.

It even gets hectic when the target git repository is not empty and have other
resources in it[^5].

!!! quote ""

    *If you want to use an existing repository, the Flux user must have **admin**
    permissions for that repository.*

Therefore, I generally prefer being explicit and knowing exactly what I'm deploying to
my cluster(s). As such, my preferred method of bootstrapping FluxCD is to
use `flux install` command.

#### Creating the GitHub Repository

You will need GitHub CLI[^2] installed for the following to work.

```bash title="" linenums="0"
gh repo create getting-started-with-fluxcd --clone --public
cd getting-started-with-fluxcd
```

#### Installing FluxCD Components

```bash title="" linenums="0"
flux install \
  --components-extra="image-reflector-controller,image-automation-controller" \
  --export > flux-system/gotk-components.yml
```

[k8s-the-hard-way]: ./0003-kubernetes-the-hard-way.md
[minikube]: https://minikube.sigs.k8s.io/docs/
[kind]: https://kind.sigs.k8s.io/
[k3s-setup]: ./0005-install-k3s-on-ubuntu22.md

[^1]: https://github.com/fluxcd/flux2/releases/
[^2]: https://cli.github.com/
[^3]: https://fluxcd.io/flux/installation/upgrade/#upgrade-with-flux-cli
[^4]: https://fluxcd.io/flux/flux-gh-action/
[^5]: https://fluxcd.io/flux/installation/bootstrap/github/#github-organization
