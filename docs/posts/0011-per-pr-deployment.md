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
  - GitOps
  - IaC
  - Infrastructure as Code
  - OAuth2
  - OpenID Connect
  - OIDC
  - Security
---

# Per-PR Deployment (think of a better name)

You have most likely seen Netlify giving you a preview URL using which you can
inspect your applications and verify the changes you've made to the codebase
are the ones you intended.

The same idea can be achived for backend applications (and even frontend ones)
using Kubernetes, dynamic DNS & wildcard certificates.

If you like to see how to expose pr123.test.example.com, buckle up cause this
is about to get really exciting!

<!-- more -->

## Introduction

Netlify has spoiled us a little, I admit. For any piece of frontend code that
I get in touch with, even if it is't meant to be deployed and delivered to
production through Netlify, I still use its preview feature to understand how
the upcoming changes will look like.

In fact, the CI pipeline of [developer-friendly.blog] is written in a way that
prints out a preview URL if a new pull-request is opened against the `main`
branch. Take a look at [the source code if you're interested].

Let's see why this is an important feature to have and to implement in any
infrastructure and continuous delivery pipeline.

## Why? No Really

This is a truly powerful mechanism in which you will see the live preview
version of the modified app before it gets merged.

What do you get in return?

1. There comes a time where you don't want or can't deploy the new version of
   the app to see the changes; perhaps due to constraint resource or maybe
   because you're not behind a workstation.
2. The live preview URL can be shared with your colleagues so taht everyone
   gets to see the same version of the app. No more "it works on my machine"!
3. If you plan this right, you may also benefit from compute cost optimization;
   for example, if you deploy your preview application next to your dev
   instance, you're benefiting a lot from the idle resources in your
   infrastructure.
4. The deployed application in the live preview will stay up for as long as
   you require. Your teammates can be on different timezones and you won't have
   to wait for a build to finish before sharing your changes with them. They
   will have access to the deployed app as soon as it's up and running.
5. If you employ techniques such as traffic-mirroring, you'll be able to verify
   the integrity and correctness of your changes with the live traffic from
   your users. This gives you a clear picture on whether your changes have
   actually improved the app and whether or not there was a regression.
6. It's not just your technical colleagues who can test your changes. You shall
   be able to pass the preview URL to your sales and/or product team and they
   will tell you whether or not the changes are aligned with the business
   requirements.
7. The author of the change, as well as every one else in the team will not
   have to wait for a production release to see the changes. Although other
   practices such as trunk-based development and continuous delivery are
   also targetting this issue, the live preview URL is a great alternative for
   teams who don't lean towards these practices.

## But, How?

I hope that you are convinced of the true power this approach brings to the
table (I can't do a better job if you aren't).

If that got you interested and want to learn more, stick around till the end
so that I can prove my case with a concrete example of such a setup.

The idea is to do whatever it needs doing to build the app and deploy it
somewhere. The requirement is that the target environment needs to have all
the dependencies prepared (e.g. database, cache, etc.).

Ultimately, using a previously fetched wildcard certificate and wildcard DNS
record, we will assign the preview URL to the app and comment it on the pull
request.

[the source code if you're interested]: https://github.com/developer-friendly/blog/blob/bb44aa926007e2fd3fd09dcc9dfc197c244cfd6b/.github/workflows/ci.yml#L53-L73
