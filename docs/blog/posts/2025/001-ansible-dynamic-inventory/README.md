---
date: 2025-01-06
description: >-
  Learn how to create an Ansible dynamic inventory for AWS cloud, eliminating
  hard-coded IPs and leveraging cloud APIs for flexible infrastructure management.
categories:
  - Ansible
  - AWS
  - Configuration Management
  - Bastion Host
  - Automation
  - Best Practices
  - Cloud Computing
  - Cloud Infrastructure
  - Continuous Integration
  - DevOps
  - IaC
  - Infrastructure as Code
  - Jump Server
  - OpenTofu
  - OpenTofu
  - Python
  - Remote Access
  - Secure Cloud Access
  - SSH Security
  - Terraform
  - Terragrunt
  - Tutorial
links:
  - blog/posts/2024/0020-bastion-in-azure.md
  - blog/posts/2024/0003-kubernetes-the-hard-way.md
  - blog/posts/2024/0013-azure-vm-to-aws.md
image: assets/images/social/blog/2025/01/06/how-to-create-your-ansible-dynamic-inventory-for-aws-cloud/index.png
---

# How to Create Your Ansible Dynamic Inventory for AWS Cloud

Most of the modern software deployment these days benefit from containerization
and Kubernetes as the de-facto orchestration platform.

However, occasionally, I find myself in need of some Ansible provisioning and
configuration management.

In this blog post, I will share how to create Ansible dynamic inventory in a
way that avoids the need to write hard-coded IP addresses of the target hosts.

<!-- more -->

## Introduction

Dynamic Inventory is the technique that uses the cloud provider's API to fetch
the IP address, and some of the initial metadata about remote host(s) before
sending any request to the target(s).

This will allow us to fetch dynamically allocated private or public IP
addresses and use them as `ansible_host` in the inventory.

In a traditional Ansible setup, you would possibly see a host file like below:

```ini title="hosts.ini"
[aws]
1.2.3.4
5.6.7.8

[azure]
9.10.11.12
13.14.15.16
```

With the technique of dynamic inventory, not only will we not require to
memorize and/or hardcode those IP addresses, it also gives us the advantage and
flexibility of keeping our [Infrastructure as Code] (IaC) agnostic and
portable, to a certain extent!

## Prerequisites

- I use [Ansible] v2[^ansible] in these examples; `ansible-core` v2.18 to be
  explicit, as of writing.
- You can either follow along, or if you want to create the resources, you
  will need accounts in the [AWS] cloud provider.
- Although provisioning of the remote hosts are not the main aim of this
  article, I use [OpenTofu] v1.8[^opentofu] to create those instances.
- Lastly, I prefer to use [Terragrunt] `v0.x`[^tg-gh] as a nice wrapper around
  TF. This gives me the flexibility to define dependency and use
  outputs from other stacks.

The directory structure for this mini-project looks like the following:

```plaintext title="" linenums="0"
.
├── ansible
│   ├── ansible.cfg
│   ├── inventory
│   │   ├── cloud.aws_ec2.yml
│   │   └── group_vars
│   │       ├── all.yml
│   │       ├── aws_bastion.yml
│   │       ├── aws_worker.yml
│   │       └── provider_aws.yml
│   └── requirements.txt
├── asg
│   ├── cloud-init.yml
│   ├── main.tf
│   ├── net.tf
│   ├── outputs.tf
│   ├── terragrunt.hcl
│   ├── variables.tf
│   └── versions.tf
└── bastion
│   ├── cloud-init.yml
    ├── main.tf
    ├── net.tf
    ├── outputs.tf
    ├── terragrunt.hcl
    ├── variables.tf
    └── versions.tf
```

## AWS AutoScaling Group (ASG)

At this initial step, I will create an autoscaling group[^asg] with a
pre-defined and minimal launch template[^launch-template] using a
cloud-init[^cloudinit] YAML file.

This will include update and upgrading the host on the first boot, and
installing the latest available `python3` package (as required by our
[Ansible]).

Although not required, I will also create a custom AWS VPC[^vpc].

Additionally I will configure the [AWS] Security Group[^nsg] to allow SSH
access to **only** the hosts within the VPC, giving me the peace of mind that
secure access is gated behind private network[^vpn].

For an additional layer of security, one might want to consider deploying
AWS VPN!

With that said, let's roll up our sleeves & get our hands dirty. :nerd:

```terraform title="asg/versions.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/versions.tf"
```

```terraform title="asg/variables.tf" hl_lines="6"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/variables.tf"
```

```terraform title="asg/net.tf" hl_lines="53"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/net.tf"
```

```yaml title="asg/cloud-init.yml"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/cloud-init.yml"
```

```terraform title="asg/main.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/main.tf"
```

???+ tip "Generate SSH key pair"

    The most straightforward way is to use the `ssh-keygen` command:

    ```shell title="" linenums="0"
    ssh-keygen -t rsa -N '' -C 'Ansible Dynamic Inventory' -f ~/.ssh/ansible-dynamic
    ```

```terraform title="asg/outputs.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/outputs.tf"
```

```hcl title="asg/terragrunt.hcl"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/asg/terragrunt.hcl"
```

We create and apply this stack with the following command sequence[^tgdoc]:

```shell
export AWS_PROFILE="<your-profile>"
terragrunt init -upgrade
terragrunt plan -out tfplan
terragrunt apply tfplan
```

## Self-Managed Bastion Host

At this step, we will opt for a simple and minimal single instance [AWS]
EC2[^ec2].

This will be enough for our demo purposes but is surely not a good candidate
for production use.

```terraform title="bastion/versions.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/versions.tf"
```

```terraform title="bastion/variables.tf" hl_lines="6"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/variables.tf"
```

The variables above will be specified using the [Terragrunt]
dependency[^tg-deps] block as you will see shortly.

```terraform title="bastion/net.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/net.tf"
```

```yaml title="bastion/cloud-init.yml"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/cloud-init.yml"
```

```terraform title="bastion/main.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/main.tf"
```

```terraform title="bastion/outputs.tf"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/outputs.tf"
```

```hcl title="bastion/terragrunt.hcl"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/terragrunt.hcl"
```

We apply this just as we did for the ASG stack (no need to repeat ourselves).

## Ansible Dynamic Inventory

Now the fun part begins. We have the instances ready, and now can create our
inventory files and send requests to the remote hosts.

First step first, we'll create the `ansible.cfg` file in the `ansible`
directory:

```ini title="ansible/ansible.cfg"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/ansible.cfg"
```

Awesome! :partying_face:

We now need to create our [AWS] EC2 dynamic inventory file[^aws-dynamic-inventory].

```yaml title="ansible/inventory/cloud.aws_ec2.yml" hl_lines="1 4-5"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/cloud.aws_ec2.yml"
```

Note that the file name should end with `.aws_ec2.yml`, e.g.
`example.aws_ec2.yml`. Additionally, specifying the `plugin` attribute is
crucial for a reproducible and consistent behavior.

Pay close attention to the `keyed_groups` section. We'll use those when
targeting instances in our [Ansible] playbooks as well as ad-hoc commands.

As a required step at this point, we need to install some [Python] libraries.

```ini title="ansible/requirements.txt"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/requirements.txt"
```

```shell title="" linenums="0"
pip install -U pip -r ansible/requirements.txt
```

Let's go ahead and create a couple of [Ansible] `group_vars` files:

```yaml title="ansible/inventory/group_vars/all.yml"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/group_vars/all.yml"
```

The `all.yml` is a special name which refers to all hosts and the variables
inside will be available as Ansible facts[^facts].

```yaml title="ansible/inventory/group_vars/provider_aws.yml" hl_lines="2"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/group_vars/provider_aws.yml"
```

The `bastion_host` is a very critical variable which is getting one of the
*possibly* many bastion hosts randomly and using its available facts to get
connected to the other remote hosts in the private network (as you will see
shortly).

### Ansible Groups

Let's explain it step by step:

1. First, the `groups.aws_bastion` is resolving to all the remote hosts in the
   group `aws_bastion`. This group comes from our earlier `keyed_groups` where
   we prefixed `aws` to every tag named `inventory`.

    ```yaml title="ansible/inventory/cloud.aws_ec2.yml" linenums="3"
    -8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/cloud.aws_ec2.yml:3:5"
    ```

    ```terraform title="bastion/variables.tf" hl_lines="6"
    -8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/bastion/variables.tf:1:9"
    ```

    The result will be something like the following. Notice the groupings that took
    place because of how we set the `keyed_groups` configuration.

    ```shell title="" linenums="0"
    $ ansible-inventory --graph
    @all:
      |--@ungrouped:
      |--@aws_ec2:
      |  |--ip-10-0-2-166.eu-central-1.compute.internal
      |  |--ip-10-0-3-239.eu-central-1.compute.internal
      |  |--ec2-3-69-93-166.eu-central-1.compute.amazonaws.com
      |  |--ip-10-0-1-52.eu-central-1.compute.internal
      |--@aws_worker:
      |  |--ip-10-0-2-166.eu-central-1.compute.internal
      |  |--ip-10-0-3-239.eu-central-1.compute.internal
      |  |--ip-10-0-1-52.eu-central-1.compute.internal
      |--@provider_aws:
      |  |--ip-10-0-2-166.eu-central-1.compute.internal
      |  |--ip-10-0-3-239.eu-central-1.compute.internal
      |  |--ec2-3-69-93-166.eu-central-1.compute.amazonaws.com
      |  |--ip-10-0-1-52.eu-central-1.compute.internal
      |--@aws_bastion:
      |  |--ec2-3-69-93-166.eu-central-1.compute.amazonaws.com
    ```

    **Fun fact**: I didn't trim the output of this command. [Ansible] doesn't close
    the vertical lines on the left as `tree` command does! :grin:

2. The `groups.aws_bastion` will get piped to the `random` and one will get
   selected: `groups.aws_bastion | random`. The result will be Ansible host
   vars[^hostvars].

    ```yaml title="ansible/inventory/group_vars/provider_aws.yml" linenums="2"
    -8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/group_vars/provider_aws.yml:2"
    ```

3. We do some unavoidable juggling to produce a dot-accessible Ansible variable
   from that output. The result will allow us to reference the Ansible
   Facts[^facts] e.g. `bastion_host.ansible_host`. You will see this shortly.

## Bastion Proxy Jump

In this final step of the preparation, we set the connect address of the
bastion to be the public IP address attached to the host (the [AWS]
ElasticIP[^eip]), as opposed to the other remote hosts in the VPC where we will
use the private IP addresses.

```yaml title="ansible/inventory/group_vars/aws_bastion.yml"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/group_vars/aws_bastion.yml"
```

Notice the value of the `ansible_host` variable. We will ensure that all the
connections to the bastion host are using that public IP address.

It's now time to configure all the other remote hosts in our VPC, this time,
we'll use private IP address for connection.

However, we can't directly connect to their private IP address and that's where
the bastion host is gonna come in-between, playing as a proxy jump, an extra
hop if you will.

Notice the double-quotation of `ProxyCommand` in the following group vars
file[^inventory-bastion].

```yaml title="ansible/inventory/group_vars/aws_worker.yml" hl_lines="1"
-8<- "docs/blog/posts/2025/001-ansible-dynamic-inventory/ansible/inventory/group_vars/aws_worker.yml"
```

Take a close look at how we are using `bastion_host.FACT` to access all the
facts available to us from the bastion remote host.

These facts are all available from the [AWS] API before we send a single
request to any of the target hosts.

To see that for yourself, run `ansible-inventory --list` in the `ansible/`
directory.

A JSON formatted output will be displayed, showing all the available facts
about the remote hosts, all available through AWS API and before sending any
requests to any of the target hosts.

## Verify the Setup

Let us do a sample ad-hoc command:

```shell title="" linenums="0"
$ ansible -m ping all
ec2-3-69-93-166.eu-central-1.compute.amazonaws.com | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ip-10-0-2-166.eu-central-1.compute.internal | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ip-10-0-1-52.eu-central-1.compute.internal | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}
ip-10-0-3-239.eu-central-1.compute.internal | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}
```

And that sums it all up.

We wanted to create a dynamic inventory for our [AWS] cloud, and we did it.
:clap:

## Conclusion

Although the use of Ansible is not as prevalent as it used to be, it may still
be crucial to do some configuration management on your target hosts.

Instead of manually adding hard-coded IP addresses to your inventory, Ansible
dynamic inventory allows you to use API calls to your cloud provider to fetch
metadata and variables about the target hosts.

The end result will be a more flexible and portable IaC, which can be used
even if the remote host has been re-imaged or replaced with a new set of
variables and facts.

I can definitly see myself coming back to this article in a future. :wink:

Until next time, *ciao* :cowboy: & happy coding! :penguin: :crab:

[Ansible]: ../../../category/ansible.md
[Infrastructure as Code]: ../../../category/infrastructure-as-code.md
[OpenTofu]: ../../../category/opentofu.md
[AWS]: ../../../category/aws.md
[Terragrunt]: ../../../category/terragrunt.md
[Python]: ../../../category/python.md

[^ansible]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
[^opentofu]: https://github.com/opentofu/opentofu/
[^tg-gh]: https://github.com/gruntwork-io/terragrunt
[^asg]: https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html
[^launch-template]: https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html
[^cloudinit]: https://cloudinit.readthedocs.io/en/latest/
[^vpc]: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
[^nsg]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html
[^vpn]: https://docs.aws.amazon.com/vpc/latest/userguide/vpn-connections.html
[^tgdoc]: https://terragrunt.gruntwork.io/docs/
[^ec2]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html
[^tg-deps]: https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#dependency
[^aws-dynamic-inventory]: https://docs.ansible.com/ansible/latest/collections/amazon/aws/docsite/aws_ec2_guide.html
[^facts]: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html
[^hostvars]: https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
[^eip]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[^inventory-bastion]: https://www.adainese.it/blog/2022/10/30/ansible-with-bastion-host/
