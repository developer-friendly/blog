---
authors:
  - meysam@developer-friendly.blog
date: 2024-03-22
draft: true
categories:
  - Kubernetes
  - IaC
  - Cilium
  - OpenTofu
  - Ansible
  - Cloud Computing
  - Hetzner
---

# How to Install Lightweight Kubernetes on Ubuntu 22.04

Learn how to deploy a lightweight Kubernetes cluster using k3s on Ubuntu 22.04
using OpenTofu & Ansible on Hetzner Cloud with Cilium as the CNI.

<!-- more -->

## Introduction

Kubernetes is a powerful container orchestration platform that allows you to
deploy, scale, and manage containerized applications. However, setting up a
Kubernetes cluster can be a complex and time-consuming process and usually
requires a PhD in Kubernetes.

However, most people are not in the business of managing Kubernetes clusters,
nor do they feel nerdy enough to spend their weekends configuring YAML files.

On the other hand, it's not just about the level of complexity involved in
managing a bunch of Kubernetes components, but also the cost of running a
full-fledged Kubernetes cluster in the cloud, be it managed or self-hosted.

That is to say that you will likely find yourself looking for a robust and
production-ready Kubernetes distribution that is lightweight, easy to install,
and easy to manage.

### Why should you care?

That's where [k3s](https://k3s.io/) comes into play. k3s is a lightweight
Kubernetes distribution that is designed for production workloads, resource-constrained
environments, and edge computing. It is a fully compliant Kubernetes distribution
that is packaged in a single binary and requires minimal dependencies.

In this post, I will show you how to install k3s on Ubuntu 22.04 using Hetzner
Cloud, OpenTofu, Ansible, and Cilium. Stay with me till the end cause we got
some cool stuff to cover.

## Prerequisites

Here are the list of CLI tools you need installed on your machine.

- [OpenTofu v1.6](https://github.com/opentofu/opentofu)
- [Ansible v2.16](https://www.ansible.com/)

## Step 0: Generate Hetzner API token

For the purpose of this tutorial, we'll only spin up a single server. However,
for production workloads, you should consider setting up a multi-node cluster
for high availability and fault tolerance. You will be guided with some of the
obvious tips at the end of this post.

First, you need to create an account on Hetzner Cloud[^1] and generate an API
token[^2]. Your generated token must have write access cause we need to create
resources on your behalf.

## Step 1: Create the server

Let us structure our project directory as follows:

```plaintext
.
├── ansible/
└── opentofu/
```

Now, let's pin the version for the required TF provider.

```hcl title="opentofu/versions.tf" hl_lines="19"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/versions.tf"
```

???+ tip "Provider Versioning"

    The pinned version in this example is very loose. You might want to be more
    specific in scalable environments where you have multiple projects and need
    to ensure nothing breaks before you intentionally upgrade with enough tests.

    As an example, you can see the Rust compiler team[^3] being too conservative
    in their Ansible versioning as they don't want team members get caught off
    guard with a breaking change.

Notice that we have also created a variable to pass in the previously generated
Hetzner API token. This is a good practice to avoid hardcoding sensitive
information in your codebase.

Next, we'll define the creation of the Hetzner Cloud Server in our TF file.

```hcl title="opentofu/main.tf"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/main.tf"
```

I don't know about you, but I personally love ARM processors. They are energy
efficient and have a great performance. Whenever possible, I will always opt-in
for ARM processors.

!!! warning "ARM64 Architecture"

    You got to consider your workload before adopting ARM64 architecture. Not
    all softwares are compatible with ARM64. However, the good news is that most
    of the popular softwares are already compatible with ARM64, including the
    k3s we are going to install in this tutorial.

You might have noticed in line 7 that we are passing in a `cloud_init` file.
That's an important piece of the whole puzzle. Let's create that file.

```yaml title="opentofu/cloud-init.yml" hl_lines="38-43"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/cloud-init.yml"
```

The first line of this file is not a normal comment. It's a directive that tells
the cloud-init to ignore the rest of the file if it's not a valid cloud-init
config. It has a similar behavior to the shebang in shell scripts.

??? example "Shebang"

    The shebang is a special comment that tells the shell which interpreter to
    use to execute the script. It's usually the first line of a script file.

    ```shell title="hello.sh"
    #!/bin/bash
    echo "Hello, World!"
    ```

    As soon as I make this script executable using `chmod +x hello.sh`, I can
    run it using `./hello.sh` and by parsing the first line, the shell knows
    that it should use the `bash` interpreter to execute the script.

Finally, let's create the relevant output that we'll use for later steps.

```hcl title="opentofu/output.tf"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/output.tf"
```

We have our TF files ready for provisioning the server. Let's create the server
using the `tofu` CLI.

```shell title=""
cd opentofu
tofu init
tofu plan -out tfplan
# observe the plan visually and confirm the changes
tofu apply tfplan
```

Now that we've got the IP address, we can use either the IPv4 or the IPv6 to
connect to the server.

```shell title=""
IP_ADDRESS=$(tofu output -raw server_ipv4_address)
echo "${IP_ADDRESS} k3s-cluster.hetzner" | sudo tee -a /etc/hosts
```

This will ensure that the hostname `k3s-cluster.hetzner` resolves to the IP
address of the server and we won't have to memorize the IP address for every
command we run.



[^1]: https://accounts.hetzner.com/login
[^2]: https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/
[^3]: https://github.com/rust-lang/simpleinfra/blob/e361f222bc377434d06d53add6827bd24a3a5d89/ansible/apply#L13:L15
