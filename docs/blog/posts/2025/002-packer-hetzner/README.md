---
date: 2025-01-20
draft: true
categories:
  - Packer
  - NixOS
  - Hetzner
  - Linux
  - Go
  - OpenTofu
  - Terraform
  - Infrastructure as Code
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
are targeting and where will you store your final snapshot image[^hetzner-snapshot].

```hcl title="nixos-hetzner.pkr.hcl" linenums="24"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl:24:38"
```

For every cloud provider, you will need to include the corresponding plugin
block.

```hcl title="nixos-hetzner.pkr.hcl"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl::8"
```

Now, funny enough, the `github.com/hetznercloud/hcloud` will not be an
accessible internet URL. Unlike, for example, [Go] packages, these are
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

This is where we define and customize our images, updating and upgrading
packages, installing new stuff, etc.

```hcl title="nixos-hetzner.pkr.hcl" linenums="40"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl:40:"
```

## Installing NixOS in Rescue Mode

Since we want to overwrite the current OS with the new [NixOS], we'll need to
take over the boot of the system and break into the [Hetzner] server rescue
mode[^hetzner-rescue].

That gives us the opportunity to write any OS to the current `/dev/sda` and
once restarted, boot into that new operating system.

That's exactly what this next step is all about.

Let's provide the config file first and go through the steps together.

```shell title="setup-nixos.sh"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh"
```

Take a good look at the script and worry not if you don't understand it fully,
cause neither do I. :nerd:

We are downloading the NixOS from the official channel, pinning it to exact
version as well as taking into account the current CPU architecture.

```shell title="setup-nixos.sh" linenums="9"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:9:9"
```

We then create the required user and group that need to be present before NixOS
installation.

```shell title="setup-nixos.sh" linenums="22"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:22:23"
```

We are also downloading the Nix packages and store them locally to be
referenced later on by the installer.

```shell title="setup-nixos.sh" linenums="25"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:25:28"
```

```shell title="setup-nixos.sh" linenums="45"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:45:46"
```

Notice the need for setting the proper environment variables. These env vars
are needed by the installer at the final step.

## Disk Partitioning

Since we are about to create a new OS on the target machine, we are bound to do
some partitioning.

Now, I know some might not like this tedious task, but let's just get over it,
shall we!?

```shell title="setup-nixos.sh" linenums="30"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:30:43"
```

The best part iof it all is that the `nixos-generate-config` will know about
these partitions and will create the corresponding
`/etc/nixos/hardware-configuration.nix` to be used by the installer.

```shell title="setup-nixos.sh" linenums="48"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:48:48"
```

## NixOS Configuration

One last step before we start the installation is to ensure a basic
configuration exists. Now, I'm no [NixOS] expert and this config is by far not
the best one, but it's a start.

```nix title="setup-nixos.sh" linenums="51"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:51:79"
```

Having this config in place, there's only one step left and that's the actual
[NixOS] installation.

```nix title="setup-nixos.sh" linenums="82"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:82:82"
```

This command will take somewhere north of 6 minutes to complete.

At the end, the server will be removed and you'll no longer be billed for it.

Additionally, the newly created snapshot will be available and billed
correspondingly. So, if you don't want to use it, make sure to remove it!
:money_mouth:

## Cleanups

Because we should be aiming for a minimal image footprint, we have to clean up
the mess we've made so far, making the final image lighter and more efficient.

```shell title="setup-nixos.sh" linenums="84"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/setup-nixos.sh:84:90"
```

```hcl title="nixos-hetzner.pkr.hcl" hl_lines="60"
-8<- "docs/blog/posts/2025/002-packer-hetzner/packer/nixos-hetzner.pkr.hcl:60:65"
```

## Caveats

This is all very good and educational, maybe even to a certain extent
entertaining.

But, is this the best way!? I can't be sure.

At the very least, I realized that without increasing the size of the server to
at least `cax31` would not give me enough disk storage in the rescue mode to
download and unsquash the Nix packages.

One might find a better way to do this without such compromise.

Especially knowing that the server type that you start with and create your
images on is the minimal spec of any future image you will be able to create
from that snapshot.

## Bonus

As a last token of appreciation to those of you who stuck around till this far,
I am providing the sample [OpenTofu] code that will be used to create [Hetzner]
servers from the created snapshot.

```terraform title="main.tf"
-8<- "docs/blog/posts/2025/002-packer-hetzner/hetzner-nixos-server/main.tf"
```

To apply this, we do business as usual:

```shell title="" linenums="0"
export HCLOUD_TOKEN="<your-hetzner-api-token>"
tofu init -upgrade
tofu plan -out tfplan
tofu apply tfplan
```

## Conclusion

We've seen how to create a [Hetzner] snapshot of one of the well-known [Linux]
distributions, [NixOS], using [Packer].

I'm just starting out and I gotta
take these baby steps before being able to run.

As for you, if you've learned and enjoyed this piece, that's fanstastic. And if
you know how to do this process better than me, please leave a comment down
below so that I can learn from you.

Until next time, *ciao* :cowboy: & happy coding! :penguin: :crab:

[Packer]: ../../../category/packer.md
[Hetzner]: ../../../category/hetzner.md
[NixOS]: ../../../category/nixos.md
[Linux]: ../../../category/linux.md
[Go]: ../../../category/go.md
[Ansible]: ../../../category/ansible.md
[OpenTofu]: ../../../category/opentofu.md

[^packer]: https://developer.hashicorp.com/packer/install
[^packer-terminology]: https://developer.hashicorp.com/packer/docs/terminology
[^hetzner-snapshot]: https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/
[^hetzner-rescue]: https://docs.hetzner.com/robot/dedicated-server/troubleshooting/hetzner-rescue-system/
