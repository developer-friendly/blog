---
date: 2024-02-15
draft: false
description: >-
  Learn how Azure facilitates immutable infrastructure with The Azure Compute
  Gallery to reuse and share VM images across different regions.
categories:
  - Azure
  - Cloud Computing
  - OpenTofu
  - IaC
---

# Azure Shared Image Gallery

In recent years, Azure Cloud has provided the capability to share the VM images
between regions, allowing you to create a Golden Image once and share it,
whether publicly for the community, or privately within your organization.

Though, not the AzureRM OpenTofu provider, nor the Azure documentation, has
a clear working example you can refer to. This is why I am sharing my
struggle, so that you don't have to go through the same.

<!-- more -->

## Creating the Linux VM

First things first, we need to creat the Virtual Machine. I create the Linux VM
using the example provided in the OpenTofu Registry.

```hcl title="compute-v1.tf"
-8<- "docs/codes/0001-azure-image-gallery/sample-only/compute-v1.tf"
```

This setup works just alright, except that it has no public IP address and I
won't be able to SSH into machine for any possible reason.

This public access will also require a proper firewall rule.

On top of that, it also will require a public SSH key for the authentication.

That's why, the modified version will look like the following.

```hcl title="compute-v2.tf" hl_lines="20-27 39 43-53 68 84-110"
-8<- "docs/codes/0001-azure-image-gallery/compute-v2.tf"
```

Perfect! Now I have a VM machine in my Azure account that I can SSH into for
further customization before creating the image.

## Customize the VM

To keep things simple, let's just install a MongDB community edition on it and
be on with it.

I am using ansible here, but you're free to SSH directly into the machine and
run the ad-hoc commands.

Before being able to run Ansible on the target machine, I will need to create
my inventory.

```hcl title="inventory.tf"
-8<- "docs/codes/0001-azure-image-gallery/inventory.tf"
```

And now, I can either use null resource, or run the `ansible-playbook` from the
CLI. I prefer the former, since it is replicatable across runs.

```hcl title="playbook.tf"
-8<- "docs/codes/0001-azure-image-gallery/playbook.tf"
```

### Installing the MongoDB

One last piece to customize the VM is to install the dependencies we need.
Here's the playbook I am using.

```yaml title="bootstrap.yml"
-8<- "docs/codes/0001-azure-image-gallery/bootstrap.yml"
```

That's it. After applying this stack with `tofu apply`, I will have a
[generalized VM](https://learn.microsoft.com/en-us/azure/virtual-machines/generalize)
ready to take a VM image from.

The generlization is something you should consider for yourself, as there are
pros and cons to having either a generalized or a specialized image. For the
purpose of this article, I am using a generalized VM image because there is
nothing special about my image, nor do I have any of the [conditions that will
stop me](https://learn.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries)
from having such an image.

## Create the Image

Running the stack so far will create a generalize VM, with my special dependencies
installed. Now I am ready to create an image from it.

One requirement here is that I want to be able to use this image in other
Azure regions. At the time of writing, the Azure cloud has recently provided
[the Azure Compute Gallery](https://learn.microsoft.com/en-us/azure/virtual-machines/azure-compute-gallery)
that will allow to replicate the same image across different regions.


The alternative is to create the same image in each region, which is an obvious
waste of resource and money.

Let's create the image with the following resources.

```hcl title="image-v1.tf"
-8<- "docs/codes/0001-azure-image-gallery/sample-only/image-v1.tf"
```

Now this is where it gets tricky, because so far, this will only create the
gallery and an image definition only. It doesn't give you the image, nor does
it allow you to create VM instances out of it later on.

For that, you will need to create an image version.

```hcl title="image-v2.tf" hl_lines="32-44"
-8<- "docs/codes/0001-azure-image-gallery/sample-only/image-v2.tf"
```

Now, you might go happy about it and call it a day. But this will throw an error
with the following content.

```bash
│ "managed_image_id": one of `blob_uri,managed_image_id,os_disk_snapshot_id`
│ must be specified
```

### Troubleshooting

What does this mean then in simple English?

In simple terms, it means that the "version" you are trying to create, will
actually be a simple tag. Think of Docker tags if it helps with the analogy.

But the whole point of this article is that you will not get through without
creating and actual `azurerm_image` resource. That is the true image that will
be created underneath. Without that, you cannot have an image version.

Again, if it helps with the analog, imagine trying to create a docker tag without
having the image in the first place.

That's what this whole thing is about.

And to get around it, you will need to create the image as well.

Just as you see below.

```hcl title="image-v3.tf" hl_lines="32-37 45"
-8<- "docs/codes/0001-azure-image-gallery/image-v3.tf"
```

## Versions

To help with reproducibility, I will include the versions of the providers in
this post.

```hcl title="versions.tf"
-8<- "docs/codes/0001-azure-image-gallery/versions.tf"
```

## Source Code

The code for this post is available from the following link.

[Source code](https://github.com/developer-friendly/blog/blob/main/docs/codes/0001-azure-image-gallery)

## Conclusion

That pretty much solves everything. I can't imagine having done it this way.
But hey, this is Azure cloud we're talking about.

The things I've seen in Azure are the kind that I haven't seen elsewhere.

In no particular order, and in a non-exhaustive list, here are some horror stories:

- Creating a parent and a child resource, updating the parent which forces a
replacement and then the provided complains not being able to delete the parent
because the child is still referencing it. I mean, isn't the whole point of
[IaC](/category/iac/) to be able to create, update and delete resources and the
underlying provider takes care of the ugly work for you!?
- The Azure Kubernetes module creates a child resource group for you, and for
any other node-pool you want to add to the cluster, you can't create a separate
resource group, but rather, you gotta reference the same resource group to create
the new node-pool. :exploding_head:

Some of these would have been fine if we weren't promised that
[IaC](/category/iac/) tools such as OpenTofu are supposed to protect you from a
need to get into the Azure portal and do the manual chores yourself, the same
chore the provider should've done for you.

But that's whole point. We were promised that it's all gonna be the responsibility
of the underlying provider. That's wrong! At least in the case of Azure.
:disappointed_relieved:
