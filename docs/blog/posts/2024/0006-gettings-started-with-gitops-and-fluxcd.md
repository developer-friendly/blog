---
date: 2024-04-06
description: >-
  What is GitOps Kubernetes? Learn FluxCD with a practical real-world
  example to automate & optimize GitOps repository structure.
draft: false
categories:
  - Kubernetes
  - FluxCD
  - GitOps
  - CI/CD
links:
  - ./blog/posts/2024/0003-kubernetes-the-hard-way.md
  - ./blog/posts/2024/0005-install-k3s-on-ubuntu22.md
image: assets/images/social/2024/04/06/gitops-demystified-introduction-to-fluxcd-for-kubernetes.png
---

# GitOps Demystified: Introduction to FluxCD for Kubernetes

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

<!-- subscribe -->

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
- [x] A basic understanding of [Kustomize][kustomize]. A topic for a future post.

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

## FluxCD Setup & Automation

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
    as a side note that you can automate the FluxCD upgrade process using the
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

## Step 0: Check Pre-requisites

You can check your if your initial setup is acceptable by FluxCD using the
following command:

```shell title="" linenums="0"
flux check --pre
```

### Creating the GitHub Repository

Skip this step if you already have a GitHub repository ready for FluxCD.

!!! note "Repository"

    FluxCD will create the repository as part of the bootstrap process.
    This step will only give you flexibility for better customization.

You will need the GitHub CLI[^2] installed for the following to work.

```bash title="" linenums="0"
gh repo create getting-started-with-gitops --clone --public
cd getting-started-with-gitops
```

### Root Reconciler

FluxCD bootstrap is able to create any initial resource you place in its bootstrap
path. Which means we will be able to spin up any and all the resources we need
alongside FluxCD with only a single command.

That's why, in the same path to the FluxCD bootstrap, we will create a root
`Kustomization` that will control all the subdirectories and reconcile the
resources as needed.

This will later be used to create the monitoring stack and all the bells and
whistles that come with it.

```yaml title="clusters/dev/k8s.yml" hl_lines="8"
-8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/clusters/dev/k8s.yml"
```

And one of the stacks that will be managed by this root `Kustomization` are as
follows:

=== "dev/monitoring/kustomization.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/monitoring/kustomization.yml"
    ```

=== "dev/monitoring/namespace.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/monitoring/namespace.yml"
    ```

=== "dev/monitoring/repository.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/monitoring/repository.yml"
    ```

===+ "dev/monitoring/release.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/monitoring/release.yml"
    ```

### Create a GitHub Personal Access Token

We will need a GitHub Personal Access Token[^7] with the `repo` scope.
You can see token creation screenshot below:

<figure markdown="span">
  ![Generating GitHub PAT](/static/img/2024/0006/pat-token.webp "Click to zoom in"){ loading=lazy }
  <figcaption>Generating GitHub Personal Access Token (PAT)</figcaption>
</figure>

Use the newly created token for the next step.

## Step 1: Bootstrapping FluxCD

We can now spin up FluxCD in our Kubernetes cluster using the following command:

```shell title="" linenums="0"
export GITHUB_TOKEN="TOKEN_FROM_THE_LAST_STEP"
export GITHUB_ACCOUNT="developer-friendly"
export GITHUB_REPO="getting-started-with-gitops"
flux bootstrap github \
  --owner=${GITHUB_ACCOUNT} \
  --repository=${GITHUB_REPO} \
  --private=false \
  --personal=true \
  --path=clusters/dev
```

It will take a moment or two for everything to reconcile, but after that,
FluxCD will be up and running in your Kubernetes cluster.

### Check the state of the cluster

You can check the status using the following command.

```shell title="" linenums="0"
flux check
```

We can also check the pods, `Kustomization` and `HelmRelease` resources.

```shell title="" linenums="0"
kubectl get pods -A
kubectl get kustomizations,helmreleases -A # ks,hr for short
```

The final status of our loki-stack `HelmRelease` will transition from this:

```plaintext title="" linenums="0"
Running 'install' action with timeout of 2m0s
```

To this:

```plaintext title="" linenums="0"
Helm install succeeded for release monitoring/loki-stack.v1 with chart loki-stack@2.10.2
```

## Step 2: Monitoring the Cluster

We now have the monitoring stack up and running in our Kubernetes cluster.
Let's leverage it to deliver our alerts and notifications to the Prometheus
Alertmanager[^8].

Because of the necessity of monitoring and sane alerting, we need a mechanism
to be notified about the events of our cluster based on different severities.
That's where FluxCD's notification controller[^6] comes into play.

In this step we will create a `Provider` for FluxCD to send notifications
and alerts to our in-cluster Alertmanager, after which the admin/operator
can decide how to handle them using the `AlertmanagerConfig` resource.

!!! success "Alertmanager Configuration"

    Stay tuned for a future post where we will explore how to configure
    Alertmanager to send notifications to various channels like Slack, Email,
    and more.

=== "dev/notifications/kustomization.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/notifications/kustomization.yml"
    ```

=== "dev/notifications/alertmanager-address.yml"
    ```yaml title="" hl_lines="4"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/notifications/alertmanager-address.yml"
    ```

===+ "dev/notifications/alertmanager.yml"
    ```yaml title="" hl_lines="8"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/notifications/alertmanager.yml"
    ```

And the notification resources are as follows:

=== "dev/notifications/alert.yml"
    ```yaml title="" hl_lines="7"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/notifications/alert.yml"
    ```

=== "dev/notifications/info.yml"
    ```yaml title="" hl_lines="7"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/notifications/info.yml"
    ```

There are some important notes worth mentioning here:

1. We didn't run any `kubectl apply` command after writing our new manifests and
committing them to the repository. FluxCD took care of that behind the scenes.
The [root reconciler](#root-reconciler) is a `Kustomization` resource which
has a recursive nature and will apply all the `kustomization.yml` files in the
subdirectories.
2. The `alertmanager-address` Secret will need to be in the same namespace as
the `Provider` resource. This is due to the design of the Kubernetes itself
and has less to do with FluxCD.
3. Having notifications on different severities allow you and your team to
receive highlights about the live state of your cluster as you see fit. This
means that you might be interested to route the informational notifications
to a muted Slack channel which is likely noisier than the critical alerts,
while sending the critical alerts to a pager system that will notify the right
people at the right time.

!!! tip "Reconciliation"

    All the manifests we created so far are committed to the repository and
    pushed to the remote. We didn't need any `kubectl apply` command to apply
    those resources and as long as we write and commit all our manifests under
    the same tree structure, FluxCD will create them in the cluster.

## Step 3: Trigger a Notification

We have created the required resource for the notifications to be sent to the
Prometheus' Alertmanager.

To take it for a spin, we can create a sample application to trigger the
info notification.

=== "dev/echo-server/kustomization.yml"
    ```yaml title="" hl_lines="5-8"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/echo-server/kustomization.yml"
    ```

=== "dev/echo-server/configs.env"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/echo-server/configs.env"
    ```

===+ "dev/echo-server/deployment.yml"
    ```yaml title="" hl_lines="11-15"
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/echo-server/deployment.yml"
    ```

=== "dev/echo-server/service.yml"
    ```yaml title=""
    -8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/v2.2.3/dev/echo-server/service.yml"
    ```

We won't go into much detail for the Kustomize resource as that is a topic for
another post and deserves more depth.

However, pay close attention to the syntax of `configs.env` and the way we have
employed `configMapGenerator` in the `kustomization.yml` file.

This will ensure that for every change to the `configs.env` file, the resulting
`ConfigMap` resource will be re-created with a new hash-suffixed name, which will
consequently restart the `Deployment` resource and re-read the new values[^9].

This is an important highlight cause you have to specify your Deployment
strategy carefully if you want to avoid downtime in your applications.

!!! success "Kustomize"

    We will dive into Kustomize and all its powerful and expressive features in a
    future post. Stay tuned to learn more about it.

To see that our notification has arrived at Alertmanager, we will jump over to
the Alertmanager service using port forwarding technique, although in a real
world scenario, you'd expose it through either an Ingress Controller or a
Gateway API (a topic for another post :wink:).

```shell title="" linenums="0"
kubectl port-forward -n monitoring svc/loki-stack-alertmanager 9093:9093 &
```

Sure enough, if we open <http://localhost:9093>, we will see the notification
in the Alertmanager UI as seen in the screenshot below.

<figure markdown="span">
  ![Alertmanager UI info triggered](/static/img/2024/0006/alertmanager-ui-info.webp "Click to zoom in"){ loading=lazy }
  <figcaption>Alertmanager UI info triggered</figcaption>
</figure>

### Trigger a Critical Alert

Now, let's break the app to see if the severity of the notification changes as
expected.

```yaml title="dev/echo-server/kustomization.yml" hl_lines="12"
-8<- "https://github.com/developer-friendly/getting-started-with-gitops/raw/6aa47c9700c525069eac4c60dc2f1f6d6ecb30a7/dev/echo-server/kustomization.yml"
```

And lo and behold, the Alertmanager UI will now show the critical alert as seen
below.

<figure markdown="span">
  ![Alertmanager UI error triggered](/static/img/2024/0006/alertmanager-ui-error.webp "Click to zoom in"){ loading=lazy }
  <figcaption>Alertmanager UI <strong>error</strong> triggered</figcaption>
</figure>

To restore the application to its normal state, you can revert the changes,
commit to the repository and let FluxCD do its magic.

## Conclusion

That concludes our guide on getting started with GitOps and FluxCD. We have
covered most of the essential components and concepts of GitOps and FluxCD.

We have deployed the monitoring stack right out of the box and provided the
minimum working example[^10] on how to structure your
repository in a way that reduces the friction of your deployments in an
automated and GitOps fashion.

Lastly, we have deployed an application and triggered both informational and
critical alerts to the Prometheus Alertmanager. By observing the notifications
in the Alertmanager UI, we have seen how the notifications are routed based on
their severity.

In a future post, we will explore more integrations with this setup on how to
route the notifications on Alertmanager to external services like Slack,
Discord, etc. and how to manage your secrets in a secure way so that you
wouldn't have to commit them to your repository.

Another topic we didn't cover here was `Receiver` resource. That will require
internet access to your cluster, which we'll cover at a later post when
discussing the Kubernetes Gateway API[^11].

Until next time, *ciao* :penguin: :crab: & happy coding! :nerd:

## Source Code

The full repository is publicly available on GitHub[^12] under the
[Apache 2.0 license][license].

[k8s-the-hard-way]: ./0003-kubernetes-the-hard-way.md
[minikube]: https://minikube.sigs.k8s.io/docs/blog/
[kind]: https://kind.sigs.k8s.io/
[k3s-setup]: ./0005-install-k3s-on-ubuntu22.md
[kustomize]: https://kustomize.io/
[license]: https://github.com/developer-friendly/blog/tree/main/LICENSE

[^1]: https://github.com/fluxcd/flux2/releases/
[^2]: https://cli.github.com/
[^3]: https://en.wikipedia.org/wiki/DevOps#GitOps
[^4]: https://fluxcd.io/flux/installation/upgrade/#upgrade-with-flux-cli
[^5]: https://fluxcd.io/flux/flux-gh-action/
[^6]: https://fluxcd.io/flux/components/notification/
[^7]: https://github.com/settings/tokens/new
[^8]: https://prometheus.io/docs/blog/alerting/latest/alertmanager/
[^9]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/
[^10]: https://en.wikipedia.org/wiki/Minimal_reproducible_example
[^11]: https://gateway-api.sigs.k8s.io/
[^12]: https://github.com/developer-friendly/getting-started-with-gitops/tree/v2.2.3/
