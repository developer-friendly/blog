---
date: 2024-04-29
draft: true
description: >-
  Get started with External Secrets Operator in Kubernetes to fetch secrets
  from external secrets management systems using OpenID Connect & IAM trust
  relationship.
categories:
  - Kubernetes
  - External Secrets
  - AWS
  - AKS
  - OpenID Connect
  - OpenTofu
  - Azure
  - Ansible
  - Cilium
  - OAuth2
  - Authentication
  - OIDC
  - Security
  - Cloud Computing
  - IaC
  - GitOps
  - FluxCD
links:
  - ./posts/0007-oidc-authentication.md
  - ./posts/0005-install-k3s-on-ubuntu22.md
  - ./posts/0003-kubernetes-the-hard-way.md
  - ./posts/0008-k8s-federated-oidc.md
  - ./posts/0002-external-secret-immutable-target.md
  - ./posts/0006-gettings-started-with-gitops-and-fluxcd.md
---

# External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS

<!--
high priority keywords to aim for in the SEO optimization tactics:
- Kubernetes
- External Secrets Operator
- AWS
- AKS
- OpenID Connect

optional:
- Azure
- AWS IAM
- IAM Role
- AWS SSM Parameters
-->

How to pass your secrets to the Kubernetes cluster without hard-coding them
into your source code or manually creating the Kubernetes Secret resource.

<!-- more -->

<!--
high level overview:

1. setting up azure aks with TF module
2. establishing a trust relationship using OIDC with AWS IAM
3. creating two IAM roles for external secrets operator (read and write)
4. test the set up by creating ExternalSecret and PushSecrets
-->

## Introduction

Deploying an application rarely is just the application itself. It is usually
all the tooling and infrastructure around it that makes it work and produce
the value it was meant to.

One of the most common things that applications need is secrets. Secrets are
sensitive information that the application needs to function properly. This
can be database passwords, API keys, or any other sensitive information the
app uses to function and communicate with all the relevant external services.

In Kubernetes, the most common way to pass secrets to the application is by
creating a [Kubernetes Secret resource]. This resource is a Kubernetes object
that stores sensitive information in the cluster. The application can then
access this information by mounting the secret as a volume or by using
environment variables.

However, creating a Kubernetes Secret resource manually is a tedious task,
especially when working at scale. Not to mention the maintenance required to
rotate the secrets periodically and keep them in sync with the upstream.

On the other hand, passing secrets as hard-coded and plaintext value is a no-no
when it comes to security. As much of a common sense as it is, going around the
industry and seeing how people hard-code their secrets into the source code
pains my soul.

In this article, we will explore how to use the
[External Secrets Operator][external-secret] to
pass secrets to the Kubernetes cluster without hard-coding them into your
source code or manually creating the Kubernetes Secret resource.

## Roadmap

Before we start, let's set a clear objective of what we want to achieve in
this article.

First off, we'll create an Azure AKS Kubernetes cluster using the
[OpenTofu](/category/opentofu) module. The AKS cluster will have its OpenID
Connect endpoint exposed to the internet.

We will use that OpenID Connect endpoint to establish a trust relationship
between the Kubernetes cluster and the AWS IAM, leveraging
[OpenID Connect](/category/openid-connect). This trust relationship will
allow the Kubernetes cluster's Service Accounts to assume an IAM Role with
web identity to access AWS resources.

Afterwards, we will deploy the External Secrets operator in the Kubernetes
cluster passing the right Service Account to its running pod so that it can
assume the proper [AWS IAM Role].

With that set up, the External Secrets operator will be able to read the
secrets from the AWS SSM Parameter Store and create Kubernetes Secrets from
them.

At this point, any pod in the same namespace as the target Secret will be able
to mount and read its values business as usual.

Optionally, we'll also cover how to allow the External Secrets operator to
write back to the AWS SSM Parameter Store the values of the Kubernetes Secrets
we want it to. An example include deploying a database with a generated
password and storing that password back in the AWS SSM Parameter Store for
references by other services or applications.

!!! success "OpenID Connect"

      OpenID Connect, in simple terms, is a protocol that allows one service
      to authenticate and authorize another service, optionally on behalf of
      a user. It is an authentication layer on top of OAuth2.0 protocol.

      If you're new to the topic, we have a practical example to solidify your
      understanding in our guide on
      [OIDC Authentication](./0007-oidc-authentication.md).

With that said, let's get started!

!!! question "Why AWS SSM instead of Azure Key Vault?"

      The External Secrets operator supports multiple backends for storing
      secrets. One of the most common backends is the AWS SSM Parameter Store.
      It is easy to set up, free to use, and has the least amount of drama
      around it.

      However, I'm not here to dictate what you should and shouldn't use in
      your stack. If Azure Key Vault works for you, by all means, go for it.
      Choosing a tech stack goes beyond just how sexy it looks on the resume,
      or how fun of a Developer Experience it provides!

## Prerequisites

Before we start, you need to have the following prerequisites:

<div class="annotate" markdown>
- [x] A Kubernetes cluster v1.29-ish. Feel free to follow earlier guides to
      set up the Kubernetes cluster [the Hard Way](./0003-kubernetes-the-hard-way.md)
      or [using k3s](./0005-install-k3s-on-ubuntu22.md). Although we'll spin
      up a new Kubernetes cluster using [Azure AKS TF module][aks-tf-mod].
- [x] Internet accessible endpoint to your Kubernetes API server (1). We have
      covered [how to expose your Kubernetes API server](./0008-k8s-federated-oidc.md)
      in last week's guide. Azure AKS, however, comes with a public
      [OpenID Connect](/category/openid-connect) endpoint [by default][aks-oidc].
- [x] An AWS account with the permissions to read and write SSM parameters and
      to create OIDC provider and IAM roles.
- [ ] Optionally, FluxCD installed in your cluster. Not required if you aim to
      use bare Helm commands for installations. There is a beginner friendly
      [guide to FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md)
      in our archive if you're new to the topic.
</div>

1. You're free to run a local Kubernetes cluster and expose it to the internet
   using tools like [ngrok][ngrok] or [telepresence][telepresence].

## Step 0: Setting up Azure Managed Kubernetes Cluster

First things first, let's set up the Azure AKS Kubernetes cluster using the
official TF module.

```hcl title="aks/variables.tf"
-8<- "docs/codes/0009/aks/variables.tf"
```

```hcl title="aks/versions.tf"
-8<- "docs/codes/0009/aks/versions.tf"
```

```hcl title="aks/main.tf"
-8<- "docs/codes/0009/aks/main.tf"
```

```hcl title="aks/outputs.tf"
-8<- "docs/codes/0009/aks/outputs.tf"
```

!!! bug "`azapi` signing key"

      As of the writing of this blog post, there is a bug in the `azapi` TF
      provider that causes the `tofu init` to fail cause of a
      [changed signing key].

We would normally use `tofu` for the task, as per our tradition in this blog.
But because of this bug, and because we can't wait for the world to fix itself
before publishing our next article, we'll compromise on `terraform` just for
this one time. :sweat: :grimacing:

Having this TF code, we now need to apply it to our Azure account.

### Authenticating to Azure

The first requirement is to be authenticated to Azure API. There are more than
one ways to [authenticate to Azure]. The most common way, and the one we'll use
today, is by [authenticating to Azure CLI].

???+ example "Authenticate to Azure Using AZ CLI"

      For your reference, here's a quick way to authenticate to Azure:

      ```shell title="" linenums="0"
      az login --use-device-code
      ```

      This command will print out a URL and a code. Open the URL in your
      browser and enter the code when prompted. This will authenticate you to
      Azure CLI.

Once authenticated, and if the default subscription and tenant-id is not set,
you can set them as environment variables just like the following:

```shell title="" linenums="0"
export ARM_SUBSCRIPTION_ID=159f2485-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export ARM_TENANT_ID=72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Applying the TF Code

Lastly, once all is set, you can apply the TF code to create the AKS cluster.

```shell title="" linenums="0"
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

This shall take about ~20 minutes to complete. Once done, you should have a
fully functional Azure AKS cluster with the OpenID Connect endpoint exposed
to the internet.

The output of this TF code will, as specified in our code, be an OIDC issuer
URL. We are going to use this URL to establish a trust relationship between
the Kubernetes cluster and the AWS IAM in the next step.

To get the [kubeconfig file], you can run the following command:

```shell title="" linenums="0"
az aks get-credentials \
  --resource-group developer-friendly-aks \
  --name developer-friendly-aks --admin
```

This will add or update your current kubeconfig file with the new AKS cluster
credentials. We will use this in a later step.

## Step 1: Establishing Azure AKS Trust Relationship with AWS IAM

This step aims to facilitate and enable the API calls from the pods inside the
Kubernetes cluster to the AWS services.
[As we have seen earlier](./0008-k8s-federated-oidc.md), this is what
OpenID Connect is all about.

Let's write the TF code to create the OIDC provider in the AWS.

```hcl title="aws-oidc/variables.tf"
-8<- "docs/codes/0009/aws-oidc/variables.tf"
```

```hcl title="aws-oidc/versions.tf"
-8<- "docs/codes/0009/aws-oidc/versions.tf"
```

```hcl title="aws-oidc/main.tf"
-8<- "docs/codes/0009/aws-oidc/main.tf"
```

```hcl title="aws-oidc/outputs.tf"
-8<- "docs/codes/0009/aws-oidc/outputs.tf"
```

The code should be self-explanatory, especially at this point after coverying
three blog posts on the topic of [OpenID Connect](/category/openid-connect).

But, let's emphasize the highlighting points:

1. When it comes to AWS IAM assume role, there are
   [five types of trust relationships]. In this scenario, we are using the
   [Web Identity trust relationship type].
2. Having the principal as `Federated` is just as the name suggests; it is
   a federated identity provider. In this case, it is the Azure AKS OIDC
   issuer URL. In simple english, it allows the Kubernetes cluster to sign
   the access tokens, and the AWS IAM will trust those tokens if signed by
   the specified Kubernetes cluster's OIDC issuer URL.
3. Having two conditionals on the audience (`aud`) and the subject (`sub`) allows
   for a tighter security control and to enforce the principle of least privilege.
   The target Kubernetes Service Account is the only one who is able to assume
   this IAM Role and is only capable of doing the permissions assigned, but no
   more. This enhances the overall security posture of the system.

Fortunately, there isn't any signing key issue with this TF provider. To apply
this, we can simply use `tofu`:

```shell title="" linenums="0"
tofu plan -out tfplan
tofu apply tfplan
```

### IAM Policy Document

You may have seen the IAM policy document as JSON string in the TF code. Truth
be told, there is no one-size-fits-all. Do whatever works best for you.

I prefer writing my IAM policy documents as TF code because every other code
in this module is written in HCL format. It is easier to maintain and read
when everything is in the same format and there will be less mental gymnastics
when a future engineer, or even myself, comes back to this code.

But, of course, I understand that when the IAM policy gets bigger, there is a
very good reason to write it in the JSON format.

For your reference, this is the equivalent TF code when writing it in the JSON
format:

```hcl title=""
-8<- "docs/codes/0009/junk/iam-role/main.tf"
```

## Step 2: Deploying External Secrets Operator

At its simplest form, you can easily install yours with `helm install`.
However, my preferred way of Kubernetes deployments is through GitOps, and
FluxCD is my go-to tool for that.

```yaml title="external-secrets/namespace.yml"
-8<- "docs/codes/0009/external-secrets/namespace.yml"
```

```yaml title="external-secrets/repository.yml"
-8<- "docs/codes/0009/external-secrets/repository.yml"
```

```yaml title="external-secrets/release.yml" hl_lines="31"
-8<- "docs/codes/0009/external-secrets/release.yml"
```

???+ example "Helm Values File"

      You don't have to necessarily commit the Helm values file into your
      source code. But it comes with a huge benefit when trying to upgrade to
      a newer version and you want to know what changes to expect during a
      code review.

      ```shell title="" linenums="0"
      helm show values \
         external-secrets/external-secrets \
         --version 0.9.x \
         > external-secrets/values.yml
      ```

      And the content:

      ```yaml title="external-secrets/values.yml"
      -8<- "docs/codes/0009/external-secrets/values.yml"
      ```

      We have covered the reason behind [volume projection] in our
      [last week's guide](./0008-k8s-federated-oidc.md). The gist of it is that we
      instruct Kubernetes issuer how to sign the access token and where to store it
      in the pod.

```yaml title="external-secrets/kustomizeconfig.yml"
-8<- "docs/codes/0009/external-secrets/kustomizeconfig.yml"
```

```yaml title="external-secrets/kustomization.yml" hl_lines="2"
-8<- "docs/codes/0009/external-secrets/kustomization.yml"
```

If you have set up your directory structure to be traversed in a recursive
fashion by FluxCD, you'd only push this to the upstream and the live state
will reconcile as specified.

Otherwise, apply the following manifest to create the FluxCD Kustomization:

```yaml title="external-secrets/kustomize.yml"
-8<- "docs/codes/0009/external-secrets/kustomize.yml"
```

## Step 3: Create the Secret Store

At this point, we should have a Kubernetes cluster with the External Secrets
operator running in it. It should also be able to assume the AWS IAM Role
we created earlier by leveraging the OIDC trust relationship.

In External Secrets operator, the `SecretStore` and `ClusterSecretStore` are
the proxies to the external secrets management systems. They are responsible
for fetching or creating the secrets from the external systems and creating
[the Kubernetes Secrets from them].

Let us create a `ClusterSecretStore` that will be responsible for fetching
or creating AWS SSM Parameters.


```hcl title="configure-secrets/variables.tf"
-8<- "docs/codes/0009/configure-secrets/variables.tf"
```

```hcl title="configure-secrets/versions.tf"
-8<- "docs/codes/0009/configure-secrets/versions.tf"
```

```hcl title="configure-secrets/main.tf" hl_lines="17-18"
-8<- "docs/codes/0009/configure-secrets/main.tf"
```

### Service Account Annotations Hack

You will notice that there are two annotations to the
`external-secrets` Service Account that are, suspiciously, sounding like an
AWS EKS Kubernetes cluster. That is, these are specifically the annotations
that only AWS EKS understands and acts upon.

This is an unfortunate mishap. If you're curious to read the full details,
I have provided a very long and detailed explanation in
[their GitHub repository's issue].

The gist of that discussion, if you're not feeling like reading my whole
rambling, is that the External Secrets operator is not able to assume IAM Role
with Web Identity outside the AWS EKS Kubernetes cluster; that is, you'll only
get the benefit of [OpenID Connect](/category/openid-connect) if
[only you're within AWS].

That is something I consider to be a bug! It shouldn't be the case and they
should be able to handle Kubernetes clusters where we wouldn't want to manually
pass the AWS credentials to the pods.

## Step 4: Test the Setup: Creating ExternalSecret and PushSecret

That's it guys!

We have done all the hard works and it's time for pay off. Let's create an
`ExternalSecret` and a `PushSecret` to test the setup.

In this step, as the tradition of this post has been, we won't go into sample
hello-world examples. We will try to deploy a MongoDB application instead.

The objective for this section is as follows:

1. Deploy a MongoDB application using Helm, pushing the auto-generated
   passwords to the AWS SSM Parameter Store using `PushSecret` CRD.
2. Deploy another application that uses the `ExternalSecret` CRD to fetch the
   newly created secret in AWS SSM Parameter Store and use it to connect to
   the MongoDB database.

If that gets you excited, let's get started! Although, I have to warn you, the
rest of this tutorial is a piece of cake compared to what we have done so far.


[external-secret]: https://external-secrets.io/v0.9.16/
[telepresence]: https://www.telepresence.io/
[ngrok]: https://ngrok.com/
[aws-ssm]: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
[aks-tf-mod]: https://registry.terraform.io/modules/Azure/aks/azurerm/8.0.0
[aks-oidc]: https://learn.microsoft.com/en-us/azure/aks/use-oidc-issuer
[Kubernetes Secret resource]: https://kubernetes.io/docs/concepts/configuration/secret/
[AWS IAM Role]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
[changed signing key]: https://github.com/Azure/terraform-provider-azapi/issues/477
[authenticate to Azure]: https://registry.terraform.io/providers/hashicorp/azurerm/3.101.0/docs#authenticating-to-azure
[authenticating to Azure CLI]: https://registry.terraform.io/providers/hashicorp/azurerm/3.101.0/docs/guides/azure_cli
[five types of trust relationships]: https://spacelift.io/blog/aws-iam-roles
[Web Identity trust relationship type]: https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role-with-web-identity.html
[kubeconfig file]: https://learn.microsoft.com/en-us/azure/aks/control-kubeconfig-access
[volume projection]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection
[their GitHub repository's issue]: https://github.com/external-secrets/external-secrets/issues/660#issuecomment-2080421742
[only you're within AWS]: https://external-secrets.io/v0.9.16/provider/aws-parameter-store/#eks-service-account-credentials
[the Kubernetes Secrets from them]: https://external-secrets.io/v0.9.16/api/clustersecretstore/
