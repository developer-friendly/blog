---
date: 2024-05-13
draft: true
description: >-
  TODO
categories:
  - Kubernetes
  - cert-manager
  - Cilium
  - Gateway API
  - External Secrets
  - FluxCD
  - OpenTofu
  - Terraform
  - GitOps
  - IaC
  - Infrastructure as Code
  - OAuth2
  - OpenID Connect
  - OIDC
  - Security
  - GitHub
---

# GitOps Continuous Deployment: FluxCD Advanced CRDs

FluxCD is a powerful GitOps ecosystem of operators that can be enabled
on-demand as per the requirement of your environment. It enables you to opt-in
for the features you need and to disable the ones you don't.

As the complexity and requirement of your environment grows, so does the need
for extra tooling to cover the implementation of the features you need.

FluxCD comes with more than just the support for Kustomization and HelmRelease.
With FluxCD, you can also manage your Docker images as new versions get built.
You can also get notified of the events that happen on your behalf by the
FluxCD operators.

Stick till the end to see how you can take your Kubernetes cluster to the next
level using advanced FluxCD CRDs.

<!-- more -->

## Introduction

We have covered the beginner's guide to FluxCD in
[an earlier post](./0006-gettings-started-with-gitops-and-fluxcd.md).

This blog post will continue from where we left off and covers the advanced
CRDs not included in the first post.

Specifically, we will mainly cover the [Source Controller] and the
[Notification Controller].

Using the provided CRDs by these operators, we will be able to achive the
following inside our Kubernetes cluster:

- [x] Fetch the latest tags of our specified Docker images
- [x] Update the [Kustomization] to use the latest Docker image tag based on
      the desired tag pattern
- [x] Notify and/or alert external services (e.g. Slack, Discord, etc.) based
      on the severity of the events happening within the cluster

If you're as pumped as I am, let's not waste any more seconds and dive right in!

## Pre-requisites

Make sure you have the following setup ready before going forward:

- [x] A Kubernetes cluster accessible from the internet (v1.30 as of writing)
      Feel free to follow our earlier guides if you need assistance:
    - [Kubernetes the Hard Way](./0003-kubernetes-the-hard-way.md)
    - [K3s Installation](./0005-install-k3s-on-ubuntu22.md)
    - [Managed Azure AKS](./0009-external-secrets-aks-to-aws-ssm.md)
- [x] FluxCD operator installed. Follow our earlier blog post to get started:
      [Getting Started with FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md)
- [x] Either [Gateway API] or an [Ingress Controller] installed in your cluster.
      We will need this internet-accessible endpoint to receive the webhooks
      from the GitHub repository to our cluster.
- [x] [GitHub CLI v2 installed]
- [ ] Optionally a GitHub account, although any other Git provider will do when
      it comes to the Source Controller.

## Source, Image Automation & Notification Controllers 101 :nerd:

Before getting hands-on, a bit of explanation is in order.

The Source Controller in FluxCD is responsible for fetching the artifacts and
the resources from the external sources. It is called **Source** controller
because it provides the resources needed for the rest of the FluxCD ecosystem.

These *Sources* can be of various types, such as GitRepository, HelmRepository
Bucket, etc. It will need the required auth and permission to access those
repositories, but, once given proper access, it will mirror the contents of
said sources to your cluster so that you can have seamless integration from
your external repositories right into the Kubernetes cluster.

The Image Autmation Controller is dedicated to managing the Docker images. It
fetches the latest tags, groups them based on defined patterns and criteria,
and updates the target resources (e.g. Kustomization) to use the latest image
tags.

The Notification Controller, on the other hand, is responsible for both
receiving and sending notifications. It can receive the events from the
[external sources, e.g. GitHub], and acts upon them as defined in its CRDs.
It can also send notification from your cluster to the external services.
This can include sending notifications or alerts to Slack, Discord, etc.

This is just an introduction and sounds a bit vague. So let's get hands-on and
see how we can use these controllers in our cluster.

## Application Scaffold

This is the not the most critical part of this post, but we will base our
examples on the following directory structure.

```plaintext title="" linenums="0"
.
├── fluxcd-secrets
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
└── kustomize
    ├── base
    │   ├── configs.env
    │   ├── deployment.yml
    │   ├── kustomization.yml
    │   └── service.yml
    └── overlays
        └── dev
            ├── externalsecret-docker.yml
            ├── externalsecret-gpgkey.yml
            ├── httproute.yml
            ├── imagepolicy.yml
            ├── imagerepository.yml
            ├── imageupdateautomation.yml
            └── kustomization.yml
```

The app can be anything you like. We're deploying a simple Rust application
with one endpoint.

## Step 1: Required Secrets

We will employ External Secrets Operator to fetch our secrets from AWS SSM.
We have already covered the [installation of ESO] in a previous post and using
that knowledge, we'll only need to place the secrets in the AWS, and instruct
the operator to fetch and feed them to our application.

```hcl title="fluxcd-secrets/variables.tf" hl_lines="47 52"
-8<- "docs/codes/0011/fluxcd-secrets/variables.tf"
```

```hcl title="fluxcd-secrets/versions.tf" hl_lines="23 27-28"
-8<- "docs/codes/0011/fluxcd-secrets/versions.tf"
```

```hcl title="fluxcd-secrets/main.tf"
-8<- "docs/codes/0011/fluxcd-secrets/main.tf"
```

```hcl title="fluxcd-secrets/outputs.tf"
-8<- "docs/codes/0011/fluxcd-secrets/outputs.tf"
```

Notice that we're defining two providers with [differing aliases]. For that,
there are a couple of worthy notes to mention:

1. We are using GitHub CLI for the API authentication OF our TF code to the
   GitHub. The main and default provider we use is `developer-friendly`
   organization and ther other is `developer-friendly-bot` normal user. You
   can easily switch profiles using `gh auth switch -u USERNAME` command.
2. The [GitHub Deploy Keys] creation API call is something even an organization
   username can do. But for the creation of the [User GPG Keys], we need to
   send the requests from a non-organization account, i.e., a normal user.
3. For the GitHub CLI authentication to work, beside the CLI installation, you
   need to grant your CLI in the terminal access to your GitHub account. You
   can see the command and the screenshot below.

```shell title="" linenums="0"
gh auth login --web --scopes admin:gpg_key
```

And the web browser page:

<figure markdown="span">
  ![GH CLI Auth](../static/img/0011/gh-cli-authentication.webp "Click to zoom in"){ loading=lazy }
  <figcaption>GitHub CLI Authentication</figcaption>
</figure>

Applying the stack above is straightforward:

```shell title="" linenums="0"
tofu init
tofu plan -out tfplan
tofu apply tfplan
```

## Step 2: Repository Set Up

Now that we have our secrets ready in AWS SSM, we can go ahead and create the
FluxCD GitRepository.

Remember we created GitHub Deploy Key earlier? We are passing it to the cluster
this way:

```yaml title="echo-server/externalsecret.yml" hl_lines="8"
-8<- "docs/codes/0011/echo-server/externalsecret.yml"
```

And using that generated Kubernetes Secret, we are creating the GitRepository
using SSH instead of HTTPS; the reason is that the Deploy Key has write access.
We'll talk about why in a bit.

```yaml title="echo-server/gitrepo.yml"
-8<- "docs/codes/0011/echo-server/gitrepo.yml"
```

```yaml title="echo-server/kustomization.yml"
-8<- "docs/codes/0011/echo-server/kustomization.yml"
```

And now let's create this stack:

```yaml title="echo-server/kustomize.yml"
-8<- "docs/codes/0011/echo-server/kustomize.yml"
```

```shell title="" linenums="0"
kubectl apply -k echo-server/kustomize.yml
```

## Step 3: Application Deployment

Now that we have our GitRepository set up, we can deploy the application.

There is not much to say about the `base` Kustomization. It is a normal
application like any other.

Therefore, let's go ahead and see what we need to create in our `dev` environment.

Notice the reference key name in our ExternalSecret resource which is targeting
the same value as we created earlier in our `fluxcd-secrets` TF stack.

```yaml title="kustomize/overlays/dev/externalsecret-docker.yml" hl_lines="8"
-8<- "docs/codes/0011/kustomize/overlays/dev/externalsecret-docker.yml"
```

```yaml title="kustomize/overlays/dev/externalsecret-gpgkey.yml" hl_lines="8"
-8<- "docs/codes/0011/kustomize/overlays/dev/externalsecret-gpgkey.yml"
```

```yaml title="kustomize/overlays/dev/httproute.yml"
-8<- "docs/codes/0011/kustomize/overlays/dev/httproute.yml"
```

The `PLACEHOLDER` in the following ImagePolicy will be replaced by the
Kustomization. Notice the pattern we are requesting, which **MUST be the same
as you build in your CI pipeline**.

```yaml title="kustomize/overlays/dev/imagepolicy.yml" hl_lines="10"
-8<- "docs/codes/0011/kustomize/overlays/dev/imagepolicy.yml"
```

The secret in the following ImageRepository will be fetched from AWS SSM by the
ESO and the corresponding Kubernetes Secret will be created in the cluster.

Creating an ImageRepository for a private Docker image is what I consider to
be a superset of the public ImageRepository. As such, I will only cover the
private ImageRepository in this blog post.

<div class="annotate" markdown>
Since the Git provider will be GitHub, we will need a GitHub PAT; I really
wish GitHub would provide official OpenID Connect support(1) someday to get rid
of all these tokens lying around in our environments! :face_with_head_bandage:
</div>

  1. There is an un-official OIDC support for GitHub as we speak:
     <https://github.com/octo-sts>

     A topic for a future post. :wink:

```yaml title="kustomize/overlays/dev/imagerepository.yml" hl_lines="6 10"
-8<- "docs/codes/0011/kustomize/overlays/dev/imagerepository.yml"
```

As before, the Kubernetes Secret holding the GPG key will be created by the ESO.
The following ImageUpdateAutomation resource will require the write access to
the repository we mentioned earlier. That's why the GitHub Deploy Key created
initial has the write access.

```yaml title="kustomize/overlays/dev/imageupdateautomation.yml" hl_lines="36"
-8<- "docs/codes/0011/kustomize/overlays/dev/imageupdateautomation.yml"
```

```yaml title="kustomize/overlays/dev/kustomization.yml" hl_lines="13"
-8<- "docs/codes/0011/kustomize/overlays/dev/kustomization.yml"
```

### Image Policy Tagging

Did you notice the line with the following *commented* value:

```json title="" linenums="0"
{"$imagepolicy": "default:echo-server:tag"}
```

Don't be mistaken! [This is not a comment]. This is a metadata that FluxCD
understands and uses to update the Kustomization `newTag` field with the latest
tag of a Docker image repository.

For your reference, here's the allowed references:

- `{"$imagepolicy": "<policy-namespace>:<policy-name>"}`
- `{"$imagepolicy": "<policy-namespace>:<policy-name>:tag"}`
- `{"$imagepolicy": "<policy-namespace>:<policy-name>:name"}`

To understand this better, let's take look at the created ImageRepository first:

```yaml title="" hl_lines="28 35"
-8<- "docs/codes/0011/junk/imagerepository.yml"
```

Out of all these scanned images, these are the ones that we care about in
our `dev` environment.

```yaml title="" hl_lines="29-30 35"
-8<- "docs/codes/0011/junk/imagepolicy.yml"
```

If you remember from our ImagePolicy, we have created the pattern so that the
Docker images are all having tags that are numerical only and the latest tag
is the one with the highest number.

Here's the snippet from the ImagePolicy again:

```yaml title="kustomize/overlays/dev/imagepolicy.yml" linenums="9" hl_lines="5"
-8<- "docs/codes/0011/kustomize/overlays/dev/imagepolicy.yml:9:13"
```

### GitHub CI Workflow

To elaborate further, this is the piece of GitHub CI definition that creates
the image with the exact tag that we are expecting:

```yaml title=".github/workflows/ci.yml" linenums="0" hl_lines="12"
-8<- "docs/codes/0011/junk/ci-workflow.yml:73:87"
```

This CI definition will create images as you have seen in the status of the
ImagePolicy, in the following format:

```plaintext title="" linenums="0"
ghcr.io/developer-friendly/echo-server:9044139623
```

You can employ other techniques as well. For example, you can use
[Semantic Versioning] as a pattern, and optionally exctact only a part of the
tag to be used in the Kustomization.

??? example "Full CI Definition"

      ```yaml title=".github/workflows/ci.yml"
      -8<- "docs/codes/0011/junk/ci-workflow.yml"
      ```




[Source Controller]: https://fluxcd.io/flux/components/source/
[Notification Controller]: https://fluxcd.io/flux/components/notification/
[Kustomization]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/
[Gateway API]: https://gateway-api.sigs.k8s.io/
[Ingress Controller]: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
[external sources, e.g. GitHub]: https://fluxcd.io/flux/components/notification/receivers/#type
[installation of ESO]: ./0009-external-secrets-aks-to-aws-ssm.md
[GitHub CLI v2 installed]: https://github.com/cli/cli/releases/tag/v2.49.1
[differing aliases]: https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations
[GitHub Deploy Keys]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys
[User GPG Keys]: https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account
[Semantic Versioning]: https://semver.org/
[This is not a comment]: https://fluxcd.io/flux/guides/image-update/#configure-image-update-for-custom-resources
