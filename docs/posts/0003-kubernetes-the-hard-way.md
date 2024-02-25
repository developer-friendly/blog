---
authors:
  - meysam@developer-friendly.blog
date: 2024-02-19
draft: true
categories:
  - Kubernetes
  - Ansible
  - Vagrant
  - Cilium
---

# Kubernetes The Hard Way

You might've solved this challenge way sooner than I attempted it. Still, I
always wanted to go through the process as it has many angles and learning the
details intrigues me.

This version, however, does not use any cloud provider. Specifically, the things
I am using differently from the original challenge are:

- **Vagrant** & **VirtualBox**: For the nodes of the cluster
- **Ansible**: For configuring everything until the cluster is ready
- **Cilium**: For the network CNI and as a replacement for the kube-proxy

So, here is my story and how I solved the famous "Kubernetes The Hard Way" by
the great Kelsey Hightower. Stay tuned if you're interested in the details.

<!-- more -->

## Introduction

Kubernetes the Hard Way is a great exercise for any system administrator to
really get into the nit and grit of Kubernetes and figure out how different
components work together and what makes it as such.

If you have only used a managed Kubernetes cluster, or used `kubeadm` to spin up
one, this is your chance to really understand the inner workings of Kubernetes.

### Objective

The whole point of this exercise is to build a Kubernetes cluster from scratch,
downloading the binaries, issuing and passing the certificates to the different
components, configuring the network CNI, and finally, having a working
Kubernetes cluster.

With that introduction, let's get started.

## Prerequisites

First things first, let's make sure all the necessary tools are installed on our
system before we start.

### Tools

All the tools mentioned below are the latest versions at the time of writing,
February 2024.

{{ read_csv('docs/codes/0003-k8s-the-hard-way/prerequisites.csv') }}

Alright, with the tools installed, it's time to get our hands dirty and really
get into it.

## The Vagrantfile

The initial step is to have three nodes available. As mentioned earlier, we're
using Vagrant on top of VirtualBox to create these nodes.

These will be Virtual Machines hosted on your local machine. As such, there is
no cloud provider needed in this version of the challenge and all the
configurations are done locally.

The configuration for our Vagrantfile looks as below.

```ruby title="Vagrantfile"
-8<- "docs/codes/0003-k8s-the-hard-way/Vagrantfile"
```

:fontawesome-regular-clipboard:
