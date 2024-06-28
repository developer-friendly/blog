---
date: 2024-06-24
description: >-
  Master the art of efficient software development: A step-by-step guide to
  deploying preview environments for pull requests with GitHub Actions and Kubernetes.
social:
  cards_layout_options:
    description: >-
      Learn the secrets to faster code reviews: How to deploy individual
      preview environments for each pull request using GitHub Actions and
      Kubernetes.
categories:
  - GitHub Actions
  - Kubernetes
  - CI/CD
  - Code Review
  - DevOps
  - Automation
  - cert-manager
  - Cilium
  - Continuous Deployment
  - Continuous Integration
  - Docker
  - FluxCD
  - Gateway API
  - GitHub
  - GitHub Container Registry
  - GitOps
  - IaC
  - Infrastructure as Code
  - Kustomization
  - OAuth2
  - OIDC
  - OpenID Connect
  - Quality Assurance
  - Security
  - Software Development
  - Testing
  - TLS
  - Tutorial
links:
  - ./posts/2024/0014-github-actions-integration-testing.md
  - ./posts/2024/0011-fluxcd-advanced-topics.md
  - ./posts/2024/0004-github-actions-dynamic-matrix.md
image: assets/images/social/2024/06/24/how-to-set-up-preview-environments-for-pull-requests.png
---

# How to Set Up Preview Environments for Pull Requests

Have you ever been frustrated at long merge queues? Did you ever wish there was
a better and faster way to get feedback on your code changes and approval from
your team members?

You may have also been on the other side of the table, reviewing pull requests
and wishing there was a better way to actually test the revisions before
approving it; giving you a sense of what it would feel and look like if it were
to merge.

Netlify and other frontend hosting services have spoiled us with the ability to
spin up a live instance of the application for each pull request for static
files. But what about backend applications? How can we achieve the same and
deploy our backend for every new proposed change in pull requests?

In this blog post, we will explore how to set up preview environments for each
pull request using GitHub Actions and Kubernetes. This guide includes spinning
up the application as a live instance with an internet accessible URL to
preview and verify the changes before they find their way into the main trunk.

<!-- more -->

## Introduction

When working in a team environment, it's common to adopt the pull-request style
for collaborations. This ensures that the quality of the codebase is maintained
having some guardrails to avoid merging changes that are undesired and/or do
not meet a certain standard of the team.

This process can become tedious, especially at scale and working with more than
a few team members. Although there are tools and practices to help with the
coordination and overhead associated with code reviews, there is still an
ongoing maintainance cost when it comes to keeping up with the flow and pace
of changes proposed to the codebase, i.e., pull requests.

One of the main reasons code reviews are tough to deal with is the efforts
required to spin up the application as proposed in the pull request. Any of the
modern day applications today depend on many services, e.g., databases, caches,
queues, etc.

Not only that it is not easy to set up all these dependencies right out of the
box, the communication between the application and these services is often a
giant undertaking on its own, perhaps nothing less than setting up a full
production environment; we all know how cumbersome that can be due to the
planning and operational mindset required.

Furthermore, the application and all its dependent services need computation
power and resources to run. This is challenging when your production
environment is working at scale of a country, continent, or even the world.
Imagine having to deploy Zookeeper, Kafka, and Cassandra locally just to test a
small change in the application. It's not only time-consuming but also resource
intensive.

That is where the preview environments come into play. It allows you to see the
live state of the application as proposed in the pull request, with all the
bells and whistles, without having to set up the environment yourself.

<!-- subscribe -->

## What is a Preview Environment?

A preview environment is a live instance of the application that is spun up
after each push to the pull request branch. This environment is usually an
identical copy of the dev or ideally prod environment with all the services and
dependencies that the application relies on. If the application needs to talk
to a database or the cache system, those communications are also set up in the
preview environment.

The whole point of preview environments is to help the author of the pull
request and other team members to see the application as it would look like if
the changes were to merge. This helps in speeding up the feedback loop and the
approval process, as the reviewers can see the changes in action and verify
that they are desirable.

What's more, the preview environment helps reduce the procrastination factor to
zero, not requiring any of the reviewers to go through the manual labor of
pulling the changes and setting up the environment locally to see the new
state of the application. As a result, the feedback loop is shortened and the
merge queue less congested.

To help better replicate the production environment, the preview environment is
usually designed in a way that closely resembles that environment, or at least
as close as possible. This ensures there is no surprises when the pull requests
are merged and the regressions are minimized.

To help with the cost optimizations, there is the possibility of sharing the
services and dependencies between the preview environment and the dev
environment. Sharing it with the prod, however, is way too risky and outweights
the benefits; any proposed change in the pull request is error prone and
susceptible to bugs and regressions that can have an unpredictable impact to
your end-users.

```mermaid
flowchart TB
    mainBranch[Main Branch]
    pullRequestBranch[Pull Request Branch]

    mainBranch -->|checkout -b| pullRequestBranch

    subgraph devEnv["Live Dev Environment"]
        liveDevInstance(["app.example.com"])
    end

    subgraph previewEnv["Preview Environment"]
        previewInstance(["pr123.test.example.com"])
    end

    subgraph dbEnv["Dev Dependencies"]
        postgresDB[(PostgreSQL Database)]
    end

    liveDevInstance -->|Connects to| postgresDB
    previewInstance -->|Connects to| postgresDB

    mainBranch -->|Deploys to| devEnv
    pullRequestBranch --> previewEnv

    classDef dottedBox fill:none,stroke-dasharray: 5 5;
    class devEnv,previewEnv,dbEnv dottedBox;
```

Additionally, depending on the structure and deployment of the dev or prod
environment, the preview environment is accessible from the internet using a
unique URL, e.g., `pr123.test.example.com`.

Having an internet-accessible endpoint allows other team members to test,
review and verify the proposed changes in the pull request as a live instance.
This greatly facilitates team working for organizations working in an async
fashion, possibly from different timezones, to collaborate and provide feedback
on the changes as soon as possible, with the least delay and to help unblock
the merge queue.

## What Preview Environment is NOT?

It's important to highlight that in no way the preview environment can be a
substitute for regular workflow of the software development lifecycle.

Even with a preview environment for each pull request, the author of the
changes still need to locally run the application, review, test and verify that
everything works as expected.

Moreover, the automated tests of the application need to run before or at least
during the deployment of the preview environment. You should, at the very
least, run your small and fast unit tests locally before pushing the changes to
the pull request branch.

The preview environment is a powerful tool, but it's not a silver bullet. At
the end of the day, when all is said and done, *no tool and technology can
replace the engineering culture and mindset of the team*.

## Why is Preview Environments Beneficial?

Working in a team and receiving instant feedback from the impact of your work
is essential to the success of the project. It allows using all the powers of
the team combined, and not just the sum of each individual's effort.

Here are the main reasons why you should consider setting up preview
environments for each pull request.

- [x] **Speeds up the feedback loop**: The preview environment allows the
      author of the pull request and the reviewers to see the new revisions
      instantly. This greatly speeds up the feedback loop and the approval
      process.
- [x] **Enhanced continuous integration**: Having fast and short feedback loop
      upon code reviews, as well as the automated tests running in parallel,
      allows the dev team to see their changes faster in the codebase, giving
      the sense of accomplishment.
- [x] **Powers up the code reviews**: The reviewers have less manual labor to
      deal with when verifying the integrity and correctness of the new
      revision of the code. The live instance of the application can quickly
      give a look 'n feel of the changes and the impact it will have on the
      application.
- [x] **Improved (remote) collaboration**: People have different task
      priorities on their working day and one may or may not be able to review
      a change in the codebase at the same time as the author. The preview
      environment facilitates asynchronous collaboration.
- [x] **Better developer/testing experience**: Having instant access to an
      already deployed instance of the new application is a boost in
      productivity, enabling fast validation within the dev team as well as the
      product team.
- [x] **Short merge queues**: A better code review results in instant
      verification. Having the newer revision of the app available for testing
      on-demand significantly increases the likelihood of convincing reviewers
      to provide input and feedback. This is because there is less resistance
      due to the time required for testing.

## How to Set Up Preview Environments for Pull Requests?

Based on the infrastructure you will work with, the setup will vary greatly.
However, for the purpose of this blog post, we have chosen the following tech
stack:

- [x] A running [Kubernetes] v1.30-ish cluster. Feel free to pick your
      preferred method for bootstraping a cluster. You are more than welcome to
      consult our archive if you need help setting up a cluster:
    - [Kubernetes the Hard Way]
    - [How to Install Lightweight Kubernetes on Ubuntu 22.04]
    - [Setting up Azure Managed Kubernetes Cluster]
- [x] [GitHub Actions] for the CI/CD pipeline.
- [x] [FluxCD] for the GitOps deployment.
- [x] [cert-manager] for the TLS certificates.
- [x] [Kustomization] for the Kubernetes manifests.

For the implementation of this task, we aim to achieve the following tasks
sequentially:

1. Create a base [Kustomization] for the application.
2. Create two overlays on top of it, one for dev deployment and the other for
   preview deployments (per each pull request).
3. Fetch the wildcard TLS certificate to be used by the preview environment
   stacks.
4. Write the [GitHub Actions] workflow to deploy and teardown the preview
   environment on-demand based on the labels of the pull request.

## Base Kustomization for the Application

Now that you know the steps we will cover, let's get our hands dirty and
roll up our system administration sleeves.

The following code snippets are using a sample `echo-server` application
written by us[^echo-server-github]. Though, the principle and the setup can be
applied to any application you are working with.

```ini title="echo-server/base/configs.env"
-8<- "docs/codes/2024/0017/echo-server/base/configs.env"
```

```yaml title="echo-server/base/service.yml"
-8<- "docs/codes/2024/0017/echo-server/base/service.yml"
```

```yaml title="echo-server/base/deployment.yml"
-8<- "docs/codes/2024/0017/echo-server/base/deployment.yml"
```

```yaml title="echo-server/base/kustomization.yml"
-8<- "docs/codes/2024/0017/echo-server/base/kustomization.yml"
```

## Overlay for Dev Deployment

```ini title="echo-server/overlays/dev/configs.env"
-8<- "docs/codes/2024/0017/echo-server/overlays/dev/configs.env"
```

```yaml title="echo-server/overlays/dev/deployment.yml"
-8<- "docs/codes/2024/0017/echo-server/overlays/dev/deployment.yml"
```

```yaml title="echo-server/overlays/dev/httproute.yml"
-8<- "docs/codes/2024/0017/echo-server/overlays/dev/httproute.yml"
```

```yaml title="echo-server/overlays/dev/kustomization.yml"
-8<- "docs/codes/2024/0017/echo-server/overlays/dev/kustomization.yml"
```

With our dev stack ready, we can simply deploy it to our cluster with the
following [FluxCD] CRD resource:

```yaml title="kustomize/dev.yml"
-8<- "docs/codes/2024/0017/kustomize/dev.yml"
```

```shell title="" linenums="0"
kubectl apply -f kustomize/dev.yml
```

## Overlay for Preview Deployment

```yaml title="echo-server/overlays/test/httproute.yml"
-8<- "docs/codes/2024/0017/echo-server/overlays/test/httproute.yml"
```

```yaml title="echo-server/overlays/test/kustomization.yml"
-8<- "docs/codes/2024/0017/echo-server/overlays/test/kustomization.yml"
```

Notice that on this stack, you see a couple of placeholders in the format of
bash interpolation, e.g., `${IMAGE_TAG}` and `${PR_NUMBER}`. These are not
known at the time of writing. Instead, they are dynamically generated values
coming from our [GitHub Actions] CI workflow which you will see shortly.

With our preview environment definition ready, we should set up some of the
other relevant and required components before being able to deploy it to our
cluster.

## Fetching the Wildcard TLS Certificate

We have already covered the ins and outs of [cert-manager] in our earlier
guide. If you need a refresher, check out the following blog post:

[cert-manager: All-in-One Kubernetes TLS Certificate Manager]

Using that stack, we can create a wildcard [TLS] certificate with the following
CRD resource:

```yaml title="cert-manager/certificate.yml"
-8<- "docs/codes/2024/0017/cert-manager/certificate.yml"
```

Having a wildcard TLS certificate is a crucial component of this set up.
Because every one of our pull request deployment will have a different URL,
dynamically generated with a specific pattern in the following form:

```plaintext title="" linenums="0"
pr7.test.developer-friendly.blog
```

## GitHub Actions Workflow

The last piece of the puzzle is what glues the whole setup together. The CI
definition is satisfying the following criteria:

*For every push to the branch of the pull-requset, if the pull-request is still
open and labeled `deploy-preview`, create the corresponding Kustomization stack
with all the values initialized.*

To make it easier to grasp the whole picture, we will break down the workflow
into smaller chunks, explain each as deserved, and then put them all together
into one single whole.

### Workflow Concurrency

After naming the workflow with a desired value, we are prohibiting the
concurrent runs of our job. This ensures that new CI runs will replace the old
ones and we won't be billed for the obsolete run that is no longer up to date
with our latest changes of the application.

```yaml title=".github/workflows/ci.yml"
-8<- "docs/codes/2024/0017/workflow/ci.yml:1:5"
```

### Trigger on Pull Request

The events that we want this CI to be triggered are the ones that involve
updates to the pull request. It can either be closed, opened, re-opened,
labeled and un-labeled, etc.. These will ensure that any push to the open pull
request will trigger the run of our job.

```yaml title=".github/workflows/ci.yml" linenums="7"
-8<- "docs/codes/2024/0017/workflow/ci.yml:7:18"
```

Consequently, the conditional of the job will check for a match on the event
and its relevant attribute when being invoked.

```yaml title=".github/workflows/ci.yml" linenums="20"
-8<- "docs/codes/2024/0017/workflow/ci.yml:20:26"
```

### Build Image Job Permission

The runner job that will build our [Docker] image will require write access
to the [GitHub Container Registry] also known as `ghcr.io`. This is where we
will store and retrieve our Docker images.

```yaml title=".github/workflows/ci.yml" linenums="27"
-8<- "docs/codes/2024/0017/workflow/ci.yml:27:29"
```

### Build and Push Docker Image

These steps will build the [Docker] image as instructed by the repository's
`Dockerfile` and push the image to the `ghcr.io`, later to be used by our
cluster when fetching the new image tag.

```yaml title=".github/workflows/ci.yml" linenums="30" hl_lines="32"
-8<- "docs/codes/2024/0017/workflow/ci.yml:30:61"
```

Pay close attention to the image tag we are instructing the build step to use.
We need the `${{ env.IMAGE_REPOSITORY }}:${{ github.run_id }}` to be among the
tags that the Docker image is built with.

This will allow us to use the same reference when updating the preview stack
with a new image tag.

Forgetting this step, and we might end up in a situation where our [Kubernetes]
Deployment is not up-to-date because the `imagePullPolicy` is by default set to
`IfNotPresent` and the image tag is not updated, resulting in using the old
image.

The important and very useful note to mention here is that `github.run_id` is
monotonic and guaranteed to be unique for each run of the
workflow[^github-actions-context]. This gives us perfect control over the image
tag and the idempotency we require.

### Deploy Job on self-hosted Runner

One of the main concerns of an operational team should be the security and
protection of the [Kubernetes] API Server.

Whether or not you are using a managed Kubernetes cluster, your API Server
should be protected by firewall rules from a certain trusted IP addresses.

Those *trusted* IP addresses will include yours, anyone in your team that
ought to send requests to the Kubernetes server, as well as your CI runner
public IP address.

The CI runner has to have an static IP address for this to work. Otherwise,
you will end up hacking your way into Kubernetes, e.g., by having an step in
your CI definition to add the current runner IP address to the firewall rules;
it's an extra step that will not benefit your maintenance costs!

As such, the solution is to either use GitHub large runners[^gh-large-runners]
or spin up your own VM, assign it an static public IP address and add that
address to the list of authorized IPs of the Kubernetes API Server.

The following example uses the latter approach, using a self-hosted GitHub
runner[^gh-self-hosted-runner].

```yaml title=".github/workflows/ci.yml" linenums="63"
-8<- "docs/codes/2024/0017/workflow/ci.yml:63:65"
```

### Set up the Environment Variables

As [mentioned before](#overlay-for-preview-deployment), we will use some of the
dynamic values during our CI run. That allows passing values that are otherwise
not known at the definition stage.

These values are provided to the runner in its definition in the following
manner:

```yaml title=".github/workflows/ci.yml" linenums="66"
-8<- "docs/codes/2024/0017/workflow/ci.yml:66:68"
```

Eventually the above values will be something like the following:

```ini title="" linenums="0"
PR_NUMBER=pr7
IMAGE_TAG=9633075699
```

### Deploy Job Permissions

Our deployment runner will require write access to the pull request to print
out the internet-accessible URL of the preview environment.

That is granted as below:

```yaml title=".github/workflows/ci.yml" linenums="69"
-8<- "docs/codes/2024/0017/workflow/ci.yml:69:70"
```

### Preview FluxCD Kustomization

We need a FluxCD [Kustomization] stack to be created dynamically for each pull
request. This will be very similar to what we had with `kustomize/dev.yml`
earlier, yet some of the values will obviously differ.

This is the Kustomization that'll be used inside the CI.

```yaml title=""
-8<- "docs/codes/2024/0017/kustomize/test.yml"
```

Let's pass that YAML file as a string into the CI.

```yaml title=".github/workflows/ci.yml" linenums="71"
-8<- "docs/codes/2024/0017/workflow/ci.yml:71:78"
```

!!! question "Complex?"

    Maybe! It's your call to define how complex is complex. Yet this is a
    working example of something you can use. Or, if you prefer something
    different, you can take inspiration from what you got here and apply it with
    your principle and your preferred style to your environment.

### Comment the URL to the Pull Request

The last part of our deployment CI is to print out the URL of the preview
environment on the pull request[^comment-pr-marketplace]. This will allow the
subscribers of the pull request to be notified that the new stack is ready and
can be accessed.

```yaml title=".github/workflows/ci.yml" linenums="79"
-8<- "docs/codes/2024/0017/workflow/ci.yml:79:85"
```

Successful run of this step will result in the following comment.

<figure markdown="span">
  ![Comment URL on the Pull Request](/static/img/2024/0017/comment-pr.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Comment URL on the Pull Request</figcaption>
</figure>

???+ example "Preview Environment"

    Deploying our `echo-server`, we will get the following response if we
    access it from the browser.

    ```json title=""
    -8<- "docs/codes/2024/0017/junk/pr7-response.json"
    ```

## Teardown the Preview Environment

We have only discussed how to set up the environment so far. But, once the pull
request is closed or the label is removed, we want to remove the stack as well.
That ensures that there is no lingering stack left in our stuck to occupy our
precious resources.

The teardown of the preview environment is similar to what we had so far, only
with a change of conditional.

```yaml title=".github/workflows/ci.yml" linenums="87"
-8<- "docs/codes/2024/0017/workflow/ci.yml:87:97"
```

Notice how powerful it can be to customize the conditional of the job. Consider
the value to the `if` conditiona to be an string. Passing multi-line string to
a YAML can be achieved with `|` (pipe characters)[^yaml-multiline-string].

We will also require the same permission and environment variables as before.

```yaml title=".github/workflows/ci.yml" linenums="98"
-8<- "docs/codes/2024/0017/workflow/ci.yml:98:101"
```

### Remove the Preview Stack from the Cluster

The removal of the [Kustomization] stack is a simple `kubectl` command.

```yaml title=".github/workflows/ci.yml" linenums="102"
-8<- "docs/codes/2024/0017/workflow/ci.yml:102:107"
```

### Remove the Comment from the Pull Request

The last step of the teardown is to remove the comment from the pull request.
The rationale is that we no longer need an inaccessible URL to be present in
our pull request.

```yaml title=".github/workflows/ci.yml" linenums="108"
-8<- "docs/codes/2024/0017/workflow/ci.yml:108"
```

The `title` of the comment ensures the uniqueness of the comment and must be
provided. This allows the removal of such comment by searching for that exact
text.

???+ example "Full CI Definition"

    The full CI definition is as follows:

    ```yaml title=".github/workflows/ci.yml"
    -8<- "docs/codes/2024/0017/workflow/ci.yml"
    ```

## Considerations

We have discussed one of the common patterns of working in a team environment
and collaborating on the codebase, while increasing the efficiency of the
processes and reducing the frictions by employing the powers of the modern
technologies and tools.

At this point, we should highlight some of the considerations so that you can
have a better understanding of what it actually takes to set this up for
yourself and your team.

### How Much Shared is Shared?

We have mentioned earlier that it is better to re-use the same resources and
dependencies as you have in your dev environment. But how much shared should it
be? Would you give your backend application all the access to the dev database
and caching system? Or do you separate them into different networks?

The answer to this question is the undesired and ever so common *it depends*.
We cannot provide you a general and universal recipe for what may or may not
work.

The goal of this article has been to provide you with a starting point,
accompanied with a practical example to solidify the concept.

However, the devil is in the details. When trying to adopt this pattern, you
ought to consider the limitations and the constraints of your environment for
yourself and decide accordingly.

### Is GitOps Required for this?

It is not.

You are free to use any other deployment method that you or your team are
comfortable with.

The GitOps and the selected tool here, [FluxCD], is just one way of doing
things. That just happens to be the preferred way of doing things by the
author. :nerd:

### RBAC, Yes or No?

It is absolutely crucial to set up RBAC in your [Kubernetes] cluster to avoid
unintended suprises and unauthorized access to your resources.

Specifically, the CI runner should have the least amount of permissions to do
its job.

Go through the resources being created in such a job and make sure you do not
give it more permissions than it actually needs.

At any point in time when you realize that your CI needs more permissions, you
will be able to grant it such, but no sooner than that.

### How Much Resource to Allocate?

The preview environment is a live instance of the application. It will require
nearly as much as what you are using in your dev environment.

As such, and if you're running in a constrained environment, you should
seriously consider using `LimitRange`[^limitrange] and/or
`ResourceQuota`[^resourcequota] to avoid overloading your cluster and causing
resource contention.

### How to Handle Secrets?

There is no one-size-fits-all answer to this question.

You may have picked one or a combination of tools to manage your secrets. As
such, managing secrets for your preview environments should be a deliberate and
informed decision on your part.

If it helps, you are more than welcome to take a look at our earlier guide
on [External Secrets] in this blog post:

[External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS]

### Do Not Forget About Monitoring and Alerting

It is imperative to have monitoring and alerting set up for your preview
environments just as you have for your dev and prod environments.

Nothing is more frustrating than having a broken preview environment and not
knowing about it until someone reports it.

### What's with the Comment on the Pull Request?

This is just a nice-to-have feature. It is not required for the setup to work.
However, bear in mind that such a comment can be a good indicator that the
preview environment is ready and can be accessed.

It also notifies all the subscribers of the pull request. This is perfect if
you want to maximize your throughput, tending to other tasks while waiting for
the feedback on the pull request.

### What are the Alternatives?

This type of preview deployments might be cumbersome to setup & hard to
maintain.

If your organization is willing to spend money, there are paid solutions that
take away the pain from your shoulders, e.g., PullPreview[^pullpreview].

There are also other ways that employ [Terraform], env0[^env0-guide],
AWS CDK[^aws-cdk-guide], CloudFormation[^cloudformation-preview-deployment]
and/or other [Infrastructure as Code] tools to achieve the same goal.

The choice is yours to make. Just make sure it's an informed one.

<iframe
  src="https://docs.google.com/forms/d/e/1FAIpQLSdKhI0aZb9myabVzyPJcbQWU0kDuDSSHKLLJ95Zx0sLsRsTcw/viewform?embedded=true"
  loading="lazy"
  width="600"
  height="750"
  frameborder="0"
  marginheight="0"
  marginwidth="0"
  >Survey Loading…</iframe
>


## Conclusion

When working in a team environment, it is vital to have a fast feedback loop
on the development process. This motivates the team members to see their
changes faster and merge their code with confidence.

The confidence that will result from the preview environments created to
provide a visual and facilitate the testing of the proposed changes in the
pull request in a live instance.

There is no replacement for a solid engineering culture. The automated tests
and a continuous integration of the codebase are the foundation of the modern
day software development.

The preview environments are just a tool to help the team members to enhance
their collaboration, improve the efficiency of code reviews and shorten the
merge queue.

With faster feedback loops, even your customer is happier, seeing the features
and bugfixes being deployed faster.

This article should give you a good starting point to set up preview
environments. Though this is only one of the many ways to achieve the same
goal. Make sure you understand the pieces involved and the requirement to
make it work in your environment.

I hope you have enjoyed reading this article as much as I did writing it. For
further questions and discussions, feel free to leave a comment or
[join our Slack channel].

Happy hacking and until next time :saluting_face:, *ciao*. :penguin: :crab:

[Kubernetes]: /category/kubernetes/
[GitHub Actions]: /category/github-actions/
[FluxCD]: /category/fluxcd/
[cert-manager]: /category/cert-manager/
[Kustomization]: /category/kustomization/
[TLS]: /category/tls/
[Docker]: /category/docker/
[GitHub Container Registry]: /category/github-container-registry/
[Kubernetes the Hard Way]: ./0003-kubernetes-the-hard-way.md
[How to Install Lightweight Kubernetes on Ubuntu 22.04]: ./0005-install-k3s-on-ubuntu22.md
[Setting up Azure Managed Kubernetes Cluster]: ./0009-external-secrets-aks-to-aws-ssm.md/#step-0-setting-up-azure-managed-kubernetes-cluster
[cert-manager: All-in-One Kubernetes TLS Certificate Manager]: ./0010-cert-manager.md
[join our Slack channel]: https://communityinviter.com/apps/developerfriendly/join-our-slack
[Terraform]: /category/terraform/
[External Secrets]: /category/external-secrets/
[Infrastructure as Code]: /category/infrastructure-as-code/
[External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS]: ./0009-external-secrets-aks-to-aws-ssm.md

[^echo-server-github]: https://github.com/developer-friendly/echo-server/
[^github-actions-context]: https://docs.github.com/en/actions/learn-github-actions/contexts
[^gh-large-runners]: https://docs.github.com/en/actions/using-github-hosted-runners/about-larger-runners
[^gh-self-hosted-runner]: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners
[^comment-pr-marketplace]: https://github.com/marketplace/actions/github-comment-pr
[^yaml-multiline-string]: https://yaml-multiline.info/
[^limitrange]: https://kubernetes.io/docs/concepts/policy/limit-range/
[^resourcequota]: https://kubernetes.io/docs/concepts/policy/resource-quotas/
[^pullpreview]: https://pullpreview.com/
[^env0-guide]: https://www.env0.com/blog/why-per-pull-request-environments-and-how
[^aws-cdk-guide]: https://github.com/jgoux/preview-environments-per-pull-request-using-aws-cdk-and-github-actions
[^cloudformation-preview-deployment]: https://medium.com/nntech/level-up-your-ci-cd-pipeline-with-pull-request-deployments-780878e2f15a
