---
authors:
  - meysam@developer-friendly.blog
date: 2024-03-24
title: "GitOps Demystified: Introduction to FluxCD for Kubernetes"
description: Explore the fundamentals of GitOps with FluxCD in our beginner-friendly guide. Learn how to automate Kubernetes deployments and enhance your delivery pipeline.
icon: fontawesome/arrows-rotate
draft: true
categories:
  - Kubernetes
  - FluxCD
  - GitOps
  - Cilium
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

[k8s-the-hard-way]: ./0003-kubernetes-the-hard-way.md
[minikube]: https://minikube.sigs.k8s.io/docs/
[kind]: https://kind.sigs.k8s.io/
[k3s-setup]: ./0005-install-k3s-on-ubuntu22.md

[^1]: https://github.com/fluxcd/flux2/releases/
[^2]: https://cli.github.com/
