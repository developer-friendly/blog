---
date: 2024-04-22
draft: true
categories:
  - Kubernetes
  - AWS
  - OpenTofu
  - OpenID Connect
links:
  - ./posts/0007-oidc-authentication.md
  - ./posts/0005-install-k3s-on-ubuntu22.md
  - ./posts/0003-kubernetes-the-hard-way.md
---

# Grant Kubernetes Pods Access to AWS Services Using OpenID Connect

Learn how to establish a trust relationship between a Kubernetes cluster and
AWS IAM to grant cluster generated Service Account tokens access to AWS
services using OIDC & without storing long-lived credentials.

<!-- more -->

## Introduction

In our [previous post](./0007-oidc-authentication.md), we discussed what
OpenID Connect (OIDC) is and how to use it to authenticate identities from one
system to another.

We covered why it is crucial to avoid storing long-lived
credentials and the benefits of employing OIDC for the task authentication.

If you haven't read that one already, here's a recap:

- [x] OIDC is an authentication protocol that allows the identities in one system
      to authenticate to another system.
- [x] It is based on OAuth 2.0 and JSON Web Tokens (JWT).
- [x] Storing long-lived credentials is risky and should be avoided.
- [x] OIDC provides a secure way to authenticate identities without storing
      long-lived credentials.
- [x] It is widely used in modern applications and systems.
- [x] The hard requirements is that both the Service Provider and the Identity
      Provider must be OIDC compliant.

We also covered a practical example of authenticating GitHub runners to AWS IAM
by establishing a trust relationship between GitHub and AWS using OIDC.

In this post, we will take it one step further and provide a way for the pods
of our Kubernetes cluster to authenticate to AWS services using OIDC.

This post will provide a walkthrough of granting such access to a
bear-metal Kubernetes cluster (k3s) using only the power of OpenID Connect
protocol. In a later post, we'll show you how easy it is to achieve the same
with a managed Kubernetes cluster like Azure Kubernetes Service (AKS). But, first
let's understand the fundamentals by trying it on a bear-metal cluster.

We will not store any credentials in our pods and as such, won't ever have to
worry about other security concerns such as secret rotations!

With that intro out of the way, let's dive in!

## Prerequisites

Make sure you have the following prerequisites in place before proceeding:

- [x] A Kubernetes cluster that can be exposed to the internet. (1)
{ .annotate }

    1.  A local Kubernetes cluster will do, however, you will need to expose
        the required endpoints to the internet. This can be done using a
        service like [ngrok](https://ngrok.com/).

        Not the topic of today's post!

- [x] An AWS account to create an OIDC provider and IAM roles.
- [x] A verified root domain name that YOU own. Skip this if you're using a
      managed Kubernetes cluster.

## Roadmap

Let's see what we are trying to achieve in this guide.

Our end goal is to create an [Identity Provider (IdP)][aws-create-idp] in AWS.
After doing so, we will be able to create an IAM Role with a trust relationship
to the IdP.

Ultimately, the pods in our Kubernetes cluster that have the
desired Service Account(s) will be able to talk to the AWS services.

To achieve this, and as per the OIDC specification, the following endpoints
must be exposed through an
[HTTPS endpoint with a verified TLS certificate][oidc-tls]:

- `/.well-known/openid-configuration`: This is a MUST for OIDC compliance.
- `/openid/v1/jwks`: This is configurable through the first endpoint as you'll
  see later.

These endpoints provide the information of the OIDC provider and the public
keys used to sign the JWT tokens, respectively. The former will be used by the
service provider to ^^validate the OIDC provider^^ and the latter will be used
to ^^validate the JWT access tokens^^ provided by the entities that want to
talk to the Serivce Provider.

!!! tip "Service Provider"

    Service Provider refers to the host that provides the service. In our
    example, AWS is the service provider.

Exposing such endpoints will make our OIDC provider compliant with the OIDC
specification. In that regard, any OIDC compliant service provider will be able
to trust our OIDC provider.

!!! tip "OIDC Compliant"

    For an OIDC provider and a Service Provider to trust each other, they must
    be OIDC compliant. This means that the OIDC provider must expose certain
    endpoints and the Service Provider must be able to validate the OIDC
    provider through those endpoints.

In practice, we will need the following two absolute URLs to be accessible
publicly through internet with a verified TLS certificate signed by a trusted
Certificate Authority (CA):

- `https://mydomain.com/.well-known/openid-configuration`
- `https://mydomain.com/openid/v1/jwks`

Again, and just to reiterate, as per the OIDC specification the HTTPS is a must
and the TLS certificate has to be verified by a trusted Certificate
Authority (CA).

When all this is set up, we shall be able to add the `https://mydomain.com` to
the AWS as an OIDC provider.

## Step 1: Dedicated Domain Name

As mentioned, we need to assign a dedicated domain name to the OIDC provider.
This will be the address we will add to the AWS IAM as an Identity Provider.

Any DNS provider will do, but for our example, we're using Cloudflare.

```hcl title="variables.tf"
-8<- "docs/codes/0008/v0/variables.tf"
```

```hcl title="versions.tf"
-8<- "docs/codes/0008/v0/versions.tf"
```

```hcl title="network.tf"
-8<- "docs/codes/0008/network.tf"
```

```hcl title="dns.tf"
-8<- "docs/codes/0008/dns.tf"
```

```hcl title="outputs.tf"
-8<- "docs/codes/0008/v0/outputs.tf"
```

We would need the required access token which you can get from their respective
account settings.

```shell title="" linenums="0"
export TF_VAR_cloudflare_api_token="PLACEHOLDER"
export TF_VAR_hetzner_api_token="PLACEHOLDER"

tofu plan -out tfplan
tofu apply tfplan
```

## Step 2: A Live Kubernetes Cluster

At this point, we should have a live Kuberntes cluster. We've already covered
[how to set up a lightweight Kubernetes cluster on an Ubuntu 22.04 machine](./0005-install-k3s-on-ubuntu22.md)
before and so, we won't go too deep into it.

But for the sake of completeness, we'll resurface the code one more time, with
some minor tweaks here and there.

```hcl title="variables.tf" hl_lines="28-36"
-8<- "docs/codes/0008/variables.tf"
```

```hcl title="versions.tf" hl_lines="15-22"
-8<- "docs/codes/0008/versions.tf"
```

```hcl title="server.tf"
-8<- "docs/codes/0008/server.tf"
```

```hcl title="firewall.tf"
-8<- "docs/codes/0008/firewall.tf"
```

```hcl title="outputs.tf" hl_lines="9-24"
-8<- "docs/codes/0008/outputs.tf"
```

Business as usual, we apply the stack as below.

```shell title="" linenums="0"
tofu plan -out tfplan
tofu apply tfplan
```

And for connecting to the machine:

```shell title="" linenums="0"
tofu output -raw ssh_private_key > ~/.ssh/k3s-cluster
chmod 600 ~/.ssh/k3s-cluster

IP_ADDRESS=$(tofu output -raw public_ip)
ssh -i ~/.ssh/k3s-cluster k8s@$IP_ADDRESS
```

To be able to use the Ansible playbook in the next steps, we shall write the
inventory where Ansible expects them.

??? example "ansible.cfg"
    ```ini title="" hl_lines="8"
    -8<- "docs/codes/0008/ansible.cfg"
    ```

```shell title="" linenums="0"
mkdir ./inventory
tofu output -raw ansible_inventory_yaml > ./inventory/k3s-cluster.yml
```

??? example "ansible-inventory --list"
    ```json title=""
    -8<- "docs/codes/0008/outputs/ansible-inventory-list.json"
    ```

At this stage we're ready to move on to the next step.

## Step 3: Bootstrap the Cluster

At this point we have installed the Cilium binary in our host machine, yet we
haven't installed the CNI plugin in our Kubernetes cluster.

Let's create an Ansible role and a playbook to take care of all the Day 1 operations.

```shell title="" linenums="0"
ansible-galaxy init k8s
touch playbook.yml
```

The first step is to install the Cilium CNI.

```yaml title="k8s/defaults/main.yml"
-8<- "docs/codes/0008/v1/k8s-defaults-main.yml"
```

```yaml title="k8s/tasks/cilium.yml"
-8<- "docs/codes/0008/k8s/tasks/cilium.yml"
```

```yaml title="k8s/tasks/main.yml"
-8<- "docs/codes/0008/v1/k8s-tasks-main.yml"
```

```yaml title="playbook.yml"
-8<- "docs/codes/0008/playbook.yml"
```

To run the playbook:

```shell title="" linenums="0"
ansible-playbook playbook.yml
```

## Step 4: Fetch the TLS Certificate

At this point, we need a CA verified TLS certificate for the domain name we
created in the first step.

We will carry our tasks with Ansible throughout the entire Day 1 to Day n
operations.

```yaml title="k8s/tasks/certbot.yml"
-8<- "docs/codes/0008/k8s/tasks/certbot.yml"
```

```yaml title="k8s/tasks/main.yml" hl_lines="5-7"
-8<- "docs/codes/0008/k8s/tasks/main.yml"
```


<!--
## Step 1: Publicly Accessible Domain Name

Now that we have a Kubernetes cluster, it's time to create a domain name that
points to the public IP address of the machine hosting the cluster.

```hcl title="versions.tf" hl_lines="15-22 26-28"
-8<- "docs/codes/0008/versions.tf"
```

```hcl title="variables.tf" hl_lines="17-26"
-8<- "docs/codes/0008/variables.tf"
```

```hcl title="dns.tf"
-8<- "docs/codes/0008/dns.tf"
```

In this example we are using Cloudflare as the DNS provider. You can use any
other DNS provider of your choice.

```shell title=""
export TF_VAR_cloudflare_api_token="PLACEHOLDER"
tofu plan -out tfplan
tofu apply tfplan
```
 -->

<!--
## Step 2: Fetch the OIDC Configurations

As mentioned in the [Roadmap](#roadmap), we need to expose the following two
endpoints:

- `/.well-known/openid-configuration`
- `/openid/v1/jwks`

The Kubernetes API server exposes these two endpoints on its own.

To try them out, you can use the following commands:

```shell title=""
kubectl get --raw /.well-known/openid-configuration
kubectl get --raw /openid/v1/jwks
```

However they are not accessible to anonymous users by default.

Additionally, it is generally frowed upon to expose the API server to the
internet as it may expose you to obvious security risks.

For those reasons, we will try to treat the API server and the OIDC provider as
two separate entities; keeping the API server in its own protected network and
exposing the OIDC provider to the internet.

In our one-node example, they are
on the same node, however, with this approach, we can easily separate them in
a real-world scenario.

There are countless ways we can achieve this, HAProxy and other reverse proxies
are some of the most popular ones.

We are aiming for simplicity in this guide. Therefore, we will use a simple
static web server to serve the OIDC configurations.

The idea is to receive the configurations with the `kubectl` command, save those
files and serve them with an static web server.

So, in a nutshell, this is what we'll do:

```shell title=""
mkdir -p .well-known/ openid/v1/

kubectl get --raw /.well-known/openid-configuration > .well-known/openid-configuration
kubectl get --raw /openid/v1/jwks > openid/v1/jwks
```

After this point, any static web server can do. You can use `serve`, Python's
`http.server`, or any other static web server.

In our guide, we will use [`static-web-server`][static-web-server]



## Step 1: TLS Certificates

We will need a verified TLS certificate for the domain name that we will use to
expose the OIDC endpoints. This is the domain name that we own and will use to
create the trusted identity provider in AWS.

```hcl title="versions.tf"
-8<- "docs/codes/0008/versions.tf"
```

```hcl title="variables.tf"
-8<- "docs/codes/0008/variables.tf"
```

```hcl title="main.tf"
-8<- "docs/codes/0008/main.tf"
```

```hcl title="output.tf"
-8<- "docs/codes/0008/output.tf"
```

This example assumes you have only one public IP addressfor the machine hosting
the


[aws-create-idp]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
[oidc-tls]: https://openid.net/specs/openid-connect-core-1_0.html
[static-web-server]: https://static-web-server.net/
 -->

<!--
important keyworkds:
AWS
kubernetes
pods
OpenID Connect

bare-metal
Azure
ts
service account
K3s

OIDC
IAM
trust relationship
 -->

<!--
# for aks
az aks show -n lware-dev-aks -g lware-dev-rg --query "oidcIssuerProfile.issuerUrl" -otsv

add that to AWS as OIDC and specify the audience appropriately

# for bear metal
you need a way to expose /.well-known/openid-configuration and /openid/v1/jwks
one of the simplest and tiniest way is to use static-web-server
you need a verified tls signed by a trusted CA
serving those OIDC files should be behind the said static server with the aforementioned tls
finally, the AWS IAM role looks like the following:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::591342154473:oidc-provider/4f0fce7c-9efa-9ee3-5fe0-467d95d2584c.developer-friendly.blog"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "4f0fce7c-9efa-9ee3-5fe0-467d95d2584c.developer-friendly.blog:aud": "sts.amazonaws.com",
                    "4f0fce7c-9efa-9ee3-5fe0-467d95d2584c.developer-friendly.blog:sub": "system:serviceaccount:default:default"
                }
            }
        }
    ]
} -->

<!--
high level structure for this document:
1. [x] refer to the previous post
2. [x] recap the most important points
3. [x] specify the OIDC compliance through exposing certain endpoints
4. how to achieve that in a bare-metal cluster
   1. [x] A domain name mapped to the VM IP address
   2. [x] a live k8s cluster
   3. [ ] fetch tls certificate using certbot
   4. [ ] fetch OIDC config and jwks and write them to disk
   5. [ ] start the static web server using that tls
5. add the OIDC to AWS
6. add the IAM role with the trust relationship to the OIDC provider
7. test the setup with a sample pod with and without SA attached
-->
