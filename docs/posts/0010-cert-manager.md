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
- [x] [OpenTofu v1.7]
- [ ] Although not required, we will use FluxCD as a GitOps approach for our
      deployments. You can either follow along and use the Helm CLI, or follow
      our earlier guide for
      [introduction to FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md).
- [ ] Optionally, External Secrets Operator installed. We will use it in this
      guide to store the credentials for the DNS01 challenge.
      - We have covered the installation of ESO in our last week's guide if
        you're new to it:
        [External Secrets Operator](./0009-external-secrets-aks-to-aws-ssm.md)

## Step 0: Installation

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

```shell title="" linenums="0"
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm show values jetstack/cert-manager > cert-manager/values.yml
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

## Step 1: Issuer

In general, you can fetch your TLS certificate in two ways: either by verifying
your domain using the HTTP01 challenge or the DNS01 challenge. Each have their
own pros and cons, but both are just to make sure that you own the domain you're
requesting the certificate for. Imagine a world where you could request a
certificate for `google.com` without owning it! :scream:

The HTTP01 challenge requires you to expose a specific path on your web server
for the CA to verify your domain. This is not always possible, especially if
you're running a private service or if you're using a managed service like
AWS ELB or Cloudflare.

On a personal note, the HTTP01 feels like a complete hack to me and not at all
standard. The feeling you get when you bypass a trivially best practice! :sweat:

As such, **in this guide, we'll use the DNS01 challenge**. This challenge
requires you to create a specific DNS record in your domain's DNS zone. That
said, you will need to have access to your domain's DNS zone to create the
record and grant cert-manager that level of access.

Providing access to cert-manager to create the DNS records is not mandatory and
you can do it on your own, though this beats the purpose of automation, where
you can sleep well knowing that your certificates will be renewed automatically
and on time without any manual intervention.

For the DNS01 challenge, there are a couple of supported DNS providers natively
by cert-manager. You can find the list of [supported providers on their website].

For the purpose of this guide, we will provide examples for two different DNS
providers: AWS Route53 and Cloudflare.

AWS services are the indudstry standard for many companies, and Route53 is one
of the most popular DNS services (fame where it's due). Cloudflare, on the other
hand, is handling a significant portion of the internet's traffic and is known
for its networking capabilities across the globe.

If you have other needs, you won't find it too difficult to find support for
your DNS provider in the cert-manager documentation.

### AWS Route53 Issuer

The [developer-friendly.blog] domain is hosted in Cloudflare and to demonstrate
the AWS Route53 issuer, we will make it so that a subdomain will be resolved
using Route53. That way, we can grab the TLS certificates later by cert-manager
using the DNS01 challenge from Route53.

<figure markdown="span" style="border: 1px solid #000">
   ![Nameservers](../static/img/0010/ns-providers.webp "Click to zoom in"){ loading=lazy }
   <figcaption>Nameserver Diagrams</figcaption>
</figure>


```hcl title="hosted-zone/variables.tf"
-8<- "docs/codes/0010/hosted-zone/variables.tf"
```

```hcl title="hosted-zone/versions.tf"
-8<- "docs/codes/0010/hosted-zone/versions.tf"
```

```hcl title="hosted-zone/main.tf"
-8<- "docs/codes/0010/hosted-zone/main.tf"
```

```hcl title="hosted-zone/outputs.tf"
-8<- "docs/codes/0010/hosted-zone/outputs.tf"
```

To apply this stack we'll use [OpenTofu](/category/opentofu). We could've either
separated the stacks to create the Route53 zone beforehand, or we will go ahead
and target our resources separately from command line as you see below.

```shell title=""
export AWS_PROFILE="PLACEHOLDER"

tofu plan -out tfplan -target=aws_route53_zone.this
tofu apply tfplan

# And now the rest of the resources

tofu plan -out tfplan
tofu apply tfplan
```

???+ question "Why Applying Two Times?"

      The values in a TF `for_each` must be known at the time of planning,
      [aka, static values].

      And since that is not the case with `aws_route53_zone.this.name_servers`,
      we have to make sure to create the Hosted Zone first before passing its
      output to another resource.

We should have our AWS Route53 Hosted Zone created as you see in the screenshot
below.

<figure markdown="span">
   ![AWS Route53](../static/img/0010/route53.webp "Click to zoom in"){ loading=lazy }
   <figcaption>AWS Route53</figcaption>
</figure>

Now that we have our Route53 zone created, we can proceed with the cert-manager
configuration.

#### AWS IAM Role

We now need an IAM Role with enough permissions to create the DNS records to
satisfy the DNS01 challenge.

```hcl title="route53-iam-role/variables.tf"
-8<- "docs/codes/0010/route53-iam-role/variables.tf"
```

```hcl title="route53-iam-role/versions.tf"
-8<- "docs/codes/0010/route53-iam-role/versions.tf"
```

```hcl title="route53-iam-role/main.tf"
-8<- "docs/codes/0010/route53-iam-role/main.tf"
```

```hcl title="route53-iam-role/outputs.tf"
-8<- "docs/codes/0010/route53-iam-role/outputs.tf"
```

```shell title="" linenums="0"
tofu plan -out tfplan
tofu apply tfplan
```

If you don't know what [OpenID Connect](/category/openid-connect) is and what
we're doing here, you might want to check out our ealier guides on the topic:

- [x] Establishing a trust relationship between
      [bare-metal Kubernetes cluster and AWS IAM](./0008-k8s-federated-oidc.md)
- [x] Same concept of trust relationship, this time between
      [Azure AKS and AWS IAM](./0009-external-secrets-aks-to-aws-ssm.md)

The gist of both articles is that we are providing a means for the two services
to talk to each other securely and without storing long-lived credentials.

In essence, one service will issue the tokens (Kubernetes cluster), and the
other will trust the tokens of the said service (AWS IAM).

#### Kubernetes Service Account

Now that we have our IAM role set up, we can pass that as an annotation to the
Service Account of the cert-manager Deployment. This way the cert-manager will
assume that role with the [Web Identity Token flow] (there are five in total).

We will also create a ClusterIssuer CRD to be responsible for fetching the TLS
certificates from the trusted CA.

```hcl title="route53-serviceaccount/variables.tf"
-8<- "docs/codes/0010/route53-serviceaccount/variables.tf"
```

```hcl title="route53-serviceaccount/versions.tf"
-8<- "docs/codes/0010/route53-serviceaccount/versions.tf"
```

```hcl title="route53-serviceaccount/main.tf"
-8<- "docs/codes/0010/route53-serviceaccount/main.tf"
```

```hcl title="route53-serviceaccount/outputs.tf"
-8<- "docs/codes/0010/route53-serviceaccount/outputs.tf"
```

```shell title="" linenums="0"
tofu plan -out tfplan
tofu apply tfplan
```

This stack allows the cert-manager controller to talk to AWS Route53.

Notice that we didn't pass any credentials, nor did we have to create any IAM
User for this communication to work. It's all the power of OpenID Connect and
allows us to establish a trust relationship and never have to worry about any
credentials in the client service. :white_check_mark:

[certbot]: https://certbot.eff.org/
[ingress]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[gateway]: https://gateway-api.sigs.k8s.io/
[cert-manager]: https://cert-manager.io/
[Operator pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[CNCF]: https://www.cncf.io/
[Kustomization resource]: https://fluxcd.io/flux/components/kustomize/kustomizations/
[Kubernetes Kustomize]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/
[supported providers on their website]: https://cert-manager.io/docs/configuration/acme/dns01/
[developer-friendly.blog]: https://developer-friendly.blog
[aka, static values]: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each#limitations-on-values-used-in-for_each
[OpenTofu v1.7]: https://github.com/opentofu/opentofu/releases/tag/v1.7.0
[Web Identity Token flow]: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html
[Kubernetes Reflector]: https://github.com/emberstack/kubernetes-reflector
