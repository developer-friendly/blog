---
draft: true
date: 2024-10-14
description: >-
  Learn how to secure admin pages and any web app interface using Ory
  Oathkeeper & Kratos, providing robust authentication without the need for
  built-in auth layers.
# social:
#   cards_layout_options:
#     description: >-
#       todo
categories:
  - Authentication
  - Cloud Security
  - DevOps
  - GitOps
  - IaC
  - IAM
  - Infrastructure as Code
  - Kratos
  - Microservices
  - Monitoring
  - OAuth2
  - OIDC
  - OpenID Connect
  - Ory
  - Oathkeeper
  - Security
  - Tutorial
# links:
#   - Source Code: https://github.com/developer-friendly/aws-lambda-opentofu-github-actions/
#   - ./blog/posts/2024/0007-oidc-authentication.md
# image: assets/images/social/2024/09/02/how-to-deploy-nodejs-to-aws-lambda-with-opentofu--github-actions.png
# rss:
#   feed_description: >-
#     todo
---

# Secure Any Web App with Ory Oathkeeper and Kratos

In today's digital landscape, protecting sensitive administrative interfaces
is crucial for organizations delivering services over the internet. This guide
offers a practical approach to implementing secure, authenticated access for
admin pages using Ory's proxy and authentication (micro)services.

We'll explore how to leverage Ory Oathkeeper and Kratos to create a robust
authentication system that aligns with current security best practices and
regulatory requirements.

If you're looking for an efficient way to enhance the security of your admin
services, you'll find value in the steps outlined here.

<!-- more -->

## Introduction: Securing Admin Access in the Digital Age

Behind the scenes of every successful digital service, is a team of expert
IT professionals trying to maintain the platform and the underlying services.
While those services are crucial to the success of the business, they also
represent a potential security risk if not properly protected.

Admin pages are a prime target for malicious actors looking to exploit
vulnerabilities in the system. By securing these pages with robust
authentication mechanisms, you can significantly reduce the risk of
unauthorized access and data breaches.

## Understanding the Need for Gated Authentication

Since we're living in the age of network and connectivity, it's essential to
implement a secure authentication system that can scale with your business
needs.

Furthermore, by providing a protected access to your upstream services, you
will enable the non-IT professionals to focus on their tasks without worrying
about common matters such as credential rotations, access control, and
compliance.

This is where Ory Oathkeeper and Kratos come into play.

The combination of the two allow for any internet business to implement
secure, scalable, and compliant authentication and authorization mechanisms
that can be easily integrated into existing systems.

By using these services, you won't have to reinvent the wheel to protect the
upstream applications, and instead, you will configure the said services in a
way that can forward the internet traffic if only certain authn & authz
policy/condition(s) are met.

That said, with these two services (and an additional Ory keto if you need),
you don't even have to implement an authentication layer on top of your app.
Imagine having to only focus on the business logic of your app, not worrying if
you gave a certain endpoint the right access control or not.

This should all excite you, cause it should as hell excites me to know that in
my day to day system administration job, I won't have to ask the developers of
my application, or a third-party off the shelf software, to implement a certain
authentication mechanism for me. I can just as well protect any endpoint I want
the way I want it! That's the true power right there.

## Introducing Ory Oathkeeper and Kratos: Powerful Authentication Tools

```mermaid
sequenceDiagram
    participant User
    participant Oathkeeper as Ory Oathkeeper
    participant Kratos as Ory Kratos
    participant Service as Upstream Service

    User->>Oathkeeper: GET /admin/users
    Oathkeeper->>Kratos: Check authentication
    alt is authenticated
        Kratos->>Oathkeeper: User logged in
        Oathkeeper->>Service: Forward request
        Service->>Oathkeeper: Response
        Oathkeeper->>User: Forward response
    else is not authenticated
        Kratos->>Oathkeeper: Authentication invalid
        Oathkeeper->>User: 401 Unauthorized
    end
```

Ory Oathkeeper is a powerful proxy that acts as a gatekeeper for your
services, enforcing access control policies and handling authentication
requests. In doing so, Oathkeeper receives all the incoming traffic from the
outside world, and by consulting the configured authentication and
authorization services, decides whether to allow or deny access to the
requested resource.

In addition, Ory Oathkeeper does not only bind to Ory Kratos, or any of the
other Ory services for that matter, as you would normally see other big
companies usually playing out their cards, tightening you to their core
services one after the other, just to suck you in in all their ecosystem,
getting every single dime out of you possible :money_mouth:.

Kratos, on the other hand, is a flexible and extensible identity management
system that provides user registration, login, and account recovery. In its
latest release (v1.3 as of the time of writing[^kratos-v1.3]), it comes with
many great features and improvements that make it a perfect fit for modern
infrastructures.

I use Ory Kratos for most of my admin pages, especially the ones that do not
have a native support for authentication, but also the ones that possibly do
and do not yet have support for better authentication mechanisms such as
Social Login, WebAuthn, or Passwordless.

## The Benefits of Secure Admin Pages for IT Professionals

Why should you care about having a secure access to your applications?

Why would you want to add yet another service to your (already complex) setup?

The reason is quite simple really.

There are many malicious actors and adversaries out there who are looking to
exploit any vulnerability they can find in your system.

It's not necessarily that they are bad people (although some of them are
:man_facepalming_tone2:), but, in reality, most are just trying to make a
living (no judgment here :shrug:).

As such, taking a proactive approach is crucial to ensure you're staying ahead
of the curve and protecting your business from potential threats. You wouldn't
want your company to be vulnerable out in the wild, now would you?

To keep things platonic, here's a list of things that are advantageous to
you and your team when you enforce authenticated and protected access to your
upstream services (admin page or otherwise):

- [x] :shield: **Compliance**: By implementing secure access controls, you can
      ensure that your organization meets the necessary compliance standards
      and regulations.
- [x] :closed_lock_with_key: **Security**: Protecting your admin pages with
      robust authentication mechanisms helps prevent unauthorized access and
      data breaches.
- [x] :chart_with_upwards_trend: **Scalability**: Ory Oathkeeper and Kratos are
      designed to scale with your business needs, ensuring that you can handle
      increased traffic and user demand. Both are completely stateless and can
      scale horizontally as well as vertically.
- [x] :wrench: **Maintenance**: By using these services, you can reduce the
      burden on your IT team and simplify the process of managing access
      controls and security policies.
- [x] :man_cartwheeling: **Flexibility**: Ory Oathkeeper and Kratos are highly
      flexible and extensible, allowing you to customize the authentication and
      authorization mechanisms to suit your specific requirements.
- [x] :sparkles: **Feature Rich**: Ory services come with many built-in
      features natively supported out of the box. To name just a few of Ory
      Kratos' latest features, passkey, webauthn, and passwordless
      authentication are just a few.

## Step-by-Step Guide: Implementing Ory Proxy for Admin Access

To start using the Oathkeeper & Kratos, we first need to deploy their services
into our infrastructure. There are various ways you can achieve this step which
highly depends on your current setup.

For the purpose of demonstration, we'll use an in-house Kustomization stack
created before writing this blog post. The reason we are not following the
crowd and using Helm is that I've personally seen many inflexibility in the
upstream and official Helm chart of both Ory Oathkeeper and Kratos (and
others). Example includes the ability to fetch secrets from [External Secrets]
Operator, or the ability to take control of the server config file in full.

I have gone ahead and created a Kustomization stack[^kustomizations] that
allows me more wiggle room and can be easily customized and integrated into any
of the current Kubernetes clusters with just a few lines of code.

These flexibilities can be cumbersome to overcome when you use the official
Helm chart. However, if you still find those Charts useful, by all means,
go ahead and use them.

Additionally for a complete guide on Ory Oathkeeper and Ory Kratos, head over
to their corresponding guide in our archive below:

- [x] [Ory Kratos: Headless Authentication, Identity and User Management]
- [x] [Ory Oathkeeper: Identity and Access Proxy Server]

!!! tip "Hot Take: Kustomization vs. Helm"

    I am one of those under-rock people who believe that Kustomization is
    superior to Helm.

    My reason is that I find the Kubernetes-native language of Kustomization
    and the YAML manifests much more intuitive.

    Additionally, I find Kustomization patches[^kust-patches] and
    replacements[^kust-replacement] to be far better in its flexibility and
    customizability.

    Lastly, the Helm is a templating language, one that requires its own
    learning curve.

    I am not unhappy learning new things, I just don't enjoy Helm (or Go)
    templating language.

    There is literally nothing you CANNOT do with Kustomization (that the Helm
    would).

### Prerequisites

If you want to follow along with this guide, here are the list of tools you
need:

- [x] A Kubernetes cluster (v1.31 as of writing)
- [x] Accessible endpoint to the cluster (ingress controller, LoadBalancer, etc)

### A Local Kubernetes Cluster

For a quick win of the day, let's spin up a k3d Kubernetes cluster. Quite easy
to setup, quite easy to work with, low barrier to entry.

```yaml title="k3d-config.yml"
--8<-- "docs/blog/codes/2024/0022/k3d-config.yml"
```

### Deploying Ory Oathkeeper

It's simpler to deploy Oathkeeper initially and that's where we start.

```yaml title="oathkeeper-values.yml"
-8<- "../../codes/2024/0022/oathkeeper-values.yml"
```

```bash title="" linenums="0"
helm repo add ory https://k8s.ory.sh/helm/charts
helm install oathkeeper ory/oathkeeper \
  --version 0.49.x \
  --values oathkeeper-values.yml
```

### Deploying Ory Kratos

Kratos' deployment is more involved and requires a bit of configuration.


## Leveraging Ory Authentication Microservices for Enhanced Security

## Compliance and Best Practices: Meeting Modern Security Standards

## Case Study: Real-World Implementation of Ory Oathkeeper and Kratos

## Troubleshooting Common Issues in Admin Page Security

## Future-Proofing Your Admin Access: Scalability and Maintenance

## Conclusion: Empowering IT Teams with Secure Admin Capabilities

[^kratos-v1.3]: https://github.com/ory/kratos/releases/tag/v1.3.0
[^kustomizations]: https://github.com/meysam81/kustomizations/tree/v1.4.1
[^kust-patches]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/
[^kust-replacement]: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/replacements/

[Ory Kratos: Headless Authentication, Identity and User Management]: ./0012-ory-kratos.md
[Ory Oathkeeper: Identity and Access Proxy Server]: ./0015-ory-oathkeeper.md
[External Secrets]: ../../category/external-secrets.md
