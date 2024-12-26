---
date: 2024-12-30
description: >-
  How to use Ory Oathkeeper and Ory Kratos to protect upstream services behind
  internet-accessible authentication.
categories:
  - Kubernetes
  - Ory
  - Kratos
  - Oathkeeper
  - VictoriaMetrics
  - Kustomization
image: assets/images/social/2024/12/30/how-to-protect-any-upstream-service-with-operational-authentication.png
---

# How to Protect ANY Upstream Service with Operational Authentication

In this blog post, I will demonstrate how to use Ory Oathkeeper and Ory Kratos
to protect upstream services behind authentication, especially the ones that do
not have native authentication built-in, e.g., Prometheus, Hubble UI,
Alertmanager, etc.

<!-- more -->

## Introduction

Over the years of administering and maintaining production-grade systems at
different companies, I have found myself in the situations where I needed to
deploy internet-accessible services that may or may not provide built-in
authentication.

These services are usually valuable assets and solutions to the current
problems of the organization/platform. Having them exposed and accessible over
the internet would benefit the employees and administrators a lot.

However, the downside is that not having built-in authentication is a security
risk. One that cannot and should not be overlooked.

As such, in the following article, I will share my method of protecting those
critical and administrative level services to the public internet in a way that
is only visible to the trusted eyes.

## Prerequisites

The purpose of this blog post is not [Kubernetes], however I find myself at
ease deploying and configuring stuff on Kubernetes.

Additionally, this blog post will mainly focus on [Ory] services, specifically
Ory [Oathkeeper] and Ory [Kratos].

Getting to know those services and their inner workings is crucial for a better
understanding of this blog post.

## Setting up the Environment

I will be deploying a K3d Kubernetes cluster on my machine, however, the ideas
described here are applicable AND used in production (by myself).

```shell title="" linenums="0"
k3d cluster create -p "8080:80@loadbalancer" --agents 0 --servers 1
```

This will be a locally accessible [Kubernetes] cluster. Notice the
port-forwarding flag which will allow us to send load balanced requests to the
cluster.

When this is ready, the following should Ingress Class is availble:

```shell title="" linenums="0"
$ kubectl get ingressclass
NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       1s
```

## Deploy VictoriaMetrics K8s Stack

I admire the [VictoriaMetrics] family and all its branching products. I use
almost all of its services, including the newly released VictoriaLogs[^vmlogs].

I will deploy their Kubernetes compatible stack using the following three
commands:

```shell title="" linenums="0"
helm repo add vm https://victoriametrics.github.io/helm-charts
helm repo update vm
helm install victoria-metrics-k8s-stack vm/victoria-metrics-k8s-stack --version=0.x
```

Now, checking on the deployed apps, I will see the followings [Kubernetes]
Service resources

```shell title="" linenums="0"
$ kubectl get svc
NAME                                                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
kubernetes                                             ClusterIP   10.43.0.1       <none>        443/TCP                      9m1s
victoria-metrics-k8s-stack-grafana                     ClusterIP   10.43.160.127   <none>        80/TCP                       4m46s
victoria-metrics-k8s-stack-kube-state-metrics          ClusterIP   10.43.166.238   <none>        8080/TCP                     4m46s
victoria-metrics-k8s-stack-prometheus-node-exporter    ClusterIP   10.43.189.100   <none>        9100/TCP                     4m46s
victoria-metrics-k8s-stack-victoria-metrics-operator   ClusterIP   10.43.242.71    <none>        8080/TCP,9443/TCP            4m46s
vmagent-victoria-metrics-k8s-stack                     ClusterIP   10.43.52.139    <none>        8429/TCP                     3m50s
vmalert-victoria-metrics-k8s-stack                     ClusterIP   10.43.216.20    <none>        8080/TCP                     3m46s
vmalertmanager-victoria-metrics-k8s-stack              ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   3m10s
vmsingle-victoria-metrics-k8s-stack                    ClusterIP   10.43.77.57     <none>        8429/TCP                     3m51s
```

## Deploy Ory Kratos

This is where the fun begins. :sunglasses:

I aim to deploy [Kratos] with as minimal overhead as possible. I maintain my
own [Kustomization] files for deploying some of the services, including
Kratos[^kustomizations].

### Kratos Server Configuration

First things first, we need to create a `config.yml` file for the Kratos server.

This is regardless of how you plan to deploy the Kratos server, e.g., Docker
Compose, bare CLI, Kubernetes, etc.

??? note "kratos-server-config.yml"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/kratos/kratos-server-config.yml"
    ```

### Kratos Kustomization

You are more than welcome to pick Helm from the officially supported Helm chart
[^ory-charts], however, I have found their Helm charts inflexible and very
hard to maintain and customize! Examples include mounting secrets from External
Secrets Operator, mounting a specific volume for configuration files, etc.

That's the main reason I maintain my own security hardened [Kustomization]
stack[^kustomizations] that is almost always one patch[^kustomize-patch] away
from being exactly what you need it to be.

```yaml title="kratos/ingress.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/kratos/ingress.yml"
```

```yaml title="kratos/kustomization.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/kratos/kustomization.yml"
```

### Kratos SQL Database

There are a number of ways you can provide a SQL-backed database to the [Ory]
[Kratos] server. In this blog post, I choose to deploy a in-cluster PostgreSQL
using the Bitnami Helm Chart[^bitnami-postgres].

```shell title="" linenums="0"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
helm install postgresql bitnami/postgresql --version=16.x --set auth.username=kratos,auth.password=kratos,auth.database=kratos
```

### Build and Apply Kratos Kustomization

At this point, we are ready to deploy the Kratos server with the provided
configuration.

??? example "kustomize build ./kratos"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/assets/kratos-manifests.yml"
    ```

??? example "kubectl apply -k ./kratos"

    ```plaintext title="" linenums="0"
    serviceaccount/kratos unchanged
    configmap/kratos-config-57k2b7bctm unchanged
    configmap/kratos-envs-f5b9tfdm77 unchanged
    service/kratos-admin unchanged
    service/kratos-courier unchanged
    service/kratos-public unchanged
    deployment.apps/kratos unchanged
    ```

We will wait for a bit, and after everything has landed successfully, here are
the success of our efforts:

??? example "kubectl logs deploy/kratos -c kratos"

    ```plaintext title=""
    time=2024-12-26T11:10:04Z level=info msg=[DEBUG] GET https://gist.githubusercontent.com/meysam81/8bb993daa8ebfeb244ccc7008a1a8586/raw/dbf96f1b7d2780c417329af9e53b3fadcb449bb1/admin.schema.json audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=No tracer configured - skipping tracing setup audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=warning msg=The config has no version specified. Add the version to improve your development experience. audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=Software quality assurance features are enabled. Learn more at: https://www.ory.sh/docs/ecosystem/sqa audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=TLS has not been configured for public, skipping audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=TLS has not been configured for admin, skipping audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=Starting the admin httpd on: 0.0.0.0:4434 audience=application service_name=Ory Kratos service_version=v1.3.1
    time=2024-12-26T11:10:05Z level=info msg=Starting the public httpd on: 0.0.0.0:4433 audience=application service_name=Ory Kratos service_version=v1.3.1
    ```

Now, let's try if it's working:

```shell title="" linenums="0"
$ curl -i http://auth-server.localhost:8080/health/ready
HTTP/1.1 200 OK
Content-Length: 16
Content-Type: application/json; charset=utf-8
Date: Thu, 26 Dec 2024 11:15:51 GMT
Vary: Origin

{"status":"ok"}
```

## Deploy Ory Oathkeeper

We are half way there guys, hang in there. :hugging:

Deploying Oathkeeper is a two-step process when it comes to [Kubernetes].

We first need to deploy Oathkeeper Maester, the Operator that converts
Kubernetes CRDs to Access Rules for the Oathkeeper server.

### Deploy Oathkeeper Maester

```yaml title="oathkeeper-maester/kustomization.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/oathkeeper-maester/kustomization.yml"
```

```shell title="" linenums="0"
kubectl apply -k ./oathkeeper-maester
```

??? example "kustomize build ./oathkeeper-maester"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/assets/oathkeeper-maester-manifests.yml"
    ```

Now, I know, I know, it's too much!
Why the hell not just use the official Helm chart!?

By all means, if that works for you, go for it.

I just enjoy hacking way too much that I would like to admit. :nerd:

### Oathkeeper Configuration

The second part of the [Oathkeeper] story is of course the Oathkeeper server
itself.

I will provide the configuration file, as it is the most crucial part of the
deployment.

??? note "oathkeeper/oathkeeper-server-config.yml"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/oathkeeper/oathkeeper-server-config.yml"
    ```

### Oathkeeper Kustomization

We have the most important part ready, it's time to deploy this bad boy!

```yaml title="oathkeeper/kustomization.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/oathkeeper/kustomization.yml"
```

```shell title="" linenums="0"
kubectl apply -k ./oathkeeper
```

??? example "kustomize build ./oathkeeper"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/assets/oathkeeper-manifests.yml"
    ```

Believe it or not, all is ready now. :partying_face:

We can safely go ahead and expose our internal services behind the [Ory]
authentication layer, and all thanks to operational configuration and system
administration skills and no requirement for changing the codebase of the
upstream services.

Imagine having to add your custom-built authantication to the [VictoriaMetrics]
codebase. Good luck with that! :sweat_smile:

## Kratos Self-Service UI Node

Oh, I forgot to mention. :face_with_hand_over_mouth:

You seen that redirect URL in the Oathkeeper server configuration? That also
needs to be deployed; a frontend that can authenticate the user from the
browser.

What other better fit for the task than the UI created by the [Ory] team
itself, officially maintained and provided as an opensource product.

And yes, I also support the [Kustomization] for that sucker too. :wink:

```yaml title="kratos-selfservice-ui-node/ingress.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/kratos-selfservice-ui-node/ingress.yml"
```

```yaml title="kratos-selfservice-ui-node/kustomization.yml"
-8<- "docs/blog/posts/2024/0023-operational-authentication/kratos-selfservice-ui-node/kustomization.yml"
```

```shell title="" linenums="0"
kubectl apply -k ./kratos-selfservice-ui-node
```

??? example "kustomize build ./kratos-selfservice-ui-node"

    ```yaml title=""
    -8<- "docs/blog/posts/2024/0023-operational-authentication/assets/kratos-selfservice-ui-node-manifests.yml"
    ```

## Protecting Unauthenticated Services

Let's go ahead and create a couple of Rule and Ingress resources to make sure
our setup is solid. :muscle:

[Kubernetes]: ../../category/kubernetes.md
[Ory]: ../../category/ory.md
[Kratos]: ../../category/kratos.md
[Oathkeeper]: ../../category/oathkeeper.md
[VictoriaMetrics]: ../../category/victoriametrics.md
[Kustomization]: ../../category/kustomization.md

[^vmlogs]: https://docs.victoriametrics.com/victorialogs/
[^kustomizations]: https://github.com/meysam81/kustomizations
[^ory-charts]: https://github.com/ory/k8s
[^kustomize-patch]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/
[^bitnami-postgres]: https://artifacthub.io/packages/helm/bitnami/postgresql
[^localhost-cookie]: https://stackoverflow.com/a/74554894/8282345
