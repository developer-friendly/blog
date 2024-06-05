---
date: 2024-06-10
description: >-
  TODO
categories:
  - Ory
  - Authentication
  - Authorization
links:
  - Source Code: https://github.com/developer-friendly/ory/
image: assets/images/social/2024/06/10/ory-oathkeeper-identity-and-access-proxy-server.png
---

# Ory Oathkeeper: Identity and Access Proxy Server

Ory has a great ecosystem of products when it comes to authentication and
authorization. Ory Oathkeeper is an stateless Identity and Access Proxy server.

It is capable of acting as a reverse-proxy as well as a decision maker and
policy enforcer for other proxy servers.

In today's application development world, if you're operating on HTTP layer,
Ory Oathkeeper has a lot to offer to you.

Stick around to find out how.

<!-- more -->

## What is Ory Oathkeeper?

Chances are, your application needs protection from unauthorized access,
whether deployed into the internet and exposed publicly, or gated behind
private network and only accessible to a certain privileged users.

That is what Ory Oathkeeper is good at, making sure that requests won't make
it to the upstream unless they are explicitly allowed.

It enforces protective measures to ensure unauthorized requests are denied.
It does that by sitting at the frontier of your infrastructure, receiving
traffics as they come in, inspecting its content, and making decisions based
on the rules you've previously defined and instructed it to.

In this blog post, we will explore what Ory Oathkeeper can do & deploy
and configure it in a way that will protect our upstream server.

This use-case is very common and you have likely encountered it or implemented
a custom solution for you application.

Stick around till the end to find out how to leverage the opensource solution
to your advantage so that you won't ever have to reinvent the wheel.

## Why Ory Oathkeeper?

There are numerous reasons why Oathkeeper is a good fit at what it does. Here
are some of the highlights you should be aware of:

- [x] **Proxy Server**: One of the superpower of Oathkeeper is its ability to
  sit at the frontier of your infrastructure and denying unauthorized requests.
  :rocket:
- [x] **Decision Maker**: Another mode of running Ory Oathkeeper is to use
  it as a policy enforcer, making decisions on whether or not a request should
  be granted access based on the defined rules. :shield:
- [x] **Open Source**: Ory Oathkeeper is open source with a permissive license
  , meaning you can inspect the source code, contribute to it, and even fork it
  if you want to. This is a good thing because it gives you the freedom to do
  whatever you want with the software. :flag_white:
- [x] **Stateless**: Ory Oathkeeper is stateless, meaning it doesn't store any
  session data. This is a good thing because it makes it horizontally scalable
  and easy to deploy in a distributed environment. :airplane:
- [x] **Pluggable**: Ory products are adhering to plugin architecture; you can
  use all of them, some of them, or only one of them. This allows a lot of
  flexibility when migrating from a current solution or integrating with a
  third party service. :electric_plug:
- [x] **Full Featured**: It comes with batteries included, providing
  experimental support for gRPC middleware (if you're into Golang), and also
  stable support for WebSockets. :battery:
- [x] **Community**: Ory has a great community of developers and users. If you
  ever get stuck, you can always ask for help in the community Slack
  channel[^ory-slack]. :handshake:

In short and more accurately put, Ory Oathkeeper is a Identity and Access
Proxy (IAP for short)[^oathkeeper-intro]. You will see later in this post how that comes into
play.

!!! note "Disclaimer"

    This blog post is not sponsored by Ory. I'm just a happy user of their
    products and I want to share my experience with you.

## How Does Ory Oathkeeper Work?

There are two modes of operation for Ory Oathkeeper:

1. **Reverse Proxy Mode**: Accepting raw traffics from the client and
   forwarding it to the upstream server.
2. **Decision Maker Mode**: Making decisions whether or not a request should
   be granted access. The frontier proxy server will query the decision API of
   Oathkeeper to grant or deny a request.

Both of these modes rely solely on the API access rules written in
human-readable YAML format. You can pass multiple rules to be applied for
multiple upstream servers or backends.

After this rather long introductory, let's get our hands dirty and roll up
our system administration sleeves.

## Deploying Ory Oathkeeper

There are different ways to deploy Oathkeeper and it highly depends on your
infrastructure more than anything else.

In this blog post, we will refrain from using Docker Compose as that is
something publicly available in the corresponding
repository[^oathkeeper-repository] and example repository[^ory-examples].

Instead, we will share how to deploy Ory Oathkeeper in a [Kubernetes] cluster
using [FluxCD]. We have in-depth guide on both topics in our archive if you're
new to them.

[^ory-slack]: https://slack.ory.sh/
[^oathkeeper-intro]: https://www.ory.sh/docs/oathkeeper/
[^oathkeeper-repository]: https://github.com/ory/oathkeeper
[^ory-examples]: https://github.com/ory/examples

[Kubernetes]: /category/kubernetes/
[FluxCD]: /category/fluxcd/
