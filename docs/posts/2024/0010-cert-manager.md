---
date: 2024-05-06
draft: false
description: >-
  Install cert-manager Helm chart and create ClusterIssuer for AWS Route53 and
  Cloudflare. Fetch & renew wildcard certificates for Ingress & Gateway API.
categories:
  - Kubernetes
  - AWS
  - OpenTofu
  - cert-manager
  - Cilium
  - Cloudflare
  - Terraform
  - Gateway API
  - Route53
  - TLS
  - Authentication
  - Authorization
  - External Secrets
  - FluxCD
  - GitOps
  - IaC
  - Infrastructure as Code
  - OAuth2
  - OIDC
  - Security
links:
  - ./posts/2024/0005-install-k3s-on-ubuntu22.md
  - ./posts/2024/0008-k8s-federated-oidc.md
  - ./posts/2024/0006-gettings-started-with-gitops-and-fluxcd.md
  - Source Code: https://github.com/developer-friendly/cert-manager-guide
social:
  cards_layout_options:
    description: >-
      Learn how to automate your TLS certificate retrieval from AWS &
      Cloudflare in Kubernetes using the cert-manager operator.
image: assets/images/social/2024/05/06/cert-manager-all-in-one-kubernetes-tls-certificate-manager.png
---

# cert-manager: All-in-One Kubernetes TLS Certificate Manager

Kubernetes is a great orchestration tool for managing your applications and all
its dependencies. However, it comes with an extensible architecture and with an
unopinionated approach to many of the day-to-day operational tasks.

One of these tasks is the management of TLS certificates. This includes issuing
as well as renewing certificates from a trusted Certificate Authority.
This CA may be a public internet-facing application or an internal service that
needs encrypted communication between parties.

In this post, we will introduce the industry de-facto tool of choice for
managing certificates in Kubernetes: cert-manager. We will walk you through
the installation of the operator, configuring the issuer(s), and receiving a
TLS certificate as a Kubernetes Secret for the Ingress or Gateway of your
application.

Finally, we will create the Gateway CRD and expose an application securely
over HTTPS to the internet.

If that gets you excited, hop on and let's get started!

<!-- more -->

## Introduction

If you have deployed any reverse proxy in the pre-Kubernetes era, you might
have, at some point or another, bumped into the issuance and renewal of TLS
certificates. The trivial approach, back in the days as well as even today,
was to use `certbot`[^1]. This command-line utility abstracts you away from the
complexity of the underlying CA APIs and deals with the certificate issuance
and renewal for you.

Certbot is created by the Electronic Frontier Foundation (EFF) and is a great
tool for managing certificates on a single server. However, when you're working
at scale with many applications and services, you will benefit from the
automation and integration that cert-manager[^2] provides.

cert-manager is a Kubernetes-native tool that extends the Kubernetes API
with custom resources for managing certificates. It is built on top of the
Operator Pattern[^3], and is a graduated project of the CNCF[^4].

With cert-manager, you can fetch and renew your TLS certificates behind automation,
passing them along to the Ingress[^5] or Gateway[^6] of your platform to host your
applications securely over HTTPS without losing the comfort of hosting your
applications in a Kubernetes cluster.

With that introduction, let's kick off the installation of cert-manager.

???+ success "Huge Thanks to You :hugging:"

    If you're reading this, I would like to thank you for the time you spend
    on this blog :rose:. Whether this is your first time, or you've been here
    before and have liked the content and its quality, I truly appreciate the
    time you spend here.

    As a token of appreciation, and to celebrate with you, I would like to
    share the achievements of this blog over the course of ~11 weeks since its
    launch (the initial commit on Feb 13, 2024[^7]).

    - [x] 10 posts published :books:
    - [x] 14k+ words written so far (40k+ including codes) :pencil:
    - [x] 2.5k+ views since the launch :eyes:
    - [x] 160+ clicks coming from search engines :mag:

    Here are the corresponding screenshots:

    <div class="grid cards" markdown>

    - <figure markdown="span">
        ![Performance](/static/img/2024/0010/performance.webp "Click to zoom in"){ loading=lazy }
        <figcaption>Search Engine Perfomance</figcaption>
      </figure>

    - <figure markdown="span">
        ![Views](/static/img/2024/0010/total-views.webp "Click to zoom in"){ loading=lazy }
        <figcaption>Total Views</figcaption>
      </figure>

    - <figure markdown="span">
          ![Visitors](/static/img/2024/0010/visitors.webp "Click to zoom in"){ max-width="300" loading=lazy }
          <figcaption>Visitors (30 days)</figcaption>
      </figure>

    - <figure markdown="span">
          ![Countries](/static/img/2024/0010/countries.webp "Click to zoom in"){ max-width="300" loading=lazy }
          <figcaption>Countries (30 days)</figcaption>
      </figure>

    </div>

    I don't run ads on this blog (yet!? :thinking:) and my monetization plan,
    as of the moment, is nothing! I may switch gear at some point; financial
    independence and doing this full-time makes me happy honestly :relaxed:.
    But, for now, I'm just enjoying writing in Markdown format and seeing how
    Material for Mkdocs[^8] renders rich content from it.

    If you are interested in supporting this effort, the GitHub Sponsors
    program, as well as the PayPal donation link are available at the bottom
    of all the pages in our website. :octicons-heart-fill-16:

    Greatly appreciate you being here and hope you keep coming back. :champagne_glass:

## Pre-requisites

Before we start, make sure you have the following set up:

- [x] A Kubernetes cluster. We have a couple of guides in our archive if you
      need help setting up a cluster:
      - [Kubernetes the Hard Way](./0003-kubernetes-the-hard-way.md)
      - [Lightweight K3s installation on Ubuntu](./0005-install-k3s-on-ubuntu22.md)
      - [Azure AKS TF Module](./0009-external-secrets-aks-to-aws-ssm.md)
- [x] OpenTofu v1.7[^9]
- [ ] Although not required, we will use FluxCD as a GitOps approach for our
      deployments. You can either follow along and use the Helm CLI instead,
      or follow our earlier guide for
      [introduction to FluxCD](./0006-gettings-started-with-gitops-and-fluxcd.md).
- [ ] Optionally, External Secrets Operator installed. We will use it in this
      guide to store the credentials for the DNS01 challenge.
      - We have covered the installation of ESO in our last week's guide if
        you're interested to learn more:
        *[External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS][ESO]*

## Step 0: Installation

cert-manager comes with a first-class support for Helm chart installation.
This makes the installation rather straightforward.

As mentioned earlier, we will install the Helm chart using FluxCD CRDs.

```yaml title="cert-manager/namespace.yml"
-8<- "docs/codes/2024/0010/cert-manager/namespace.yml"
```

```yaml title="cert-manager/repository.yml"
-8<- "docs/codes/2024/0010/cert-manager/repository.yml"
```

```yaml title="cert-manager/release.yml" hl_lines="20"
-8<- "docs/codes/2024/0010/cert-manager/release.yml"
```

Although not required, it is hugely beneficial to store the Helm values as it
is in your VCS. This makes your future upgrades and code reviews easier.

```shell title="" linenums="0"
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm show values jetstack/cert-manager \
  --version v1.14.x > cert-manager/values.yml
```

```yaml title="cert-manager/values.yml"
-8<- "docs/codes/2024/0010/cert-manager/values.yml"
```

Additionally, we will use Kubernetes Kustomize[^10]:

```yaml title="cert-manager/kustomizeconfig.yml"
-8<- "docs/codes/2024/0010/cert-manager/kustomizeconfig.yml"
```

```yaml title="cert-manager/kustomization.yml" hl_lines="7"
-8<- "docs/codes/2024/0010/cert-manager/kustomization.yml"
```

Notice the namespace we are instructing Kustomization to place the resources in.
The FluCD Kustomization CRD will be created in the `flux-system` namespace, while
the Helm release itself is placed in the `cert-manager` namespace.

Ultimately, to create this stack, we will create a FluxCD Kustomization resource[^11]:

```yaml title="cert-manager/kustomize.yml"
-8<- "docs/codes/2024/0010/cert-manager/kustomize.yml"
```

You may either advantage from the recursive reconciliation of FluxCD, add it
to your root Kustomization or apply the resources manually from your command line.

```shell title="" linenums="0"
kubectl apply -f cert-manager/kustomize.yml
```

??? example "Build Kustomization"

    A good practice is to build your Kustomization locally and optionally apply
    them as a dry-run to debug any potential typo or misconfiguration.

    ```shell title="" linenums="0"
    kustomize build ./cert-manager
    ```

    And the output:

    ```yaml title=""
    -8<- "docs/codes/2024/0010/junk/cert-manager/manifests.yml"
    ```

## Step 1.0: Issuer 101

In general, you can fetch your TLS certificate in two ways: either by verifying
your domain using the HTTP01 challenge or the DNS01 challenge. Each have their
own pros and cons, but both are just to make sure that you own the domain you're
requesting the certificate for. Imagine a world where you could request a
certificate for `google.com` without owning it! :scream:

The HTTP01 challenge requires you to expose a specific path on your web server
and asking the CA to send a GET request to that endpoint, expecting a specific
file to be present in the response.

This is not always possible, especially if you're running a private service.

On a personal note, the HTTP01 feels like a complete hack to me. :sweat:

As such, **in this guide, we'll use the DNS01 challenge**. This challenge
will create a specific DNS record in your nameserver. You don't specifically
have to manually do it yourself, as that is the whole point of automation that
cert-manager will bring to the table.

For the DNS01 challenge, there are a couple of nameserver providers
natively supported by cert-manager. You can find the list of
supported providers on their website[^12].

For the purpose of this guide, we will provide examples for two different
nameserver providers: AWS Route53 and Cloudflare.

AWS services are the indudstry standard for many companies, and Route53 is one
of the most popular DNS services (fame where it's due).

Cloudflare, on the other hand, is handling a significant portion of the
internet's traffic and is known for its networking capabilities across the
globe.

If you have other needs, you won't find it too difficult to find support for
your nameserver provider in the cert-manager documentation.

## Step 1.1: AWS Route53 Issuer

The [developer-friendly.blog] domain is hosted in Cloudflare and to demonstrate
the AWS Route53 issuer, we will make it so that a subdomain will be resolved
by a Route53 Hosted Zone. That way, we can instruct the cert-manager controller
to talk to the Route53 API for record creation and domain verfication.

<figure markdown="span">
   ![Nameservers](/static/img/2024/0010/ns-providers.webp "Click to zoom in"){ loading=lazy }
   <figcaption>Nameserver Diagrams</figcaption>
</figure>

```hcl title="hosted-zone/variables.tf"
-8<- "docs/codes/2024/0010/hosted-zone/variables.tf"
```

```hcl title="hosted-zone/versions.tf"
-8<- "docs/codes/2024/0010/hosted-zone/versions.tf"
```

```hcl title="hosted-zone/main.tf"
-8<- "docs/codes/2024/0010/hosted-zone/main.tf"
```

```hcl title="hosted-zone/outputs.tf"
-8<- "docs/codes/2024/0010/hosted-zone/outputs.tf"
```

To apply this stack we'll use [OpenTofu](/category/opentofu).

We could've either separated the stacks to create the Route53 zone beforehand,
or we will go ahead and target our resources separately from command line as
you see below.

```shell title="" linenums="0"
export TF_VAR_cloudflare_api_token="PLACEHOLDER"
export AWS_PROFILE="PLACEHOLDER"

tofu plan -out tfplan -target=aws_route53_zone.this
tofu apply tfplan

# And now the rest of the resources

tofu plan -out tfplan
tofu apply tfplan
```

???+ question "Why Applying Two Times?"

      The values in a TF `for_each` must be known at the time of planning,
      AKA, static values[^13].

      And since that is not the case with `aws_route53_zone.this.name_servers`,
      we have to make sure to create the Hosted Zone first before passing its
      output to another resource.

We should have our AWS Route53 Hosted Zone created as you see in the screenshot
below.

<figure markdown="span">
   ![AWS Route53](/static/img/2024/0010/route53.webp "Click to zoom in"){ loading=lazy }
   <figcaption>AWS Route53</figcaption>
</figure>

Now that we have our Route53 zone created, we can proceed with the cert-manager
configuration.

### AWS IAM Role

We now need an IAM Role with enough permissions to create the DNS records to
satisfy the DNS01 challenge[^14].

Make sure you have a good understanding of the
[OpenID Connect](/category/openid-connect/), the technique we're employing in
the trust relationship of the AWS IAM Role.

```hcl title="route53-iam-role/variables.tf"
-8<- "docs/codes/2024/0010/route53-iam-role/variables.tf"
```

```hcl title="route53-iam-role/versions.tf"
-8<- "docs/codes/2024/0010/route53-iam-role/versions.tf"
```

```hcl title="route53-iam-role/main.tf" hl_lines="34 48 57"
-8<- "docs/codes/2024/0010/route53-iam-role/main.tf"
```

```hcl title="route53-iam-role/outputs.tf"
-8<- "docs/codes/2024/0010/route53-iam-role/outputs.tf"
```

```shell title="" linenums="0"
tofu plan -out tfplan -var=oidc_issuer_url="KUBERNETES_OIDC_ISSUER_URL"
tofu apply tfplan
```

If you don't know what [OpenID Connect](/category/openid-connect/) is and what
we're doing here, you might want to check out our ealier guides on the
following topics:

- [x] Establishing a trust relationship between
      [bare-metal Kubernetes cluster and AWS IAM](./0008-k8s-federated-oidc.md)
- [x] Same concept of trust relationship, this time between
      [Azure AKS and AWS IAM](./0009-external-secrets-aks-to-aws-ssm.md)

The gist of both articles is that we are providing a means for the two services
to talk to each other securely and without storing long-lived credentials.

In essence, one service will issue the tokens (Kubernetes cluster), and the
other will trust the tokens of the said service (AWS IAM).

### Kubernetes Service Account

Now that we have our IAM role set up, we can pass that information to the
cert-manager Deployment. This way the cert-manager will
assume that role with the Web Identity Token flow[^15] (there are five flows in
total).

We will also create a ClusterIssuer CRD to be responsible for fetching the TLS
certificates from the trusted CA.

```hcl title="route53-issuer/variables.tf"
-8<- "docs/codes/2024/0010/route53-issuer/variables.tf"
```

```hcl title="route53-issuer/versions.tf"
-8<- "docs/codes/2024/0010/route53-issuer/versions.tf"
```

```yaml title="route53-issuer/values.yml.tftpl"
-8<- "docs/codes/2024/0010/route53-issuer/values.yml.tftpl"
```

```hcl title="route53-issuer/main.tf" hl_lines="31 34-37"
-8<- "docs/codes/2024/0010/route53-issuer/main.tf"
```

```hcl title="route53-issuer/outputs.tf"
-8<- "docs/codes/2024/0010/route53-issuer/outputs.tf"
```

```shell title="" linenums="0"
tofu plan -out tfplan -var=kubeconfig_context="KUBECONFIG_CONTEXT"
tofu apply tfplan
```

If you're wondering why we're changing the configuration of the cert-manager
Deployment with a new Helm upgrade, you will find an exhaustive discussion
and my comment on the relevant GitHub issue[^16].

The gist of that conversation is that the cert-manager Deployment won't take into
account the `eks.amazonaws.com/role-arn` annotation on its Service Account, as
[you'd see the External Secrets Operator would](./0008-k8s-federated-oidc.md#step-7-test-the-setup).
It won't even consider using the `ClusterIssuer.spec.acme.solvers[*].dns01.route53.role`
field for some reason! :gun:

That's why we're manually passing that information down to its AWS Go SDK[^17]
using the official environment variables[^18].

This stack allows the cert-manager controller to talk to AWS Route53.

Notice that we didn't pass any credentials, nor did we have to create any IAM
User for this communication to work. It's all the power of
[OpenID Connect](/category/openid-connect/) and
allows us to establish a trust relationship and never have to worry about any
credentials in the client service. :white_check_mark:

### Is There a Simpler Way?

Sure there is. If you don't fancy [OpenID Connect](/category/openid-connect/),
there is always the option to pass the credentials around in your environment.
That leaves you with the burden of having to rotate them every now and then,
but if you're cool with that, there's nothing stopping you from going down
that path. You also have the possibility of automating such rotation using
less than 10 lines of code in any programming language of course.

All that said, I have to say that I consider this to be an
implementation bug[^16];
where cert-manager does not provide you with a clean interface to easily
pass around IAM Role ARN. The cert-manager controller SHOULD be able to assume
the role it is given with the web identity flow!

Regardless of such shortage, in this section, I'll provide you a simpler way
around this.

Bear in mind that I do not recommend this approach, and wouldn't use it in my
own environments either. :shrug:

The idea is to use our
[previously deployed ESO](./0009-external-secrets-aks-to-aws-ssm.md) and pass
the AWS IAM User credentials to the cert-manager controller (easy peasy, no
drama!).

```hcl title="iam-user/variables.tf"
-8<- "docs/codes/2024/0010/iam-user/variables.tf"
```

```hcl title="iam-user/versions.tf"
-8<- "docs/codes/2024/0010/iam-user/versions.tf"
```

```hcl title="iam-user/main.tf" hl_lines="41-42"
-8<- "docs/codes/2024/0010/iam-user/main.tf"
```

```hcl title="iam-user/outputs.tf"
-8<- "docs/codes/2024/0010/iam-user/outputs.tf"
```

And now let's create the corresponding ClusterIssuer, passing the credentials
like a normal human being!

```hcl title="route53-issuer-creds/variables.tf"
-8<- "docs/codes/2024/0010/route53-issuer-creds/variables.tf"
```

```hcl title="route53-issuer-creds/versions.tf"
-8<- "docs/codes/2024/0010/route53-issuer-creds/versions.tf"
```

```hcl title="route53-issuer-creds/main.tf" hl_lines="19-20 22-23 53 56"
-8<- "docs/codes/2024/0010/route53-issuer-creds/main.tf"
```

```hcl title="route53-issuer-creds/outputs.tf"
-8<- "docs/codes/2024/0010/route53-issuer-creds/outputs.tf"
```

We're now done with the AWS issuer. Let's switch gear for a bit to create the
Cloudflare issuer before finally creating a TLS certificate for our desired
domain(s).

## Step 1.2: Cloudflare Issuer

Since Cloudflare does not have native support for OIDC, we will have to pass
an API token to the cert-manager controller to be able to manage the DNS
records on our behalf.

That's where the External Secrets Operator comes into play, again. I invite you
to take a look at our [last week's guide][ESO] if you
haven't done so already.

We will use the ExternalSecret CRD to fetch an API token from the AWS SSM
Parameter Store and pass it down to our Kubernetes cluster as a Secret resource.

Notice the highlighted lines.

```yaml title="cloudflare-issuer/externalsecret.yml" hl_lines="4 9"
-8<- "docs/codes/2024/0010/cloudflare-issuer/externalsecret.yml"
```

```yaml title="cloudflare-issuer/clusterissuer.yml" hl_lines="4 16-17"
-8<- "docs/codes/2024/0010/cloudflare-issuer/clusterissuer.yml"
```

```yaml title="cloudflare-issuer/kustomization.yml"
-8<- "docs/codes/2024/0010/cloudflare-issuer/kustomization.yml"
```

```yaml title="cloudflare-issuer/kustomize.yml"
-8<- "docs/codes/2024/0010/cloudflare-issuer/kustomize.yml"
```

```shell title="" linenums="0"
kubectl apply -f cloudflare-issuer/kustomize.yml
```

That's all the issuers we aimed to create for today. One for AWS Route53 and
another for Cloudflare.

We are now equipped with enough access in our Kubernetes cluster to just create
the TLS certificate and never have to worry about how to verify their ownership.

With that promise, let's wrap this up with the easiest part! :sunglasses:

## Step 2: TLS Certificate

You should have noticed by now that the root [developer-friendly.blog] will
be resolved by Cloudflare as our initial nameserver. We also created a subdomain
and a Hosted Zone in AWS Route53 to resolve the `aws.` subdomain using Route53
as its nameserver.

We can now fetch a TLS certificate for each of them using our newly created
ClusterIssuer resource. The rest is the responsibility of the cert-manager to
verify the ownership within the cluster through the DNS01 challenge and using
the access we've provided it.

```yaml title="tls-certificates/aws-subdomain.yml" hl_lines="10"
-8<- "docs/codes/2024/0010/tls-certificates/aws-subdomain.yml"
```

```yaml title="tls-certificates/cloudflare-root.yml" hl_lines="10"
-8<- "docs/codes/2024/0010/tls-certificates/cloudflare-root.yml"
```

```yaml title="tls-certificates/kustomization.yml"
-8<- "docs/codes/2024/0010/tls-certificates/kustomization.yml"
```

```yaml title="tls-certificates/kustomize.yml"
-8<- "docs/codes/2024/0010/tls-certificates/kustomize.yml"
```

```shell title="" linenums="0"
kubectl apply -f tls-certificates/kustomize.yml
```

It'll take less than a minute to have the certificates issued and stored as
Kubernetes Secrets in the **same namespace as the cert-manager Deployment**.

If you would like the certificates in a different namespace, you're better off
creating Issuer instead of ClusterIssuer.

The final result will have a Secret with two keys: `tls.crt` and `tls.key`.
This will look similar to what you see below.

```yaml title=""
-8<- "docs/codes/2024/0010/junk/tls-certificates/manifests.yml"
```

## Step 3: Use the TLS Certificates in Gateway

At this point, we have the required ingredients to host an application within
cluster and exposing it securely through HTTPS into the world.

That's exactly what we aim for at this step. But, first, let's create a Gateway
CRD that will be the entrypoint to our cluster. The Gateway can be thought of
as the sibling of Ingress resource, yet more handsome, more successful, more
educated and more charming[^19].

The key point to keep in mind is that the Gateway API doesn't come with the
implementation. Infact, it is unopinionated about the implementation and you
can use any networking solution that fits your needs and **has support for it**.

In our case, and based on the personal preference and tendency of the author
:innocent:, we'll use [Cilium](/category/cilium/) as the networking solution,
both as the CNI, as well as the implementation for our Gateway API.

We have covered the [Cilium installation before][k3s-ubuntu], but, for the sake
of completeness, here's the way to do it[^20].

```yaml title="cilium/playbook.yml" hl_lines="27-28 44-46"
-8<- "docs/codes/2024/0010/cilium/playbook.yml"
```

And now, let's create the Gateway CRD.

```yaml title="gateway/gateway.yml" hl_lines="6 11 17 24 28"
-8<- "docs/codes/2024/0010/gateway/gateway.yml"
```

Notice that we did not create the `gatewayClassName`. It comes as
battery-included with [Cilium](/category/cilium/). You can find the
`GatewayClass` as soon as Cilium installation completes with the following
command:

```shell title="" linenums="0"
kubectl get gatewayclass
```

GatewayClass is to Gateway as IngressClass is to Ingress. :material-check-all:

Also note that we are passing the TLS certificates to this Gateway we have
created earlier. That way, the gateway will terminate and offload the SSL/TLS
encryption and your upstream service will receive plaintext traffic.

However, if you have set up your mTLS the way we did with Wireguard encryption
(or any other mTLS solution for that matter), node-to-node and/or pod-to-pod
communications will also be encrypted.

```yaml title="gateway/http-to-https-redirect.yml" hl_lines="11"
-8<- "docs/codes/2024/0010/gateway/http-to-https-redirect.yml"
```

Though not required, the above HTTP to HTTPS redirect allows you to avoid
accepting any plaintext HTTP traffic on your domain.

```yaml title="gateway/kustomization.yml"
-8<- "docs/codes/2024/0010/gateway/kustomization.yml"
```

```yaml title="gateway/kustomize.yml"
-8<- "docs/codes/2024/0010/gateway/kustomize.yml"
```

```shell title="" linenums="0"
kubectl apply -f gateway/kustomize.yml
```

## Step 4: HTTPS Application

That's all the things we aimed to do today. At this point, we can create our
HTTPS-only application and expose it securely to the wild internet!

```yaml title="app/deployment.yml"
-8<- "docs/codes/2024/0010/app/deployment.yml"
```

```yaml title="app/service.yml"
-8<- "docs/codes/2024/0010/app/service.yml"
```

```yaml title="app/httproute.yml" hl_lines="7-8"
-8<- "docs/codes/2024/0010/app/httproute.yml"
```

```ini title="app/configs.env"
-8<- "docs/codes/2024/0010/app/configs.env"
```

```yaml title="app/kustomization.yml"
-8<- "docs/codes/2024/0010/app/kustomization.yml"
```

```yaml title="app/kustomize.yml"
-8<- "docs/codes/2024/0010/app/kustomize.yml"
```


```shell title="" linenums="0"
kubectl apply -f app/kustomize.yml
```

That's everything we had to say for today. We can now easily access our
application as follows:

```shell title="" linenums="0"
curl -v https://echo.developer-friendly.blog -sSo /dev/null
```

or...

```shell title="" linenums="0"
curl -v https://aws.echo.developer-friendly.blog -sSo /dev/null
```

```plaintext title="Output of the curl command(s)" linenums="0"
...truncated...
*  expire date: Jul 30 04:44:12 2024 GMT
...truncated...
```

Both will show that the TLS certificate is present. signed by a trusted CA, is
valid and matches the domain we're trying to access. :tada:

You shall see the same expiry date on your certificate if accessing as follows:

```shell title="" linenums="0"
kubectl get certificate \
  -n cert-manager \
  -o jsonpath='{.items[*].status.notAfter}'
```

```plaintext title="Output of kubectl command" linenums="0"
2024-07-30T04:44:12Z
```

As you can see, the information we get from the publicly available certificate
as well as the one we get internally from our Kubernetes cluster are the same
down to the second. :muscle:

## Conclusion

These days, I am never spinning up a Kubernetes cluster without having
cert-manager installed on it as its day 1 operation task. It's such a
life-saver tool to have in your toolbox and you can rest assured that the TLS
certificates in your cluster are always up-to-date and valid.

If you ever had to worry about the expiry date of your certificates before,
those days are behind you and you can benefit a lot by employing the
cert-manager operator in your Kubernetes cluster. Use it to its full potential
and you shall be served greatly.

Hope you enjoyed reading this material.

Until next time :saluting_face:, *ciao* :cowboy: and happy hacking! :crab:
:penguin: :whale:

[^1]: https://certbot.eff.org/
[^2]: https://cert-manager.io/
[^3]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[^4]: https://www.cncf.io/
[^5]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[^6]: https://gateway-api.sigs.k8s.io/
[^7]: https://github.com/developer-friendly/blog/commit/eedf71d1f179a8a994a030e77c62f380440ed4d8
[^8]: https://squidfunk.github.io/mkdocs-material
[^9]: https://github.com/opentofu/opentofu/releases/tag/v1.7.0
[^10]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/
[^11]: https://fluxcd.io/flux/components/kustomize/kustomizations/
[^12]: https://cert-manager.io/docs/configuration/acme/dns01/
[^13]: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each#limitations-on-values-used-in-for_each
[^14]: https://cert-manager.io/docs/configuration/acme/dns01/route53/#set-up-an-iam-role
[^15]: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html
[^16]: https://github.com/cert-manager/cert-manager/issues/2147#issuecomment-2094066782
[^17]: https://github.com/aws/aws-sdk-go
[^18]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
[^19]: https://gateway-api.sigs.k8s.io/
[^20]: https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/

[k3s-ubuntu]: ./0005-install-k3s-on-ubuntu22.md
[ESO]: ./0009-external-secrets-aks-to-aws-ssm.md
[developer-friendly.blog]: https://developer-friendly.blog
