---
date: 2025-01-20
draft: true
categories:
  - Packer
  - NixOS
  - Hetzner
  - Linux
  - Go
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

I have been on the sidelines for a long time, waiting for an opportunity to dip
my toes into the [NixOS] ecosystem.

I have been hearing a lot of good things about it and I wanted to see what the
fuss was all about.

Additionally, I have been using [Hetzner] Cloud for a while now, both
personally and professionally in production setups.

I thought it would be a good idea to combine the two and see what I can come up
with.

## Prerequisites

- Packer v1.11 installed on your local machine[^packer]
- Hetzner Cloud account with an API token
    - Use my referral code to get €20 in credits :grimacing::
      <https://hetzner.cloud/?ref=ai5E5vaX1J71>

## Getting Started

There are various ways of installing [NixOS], and I found it somehow confusing
that the docs are scattered all over the internet, not making it easy for
beginners to get started.

High barrier to entry is perhaps one of the reasons why NixOS is not as
wide-spread as other [Linux] distributions!

## Packer Configuration

Let us jump straight into it, cause there ain't much pre-work needed.

If you know, you know, and if you don't, I'll explain the file as much as
possible in a bit.

```hcl title="nixos-hetzner.pkr.hcl" hl_lines="44"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl"
```

Not a lot of excitement is happening here and the main part of the deal is that
`setup-nixos.sh` file in the same working directory.

However, before we go over the shell script, let's briefly explain [Packer]
concepts for those unfamiliar with it.

### Packer Concepts

There are, generally speaking, two main components to each Packer configuration
file, whether you write it in the HCL language or the JSON
format[^packer-terminology].

The first component is the `source` block, specifying which cloud provider you
are targeting and where will you store your final snapshot image.

```hcl title="nixos-hetzner.pkr.hcl" linenums="24"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl:24:38"
```

For every cloud provider, you will need to include the corresponding plugin
block.

```hcl title="nixos-hetzner.pkr.hcl"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl::8"
```

Now, funny enough, the `github.com/hetznercloud/hcloud` will not be an
accessible internet URL. Unlink, for example, [Go] packages, these are
arbitrary names assigned to the plugin.

Once you define your plugins, you got to import its files using `packer init`.
This command needs to run in the same directory as your `*.pkr.hcl` file.

```shell title="" linenums="0"
$ ls -1
nixos-hetzner.pkr.hcl
setup-nixos.sh
$ packer init .
# no output
```

### Packer Build

The second building block of [Packer] configuration file is the `build` block.

Regardless of which `source` you  are using, you can define your `build` block
agnostic of the cloud provider, having custom and arbitrary shell scripts,
[Ansible] playbooks, etc.

This where we define and customize our images, updating and upgrading packages,
installing new stuff, etc.

```hcl title="nixos-hetzner.pkr.hcl" linenums="40"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl:40:"
```

[Packer]: ../../../category/packer.md
[Hetzner]: ../../../category/hetzner.md
[NixOS]: ../../../category/nixos.md
[Linux]: ../../../category/linux.md
[Go]: ../../../category/go.md
[Ansible]: ../../../category/ansible.md

[^packer]: https://developer.hashicorp.com/packer/install
[^packer-terminology]: https://developer.hashicorp.com/packer/docs/terminology
