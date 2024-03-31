---
date: 2024-03-22
draft: false
categories:
  - Kubernetes
  - IaC
  - Cilium
  - OpenTofu
  - Ansible
  - Cloud Computing
  - Hetzner
links:
  - ./posts/0003-kubernetes-the-hard-way.md
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

!!! success "Complexity not an issue for you?"

      If you're like me, enjoying a good challenge and have a knack for tackling
      complexity, you will be greatly served by spinning up [Kubernetes the
      Hard Way][k8s-the-hard-way] I have published recently.

On the other hand, it's not just about the level of complexity involved in
managing a bunch of Kubernetes components, but also the cost of running a
full-fledged Kubernetes cluster in the cloud, be it managed or self-hosted.

That is to say that you will likely find yourself looking for a robust and
production-ready Kubernetes distribution that is lightweight, easy to install,
and easy to manage.

!!! info "Disclaimer"

      This post is influenced by a community article[^1] on the Hetzner
      Tutorials. I wanted to add Cilium and Ansible to the mix, so I started
      my own journey. I hope you find this post helpful.

### Why should you care?

That's where [k3s](https://k3s.io/) comes into play. k3s is a lightweight
Kubernetes distribution that is designed for production workloads, resource-constrained
environments, and edge computing. It is a fully compliant Kubernetes distribution
that is packaged in a single binary and requires minimal dependencies.

In this post, I will show you how to install k3s on Ubuntu 22.04 using [Hetzner
Cloud](/category/hetzner/), [OpenTofu](/category/opentofu/),
[Ansible](/category/ansible/), and [Cilium](/category/cilium/).
Stay with me till the end cause we got some cool stuff to cover.

## Prerequisites

Here are the list of CLI tools you need installed on your machine.

- [OpenTofu v1.6][opentofu-github]
- [Ansible v2.16][ansible-website]

## Step 0: Generate Hetzner API token

For the purpose of this tutorial, we'll only spin up a single server. However,
for production workloads, you should consider setting up a multi-node cluster
for high availability and fault tolerance. You will be guided with some of the
obvious tips at the end of this post.

First, you need to create an account on Hetzner Cloud[^2] and generate an API
token[^3]. Your generated token must have write access cause the TF files will
create resources on your behalf.

## Step 1: Create the server

Let us structure our project directory as follows:

```plaintext
.
├── ansible/
└── opentofu/
```

Now, let's pin the version for the required TF provider.

```hcl title="opentofu/versions.tf" hl_lines="19"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/demo/old-versions.tf"
```

???+ tip "Provider Versioning"

    The pinned version in this example is very loose. You might want to be more
    specific in scalable environments where you have multiple projects and need
    to ensure nothing breaks before you intentionally upgrade with enough tests.

    As an example, you can see the Rust infrastructure team[^4] being too
    conservative in their Ansible versioning as they don't want team members
    get caught off guard with a breaking change.

Notice that we have also created a variable to pass in the previously generated
Hetzner API token. This is a good practice to avoid hardcoding sensitive
information in your codebase.

To efficiently benefit from this technique, you can add the following lines
to your `.bashrc` file for all the future projects.

```shell title="~/.bashrc"
# ... truncated ...

export TF_VAR_hetzner_api_token="PLACEHOLDER"
```

Next, we'll define the creation of the Hetzner Cloud Server in our TF file.

```hcl title="opentofu/main.tf" hl_lines="7"
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

You might have noticed in line 7 that we are passing in a cloud-init[^5] file.
That's an important piece of the whole puzzle. Let's create that file.

???+ example "Generating SSH key pair"

    If you don't have an SSH key pair, you can generate one using the following
    command:

    ```shell title="Password-less elliptic curve key pair" linenums="0"
    ssh-keygen -t ed25519 -f ~/.ssh/k3s-cluster.hetzner -N ''
    ```

```yaml title="opentofu/cloud-init.yml" hl_lines="37-42"
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

### Explain the k3s installation

All the config in cloud-init file is self-explanatory. However, I'd like to
highlight a few important points.

{{ read_csv('docs/codes/0005-install-k3s-ubuntu/k3d-flags.csv') }}

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

### Step 1.1: Prepare Ansible Inventory

We will heavily rely on the SSH connections to the machine as the default way
of connection for Ansible. Therefore, to make that access easier and
password-less, we gotta take two steps:

1. Prepare the SSH config file
2. Prepare the Ansible inventory file

Let's start with the SSH config file.

```ssh title="~/.ssh/config"
# ... truncated ...

Host k3s-cluster.hetzner
  User k8s
  IdentityFile ~/.ssh/k3s-cluster.hetzner # location of `ssh-keygen` command
```

Now, let's prepare the Ansible inventory file using the `yaml` plugin of
Ansible inventory.

```yaml title="ansible/inventory.yml"
-8<- "docs/codes/0005-install-k3s-ubuntu/ansible/inventory.yml"
```

## Step 2: Bootstrap the cluster

So far, we have provisioned the cluster using OpenTofu. But, if you SSH into
the machine, `kubectl get nodes` will return a `NotReady` state for your node.
That is because of the absence of a CNI plugin in the cluster.

It's time to use Ansible to take care of that, although, arguably, we could
have done that in the cloud-init file as well.

But, using Ansible gives more flexibility and control over the steps involved
and it will make it reproducible upon future invocations.

```yaml title="ansible/playbook.yml" hl_lines="23-24 39-40"
-8<- "docs/codes/0005-install-k3s-ubuntu/ansible/playbook.yml"
```

As you see in the highlighted lines, we will use Kubernetes Gateway API[^6] as
a replacement for Ingress Controller. This is a more modern approach and it
has more capabilities than the traditional Ingress Controller.

Among many other benefits, Gateway API has the ability to handle TLS, gRPC, and
WebSockets, which are not supported by Ingress Controller.

???+ quote "Why Gateway API?"

      These days I will use Gateway API for all my Kubernetes clusters, unless I have
      a specific requirement that mandates the use of Ingress Controller.

Cilium has native support[^7] for Gatway API.

To run this ansible playbook, I will simply run the following command:

```shell title="" linenums="0"
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -v
```

You might as well ignore that last `-v` flag, but I like to see the output of
the playbook as it runs.

???+ success "Ansible Configuration"

      In fact, I have a global user configuration that has some sane defaults.
      Completely contradictory to what the Ansible *sane* defaults are.

      ```ini title="~/.ansible.cfg"
      -8<- "docs/codes/0005-install-k3s-ubuntu/ansible/ansible.cfg"
      ```

## Step 3: Use the Cluster

We have done all the heavy lifting thus far and now it's time to use the
cluster.

For that, you can either use `scp` or `rsync` to fetch the `~/.kube/config`
into your local machine, or use the `kubectl` command right from the remote
server.

I generally prefer the former as I believe the control machine is my localhost
and everything else is a remote machine that hosts the workload I command it to.

**NOTE**: In the case where you copy the remote Kubeconfig file to your local
machine, you will need to update the `server` field in the `~/.kube/config` file
as it is pointing to the `127.0.0.1` by default.

```yaml title="~/.kube/config" hl_lines="5"
-8<- "docs/codes/0005-install-k3s-ubuntu/kubeconfig"
```

## Step 4: Protect the Server

Since exposing the Kubernetes API server means the cluster shall be
internet-accessible, I, as a security-conscious person, would protect my server
with the help of firewall.

That said, I would, as a last step, deploy the **free** Hetzner
Cloud Firewall to protect my server.

```hcl title="opentofu/versions.tf" hl_lines="7-10"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/versions.tf"
```

```hcl title="opentofu/network.tf" hl_lines="11 17-19"
-8<- "docs/codes/0005-install-k3s-ubuntu/opentofu/network.tf"
```

## Bonus: Multi-Node Cluster

When planning to go for production in this setup, you are advised to go for a
multi-node deployment for high availability and fault tolerance.

To achieve that, you can pass the `K3S_URL`[^8] and `K3S_TOKEN` to the cloud-init
script for any of the worker nodes.

## Source Code

All the code examples in this post are publicly available[^9] on GitHub under the
[Apache 2.0 license][license].

[^1]: https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster
[^2]: https://accounts.hetzner.com/login
[^3]: https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/
[^4]: https://github.com/rust-lang/simpleinfra/blob/e361f222bc377434d06d53add6827bd24a3a5d89/ansible/apply#L13:L15
[^5]: https://cloudinit.readthedocs.io/en/latest/topics/format.html
[^6]: https://gateway-api.sigs.k8s.io/
[^7]: https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
[^8]: https://docs.k3s.io/cli/agent#cluster-options
[^9]: https://github.com/developer-friendly/blog/tree/main/docs/codes/0005-install-k3s-ubuntu

[license]: https://github.com/developer-friendly/blog/tree/main/LICENSE
[opentofu-github]: https://github.com/opentofu/opentofu
[ansible-website]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
[k8s-the-hard-way]: ./0003-kubernetes-the-hard-way.md
