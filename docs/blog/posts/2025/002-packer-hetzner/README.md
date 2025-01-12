---
date: 2025-01-12
draft: true
---

# Packer: How to Build NixOS 24 Snapshot on Hetzner Cloud

Packer is a powerful tool to create immutable images, with support for various
cloud providers.

In this blog post, I share how I built a NixOS 24 snapshot using Packer on
Hetzner Cloud.

If you're a fan of NixOS or want to learn more about Packer, this post is for
you.

<!-- more -->

## Introduction

I have been on the sidelines waiting for an opportunity to dip my toes into the
NixOS ecosystem.

I have been hearing a lot of good things about it and I wanted to see what the
fuss was all about.

Additionally, I have been using Hetzner Cloud for a while now, both personally
and professionally in production setups.

I thought it would be a good idea to combine the two and see what I can come up
with.

## Prerequisites

- Packer v1.11 installed on your local machine[^packer]
- Hetzner Cloud account with an API token
    - Use my referral code to get €20 in credits :grimacing::
      <https://hetzner.cloud/?ref=ai5E5vaX1J71>

## Getting Started

There are various ways of installing NixOS, and I found it somehow confusing
that the docs are scattered all over the internet, not making it easy for
beginners to get started.

High barrier to entry is perhaps one of the reasons why NixOS is not as
wide-spread as other Linux distributions!

## Packer Configuration

If you know, you know, and if you don't, I'll explain the file as much as
possible in a bit.

```hcl title="nixos-hetzner.pkr.hcl"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl"
```

[^packer]: https://developer.hashicorp.com/packer/install
