---
date: 2024-03-24
title: "GitOps Demystified: Introduction to FluxCD for Kubernetes"
description: Explore the fundamentals of GitOps with FluxCD in our beginner-friendly guide. Learn how to automate Kubernetes deployments and enhance your delivery pipeline.
icon: fontawesome/solid/arrows-rotate
draft: true
categories:
  - Kubernetes
  - FluxCD
  - GitOps
links:
  - ./posts/0003-kubernetes-the-hard-way.md
  - ./posts/0005-install-k3s-on-ubuntu22.md
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
- [ ] Optionally, the GitHub CLI (`gh`)[^2] for easier GitHub operations (
      `v2.47.0` at the time of writing).
- [ ] A basic understanding of [Kustomize][kustomize]. A topic for a future post.

## What is GitOps?

GitOps is a modern approach to managing infrastructure and applications. It
leverages Git repositories as the source of truth for your infrastructure and
application configurations. By using GitOps, you can automate your deployment
processes, enhance your delivery pipeline, and reduce deployment frictions.

!!! quote "GitOps Definition by Wikipedia"

    GitOps evolved from DevOps. The specific state of deployment configuration
    is version-controlled. Because the most popular version-control is Git,
    GitOps' approach has been named after Git. Changes to configuration can be
    managed using code review practices, and can be rolled back using
    version-controlling. Essentially, all of the changes to a code are tracked,
    bookmarked, and making any updates to the history can be made easier. As
    explained by Red Hat, "*visibility to change means the ability to trace and
    reproduce issues quickly, improving overall security.*"[^3]

## What is FluxCD?

FluxCD is a popular GitOps operator for Kubernetes. It automates the deployment
of your applications and infrastructure configurations by syncing them with your
Git repository. FluxCD watches your Git repository for changes and applies them
to your Kubernetes cluster.

## Bootstrap FluxCD

Bootstrap refers to the initial setup of FluxCD in your Kubernetes cluster.
After which, FluxCD will continuously watch your Git repository for changes and
apply them to your cluster.

One of the benefits of using FluxCD during the bootstrap phase is
that you can even upgrade FluxCD itself using the same GitOps approach, as you
would do with your applications.

That means less manual intervention and more automation, especially if you opt
for an automated FluxCD upgrade process[^4]. I don't know about you, but I
cannot have enough automation in my life :grin:.

???+ info "Automated FluxCD Upgrade"

    Since this will not be the topic of today's post, it's worth mentioning
    as a side note that you can automated the FluxCD upgrade process using the
    power of your CI/CD pipelines.

    For example, you can see a `step` of a GitHub Action workflow that upgrades
    FluxCD to the latest version below (source[^5]):

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

### Step 0: Check Pre-requisites

You can check your if your initial setup is acceptable by FluxCD using the
following command:

```shell title="" linenums="0"
flux check --pre
```

### Step 1: Install FluxCD

The FluxCD official documentation recommends the usage of `bootstrap` subcommand.
However, as easy as it may sound, it abstracts you away way too much in my
opinion in that it will commit a couple of resources to your cluster, creates
some Kubernetes CRD resources and returns back a successful message.

You generally don't get to see what has really happened under the hood unless
you investigate on your own.

I personally prefer to know exactly what is being created in my cluster!

It even gets more hectic when the target git repository is not empty and have
other resources in it[^6].

!!! quote ""

    *If you want to use an existing repository, the Flux user must have **admin**
    permissions for that repository.*

Therefore, I generally prefer being explicit and knowing exactly what I'm deploying to
my cluster(s). As such, my preferred method of bootstrapping FluxCD is to
use `flux install` command.

#### Creating the GitHub Repository

Skip this step if you already have a GitHub repository ready for FluxCD.

You will need GitHub CLI[^2] installed for the following to work.

```bash title="" linenums="0"
gh repo create getting-started-with-fluxcd --clone --public
cd getting-started-with-fluxcd
```

#### Installing FluxCD Components

```bash title="" linenums="0"
mkdir flux-system
flux install \
  --components-extra="image-reflector-controller,image-automation-controller" \
  --export > flux-system/gotk-components.yml
```

The resulting manifest is a long one, but if you're curious to see a detailed
view, head over to the repository of this post[^7].

Now, why `flux-system/` directory and why that odd-looking name `gotk-components.yml`
you might ask.

It's always a good idea to logically separate
the resources of your infrastructure in a meaningful directory structure. This
ensures enhanced maintainability and readability of your codebase.

As for the `gotk`, it stands for GitOps Toolkit. Nothing extra and nothing
fancy, just a naming convention that FluxCD uses for its components.

It would be the same name if you had used the `flux bootstrap` command.

#### GitOps the GitOps

Now we have done nothing so far in terms of changing the live state of our
cluster. We have only created a manifest file waiting for some more love.

That's why we need two more resources before actually creating any resources
using FluxCD.

```bash title="" linenums="0"
flux create source git getting-started-with-gitops \
  --url=https://github.com/developer-friendly/getting-started-with-gitops \
  --branch=main \
  --export > flux-system/gotk-source.yml

flux create kustomization flux-system \
    --source=GitRepository/getting-started-with-gitops \
    --path=./flux-system \
    --prune=true \
    --interval=1m \
    --export > flux-system/gotk-sync.yml
```

The resulting resources will look simliar to the following:

```yaml title="flux-system/gotk-source.yml"
-8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/main/flux-system/gotk-source.yml"
```
```yaml title="flux-system/gotk-sync.yml"
-8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/main/flux-system/gotk-sync.yml"
```

Creating a `kustomization.yml` file will allow us to manage these resources
under one umbrella.

```yaml title="flux-system/kustomization.yml"
-8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/main/flux-system/kustomization.yml"
```

We are now ready to apply these resources to our cluster.

!!! tip "First Time FluxCD Installation"

    Only if this is the first time installing FluxCD to the cluster, it's better
    to install the CRDs first to avoid hitting any issues for the custom
    resources we'll create later.

    ```bash title="" linenums="0"
    kubectl apply -f https://github.com/developer-friendly/getting-started-with-gitops/raw/main/flux-system/gotk-components.yml
    ```

```bash title="" linenums="0"
kubectl apply -f kubectl apply -f https://github.com/developer-friendly/getting-started-with-gitops/raw/main/flux-system/gotk-sync.yml
```

[k8s-the-hard-way]: ./0003-kubernetes-the-hard-way.md
[minikube]: https://minikube.sigs.k8s.io/docs/
[kind]: https://kind.sigs.k8s.io/
[k3s-setup]: ./0005-install-k3s-on-ubuntu22.md
[kustomize]: https://kustomize.io/

[^1]: https://github.com/fluxcd/flux2/releases/
[^2]: https://cli.github.com/
[^3]: https://en.wikipedia.org/wiki/DevOps#GitOps
[^4]: https://fluxcd.io/flux/installation/upgrade/#upgrade-with-flux-cli
[^5]: https://fluxcd.io/flux/flux-gh-action/
[^6]: https://fluxcd.io/flux/installation/bootstrap/github/#github-organization
[^7]: https://github.com/developer-friendly/getting-started-with-gitops
