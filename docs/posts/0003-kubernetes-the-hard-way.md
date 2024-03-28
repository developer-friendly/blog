---
date: 2024-03-03
draft: false
categories:
  - Kubernetes
  - Ansible
  - Vagrant
  - Cilium
links:
  - ./posts/0005-install-k3s-on-ubuntu22.md
---

# Kubernetes The Hard Way

You might've solved this challenge way sooner than I attempted it. Still, I
always wanted to go through the process as it has many angles and learning the
details intrigues me.

This version, however, does not use any cloud provider. Specifically, the things
I am using differently from the original challenge are:

- **Vagrant** & **VirtualBox**: For the nodes of the cluster
- **Ansible**: For configuring everything until the cluster is ready
- **Cilium**: For the network CNI and as a replacement for the kube-proxy

So, here is my story and how I solved the famous "Kubernetes The Hard Way" by
the great Kelsey Hightower. Stay tuned if you're interested in the details.

<!-- more -->

## Introduction

Kubernetes the Hard Way is a great exercise for any system administrator to
really get into the nit and grit of Kubernetes and figure out how different
components work together and what makes it as such.

If you have only used a managed Kubernetes cluster, or used `kubeadm` to spin up
one, this is your chance to really understand the inner workings of Kubernetes.
Because those tools abstract a lot of the details away from you, which is not
helping to understand the implementation details if you have a knack for it.

### Objective

The whole point of this exercise is to build a Kubernetes cluster from scratch,
downloading the binaries, issuing and passing the certificates to the different
components, configuring the network CNI, and finally, having a working
Kubernetes cluster.

With that introduction, let's get started.

## Prerequisites

First things first, let's make sure all the necessary tools are installed on our
system before we start.

### Tools

All the tools mentioned below are the latest versions at the time of writing,
February 2024.

{{ read_csv('docs/codes/0003-k8s-the-hard-way/prerequisites.csv') }}

Alright, with the tools installed, it's time to get our hands dirty and really
get into it.

## The Vagrantfile

!!! info

    The `Vagrantfile` configuration language is a Ruby DSL. If you are not a
    Ruby developer, fret not, as I'm not either. I just know enough to get by.

The initial step is to have three nodes up and running for the Kubernetes cluster,
and one for the Load Balancer used in front of the API server. We will be
using Vagrant on top of VirtualBox to create all these nodes.

These will be Virtual Machines hosted on your local machine. As such, there is
no cloud provider needed in this version of the challenge and all the
configurations are done locally.

The configuration for our Vagrantfile looks as below.

```ruby title="Vagrantfile" hl_lines="13 14 18-19 23 37 50-56"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile"
```

### Private Network Configuration

```ruby title="Vagrantfile" linenums="13"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:13:13"
```
```ruby title="" linenums="37"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:37:37"
```

There are a couple of important notes worth mentioning about this config, highlighted
in the snippet above and the following list.

The network configuration, as you see above, is a private network with hard-coded
IP addresses. This is not a hard requirement, but it makes a lot of the upcoming
assumptions a lot easier.

Dynamic IP addresses will need more careful handling when it comes to configuring
the nodes, their TLS certificates, and how they communicate overall.

And tackling craziness in this challenge is a sure way not to go down the rabbit
hole of despair :sunglasses:.

### Load Balancer Port Forwarding

```ruby title="Vagrantfile" linenums="14"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:14:14"
```

For some reason, I wasn't able to directly call `192.168.56.100:6443`, which is
the address pair available for the HAProxy. This is accessible from within the
Vagrant VMs, but not from the host machine.

Using firewall techniques such as `ufw` only made things worse; I was locked
out of the VM. I know now that I had to enable SSH access first, but that's
behind me now.

Having the port-forwarding configured, I was able to call the `localhost:6443`
from my machine and directly get access to the HAProxy.

???+ bug "On Vagrant Networking"

    In general, I have found many networking issues while working on this
    challenge. For some reason, the download speed inside the VMs was terrible
    (I am not the only complainer here if you search through the web). That's
    the main driver for mounting the same download directory for all the VMs to
    stop re-downloading every time the Ansible playbook runs.

### CPU and Memory Allocation

```ruby title="Vagrantfile" linenums="18"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:18:19"
```

While not strictly required, I found benefit restraining the CPU and memory
usage on the VMs. This ensures that no extra resources is being used.

Frankly speaking they shouldn't even go beyond this. This is an emtpy cluster
with just the control-plane components and no heavy workload is running on it.

### Mounting the Download Directory

```ruby title="Vagrantfile" linenums="23"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:23:23"
```

The download directory is mounted to all the VMs to avoid re-downloading the
binaries from the internet every time the playbook is running, either due to a
machine restart, or simply to start from scratch.

The trick, however, is that in Ansible `get_url`, as you'll see shortly, you
will have to specify the absolute path to the destination file to benefit from
this optimization and only specifying a directory will re-download the file.

### Ansible Provisioner

```ruby title="Vagrantfile" linenums="26"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:26:30"
```
```ruby title="" linenums="50"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/Vagrantfile:50:56"
```

The last and most important part of the `Vagrantfile` is the Ansible provisioner
section which, as you can see, is for both the Load Balancer VM as well as all
the three nodes of the Kubernetes cluster.

The difference, however, is that for the Kubernetes nodes, we want the playbook
to run for all of them at the same time to benefit from parallel execution of
Ansible playbook. The alternative would be to spin up the nodes one by one and
run the playbook on each of them, which is not efficient and consumes more time.

## Ansible Playbook

After provisioning the VMs, it's time to take a look at what the Ansible playbook
does to configure the nodes and the Load Balancer.

The main configuration of the entire Kubernetes cluster is done via this
playbook and as such, you can expect a hefty amount of configurations to be
done here.

First, let's take a look at the playbook itself to get a feeling of what to
expect.

```yaml title="bootstrap.yml"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/bootstrap.yml"
```

If you notice there are two plays running in this playbook, one for the Load
Balancer and the other for the Kubernetes nodes. This distinction is important
because not all the configurations will be the same for all the VMs. That's the
logic behind having different `hosts` in each.

Another important highlight is that the Load Balancer is being configured first,
only because that's the entrypoint for our Kubernetes API server and we need
that to be ready before the upstream servers.

### Directory Layout

This playbook you see above is at the root of our directory structure, right
next to all the roles you see included in the `roles` section.

To get a better understanding, here's what the directory structure looks like:

```plaintext title="Directory Tree" hl_lines="2" linenums="0"
.
├── ansible.cfg
├── bootstrap.yml
├── cilium/
├── coredns/
├── encryption/
├── etcd/
├── etcd-gateway/
├── haproxy/
├── k8s/
├── kubeconfig/
├── prerequisites/
├── tls/
├── tls-ca/
├── Vagrantfile
├── vars/
└── worker/
```

Beside the playbook itself, the Ansible playbook and the `Vagrantfile` the other
pieces are roles, initialized with `ansible-galaxy init <role-name>` command and
modified as per the specification in the originial challenge.

We will take a closer look at each role shortly.

### Ansible Configuration

Before jumping into the roles, one last impotant piece of information is the
`ansible.cfg` file, which holds the modifications we make to the Ansible default
behavior.

The content is as below.

```ini title="ansible.cfg" hl_lines="16"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/ansible.cfg"
```

The importance of facts caching is to get performant execution of the playbooks
during subsequent runs.

## Let's Begin the Real Work

So far, we've only been preparing everything. The remainder of this post will
focus on the real challenge itself, creating the pieces and components that
make up the Kubernetes cluster, one by one.

For the sake of brevity, and because I don't want this blog post be long, or worse,
broken into multiple parts, I will only highlight the most important tasks,
remove duplicates from the discussion, and generally go through the core aspect
of the task at hand. You are more than welcome to visit the source code[^1] for
yourself and dig deeper.

### Step 0: Prerequisites

In here we will enable port-forwarding, create the necessary directories that
will be used by later steps, and optionally, add the DNS records to each and
every node's `/etc/hosts` file.

The important lines are highlighted in the snippet below.

```yaml title="prerequisites/tasks/main.yml" hl_lines="4-5 7 21-22"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/prerequisites/tasks/main.yml"
```

As you can see, after the `sysctl` modification, we're notifying our handler
for a reload and re-read of the `sysctl` configurations. The handler
definition is as below.

```yaml title="prerequisites/handlers/main.yml"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/prerequisites/handlers/main.yml"
```

!!! tip "Ansible Linting"

    When you're working with Ansible, I highly recommend using `ansible-lint`[^2]
    as it will help you refine your playbooks much faster during the development
    phase of your project. It's not just "nice" and "linting" that matters. Some
    of the recommendations are really important from other aspects, such as
    security and performance.

### Step 1: TLS CA certificate

For all the workloads we will be deploying, we will need a CA signing TLS
certificates for us. If you're not a TLS expert, just know two main things:

1. TLS enforces encrypted and secure communication between the parties (client
   and server in this case but can alse be peers). You can try it
   out for yourself and sniff some of the data using Wireshark to see that none
   of the data is readable. They are only decipherable by the parties involved
   in the communication.
1. At least in the case of Kubernetes, TLS certificates are used for
   authentication and authorization of the different components and users. This
   will, in effect, mean that if a TLS certificate was signed by the trusted CA
   of the cluster, and the subject of that TLS has elevated privileges, then
   that subject can send corresponding to the API server and no further
   authentication is needed.

The TLS key and certificate generations are a pain in the butt IMO. But, with
the power of Ansible, we take a lot of the pain away, as you can see in the
snippet below.

```yaml title="tls-ca/tasks/ca.yml" hl_lines="19 33 44-45"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/tls-ca/tasks/ca.yml"
```

I'm not a TLS expert, but from my understanding, the most important part of the
CSR creation is the `CA: TRUE` flag. I actually don't even know if any of the
constraints or usages are needed, used and respected by any tool!

Also, the `provider: selfsigned`, as self-explanatory as it is, is used to
instruct that we're creating a new root CA certificate and not a subordinate one.

Lastly, we copy both the CA key and its certificate to a shared directory that
will be used by all the other components when generating their own certificate.

!!! info "Etcd CA"

    We could use the same CA for `etcd` communications as well, but I decided to
    separate them out to make sure no component other than the API server and the
    peers of `etcd` will be allowed to send any requests to the `etcd` server.

In the same Ansible role, we also generate a key and certificate for the admin/
operator of the cluster. In this case, that'll be me, the person who's provisioning
and configuring the cluster.

The idea is that we will not use the TLS certificate of other components to talk
to the API server, but rather use the ones explicitly created for this purpose.

Here's what it will look like:

```yaml title="tls-ca/tasks/admin.yml" hl_lines="19 26-28"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/tls-ca/tasks/admin.yml"
```

The `subject` you see on line 19, is the group `system:masters`. This group
inside the Kubernetes cluster has the highest privileges. It won't require
any RBAC to perform the requests, as all will be granted by default.

As for the certificate creation, you see on line 26-28 that we specify to the
Ansible task that the CA will be of type `selfsigned` and we're passing the same
key and certificate we created in the last step.

#### TLS CA Execution

To wrap this step up, two important things worth mentioning are:

1. Both of the snippets mentioned here and the ones not mentioned, will be
   imported into the root of the Ansible role with the following `main.yml`.
   ```yaml title="tls-ca/tasks/main.yml" hl_lines="1-3 10-12"
   -8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/tls-ca/tasks/main.yml"
   ```
1. You might have noticed in the `bootstrap.yml` root playbook that this CA role
   will only run once, the first Ansible inventory that gets to this point.
   This will ensure we don't consume extra CPU power or overwrite the currently
   existing CA key and certificate. Some of our roles are designed this way,
   e.g., the installation of `cilium` is another one of those cases.
   ```yaml title="bootstrap.yml" linenums="32"
   -8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/bootstrap.yml:32:33"
   ```

### Step 2: TLS Certificates for Kubernetes Components

The number of certificates we need to generate for the Kubernetes components is
eight in total,  but we'll bring only one in this discussion. The most impotant
one, the API server certificate.

All the others are similar with a possible minor tweak.

Let's first take a look at what the Ansible role will look like:

```yaml title="tls/tasks/apiserver.yml" hl_lines="9 14 22 30-32"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/tls/tasks/apiserver.yml"
```

From the highlights in the snippet above, you can see at least 3 piece of
important information:

1. This certificate is not for the CA: `CA: FALSE`.
1. The subject is in `system:kubernetes` group. This is just an identifier really
   and serves to special purpose.
1. The same properties as with the `admin.yml` was used to generate the TLS
   certificate. Namely the `provider` and all the `ownca_*` properties.

### Step 3: KubeConfig Files

In this step, for every component that will talk to the API server, we will create
a KubeConfig file, specifying the server address, the CA certificate, and the
key and certificate of the client.

The format of the KubeConfig is the same as you have in your filesystem under
`~/.kube/config`. That, for the purpose of our cluster, will be a Jinja2 template
that will take the variables we just mentioned.

Here's what that Jinja2 template will look like:

```yaml title="kubeconfig/templates/kubeconfig.yml.j2"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/kubeconfig/templates/kubeconfig.yml.j2"
```

And with that template, we can generate multiple KubeConfigs for each component.
This is one of the examples to create one for the Kubelet component.

```yaml title="kubeconfig/tasks/kubelet.yml" hl_lines="10-11"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/kubeconfig/tasks/kubelet.yml"
```

!!! note "Kubernetes API Server"

    The current setup is to deploy three API server, one on each of the three
    VM nodes. That means in any node, we will have `localhost` access to the
    control plane, if and only if the key and certificate are passed correctly.

As you notice, the Kubelet is talking to the `localhost:6443`. A better alternative
is to talk to the Load Balancer in case one of the API servers goes down. But,
this is an educational setup and not a production one!

The values that are not directly passed with `vars` property, are being passed
by the defaults variables:

```yaml title="kubeconfig/defaults/main.yml" hl_lines="3"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/kubeconfig/defaults/main.yml"
```

They can also be passed from parents of the role, or the files being passed to
the playbook.

```yaml title="vars/lb.yml" hl_lines="3 4"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/vars/lb.yml"
```

!!! tip "Ansible Variables"

    As you may have noticed, inside every `vars` file, we can use the values from
    other variables. That's one of the many things that make Ansible so powerful!

### Step 4: Encryption Configuration

The objective of this step is to create an encryption key that will be used to
encrypt and decrypt the Kubernetes Secrets stored in the `etcd` database.

For this task, we use one template, and a set of Ansible tasks.

```yaml title="encryption/templates/config.yml.j2" hl_lines="10"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/encryption/templates/config.yml.j2"
```

```yaml title="encryption/tasks/main.yml" hl_lines="3-4 6 9 17-18"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/encryption/tasks/main.yml"
```

As you see in the task definition, we will only generate one secret for all the
subsequent runs, and reuse the file that hold that password.

That encryption configuration will later be passed to the cluster for storing
encrypted Secret resources.

### Step 5: Etcd Cluster

In this step we will download the compiled `etcd` binary, create the configuration,
create the systemd service, issue the certificates for the `etcd` peers as well
as one for the API server talking to the `etcd` cluster as a client.

The installation will like below.

```yaml title="etcd/tasks/install.yml" hl_lines="4-5 9 12 19 24-28"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/etcd/tasks/install.yml"
```

A few important note to mention for this playbook:

1. We specify the `dest` as an absolute path to the `get_url` task to avoid
   re-downloading the file for subsequent runs.
1. The `checksum` ensures that we don't get any nasty binary from the internet.
1. The `register` for the download step will allow us to use the `etcd_download.dest`
   when later trying to extract the tarball.
1. Inside the tarball may or may not be more than one file. We are only interested
   in extracting the ones we specify in the `extra_opts` property. Be mindful of
   the `--strip-components` and the `--wildcards` options.

The variables for the above task will look like below:

```yaml title="vars/etcd.yml" hl_lines="2 5-7"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/vars/etcd.yml"
```

Once the installation is done, we can proceed with the configuration as below:

```yaml title="etcd/tasks/configure.yml" hl_lines="13 18-19 26 30-32"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/etcd/tasks/configure.yml"
```

The handler for restarting the `etcd` is not much different from what we've
seen previously. But the systemd Jinja2 template is an interesting one:

```yaml title="etcd/templates/systemd.service.j2" hl_lines="10 15 24 26-27"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/etcd/templates/systemd.service.j2"
```

The two variables you see in the above template are passed from the following
`vars` file:

```yaml title="vars/k8s.yml" hl_lines="2 11"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/vars/k8s.yml"
```

You will realize that the `etcd` is instructed to verify the authentication
of its requests using the TLS CA. No request shall be allowed unless its TLS
is signed by the verified and trusted CA.

This is achieved by the `--client-cert-auth` and `--trusted-ca-file` options for
clients of the `etcd` cluster, and the `--peer-client-cert-auth` and
`--peer-trusted-ca-file` for the peers of the `etcd` cluster.

You will also notice that this is a 3-node `etcd` cluster, and the peers are
statically configured by the values given in the `vars/etcd.yml` file. This is
exactly one of the cases where having static IP addresses make a lot of our
assumptions easier and the configurations simpler. One can only imagine what
would be required for dynamic environments where DHCP is involved.

### Step 6: Kubernetes Components

There are multiple components, as you know, but here's a sample, being the
Kubernetes API server.

```yaml title="k8s/tasks/install.yml"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/k8s/tasks/install.yml"
```
```yaml title="k8s/templates/kube-apiserver.service.j2" hl_lines="14-15 17-20 22"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/k8s/templates/kube-apiserver.service.j2"
```

And the default vaules are fetched from its own role defaults:

```yaml title="k8s/defaults/main.yml" hl_lines="14-15 17-20 22"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/k8s/defaults/main.yml"
```

You will notice the following points in this systemd setup:

1. The external host address is of the Load Balancer.
1. The certificate files for both Kubernetes API server and the Etcd server are
   being passed from the location previously generated.
1. The encryption config is being fetched from a file generated in step 4.

!!! question "What makes this setup HA then?"

    First of all, there are a couple of places that are not pointing to the
    Load Balancer IP address so this wouldn't count as as a complete HA setup.
    But, having an LB in-place already qualifies this setup as such.

    But, you will not see any peer address configuration in the API server as
    it was the case for `etcd` with `--initial-cluster` flag and you might
    wonder how do the different instances of the API server know of one another
    and how can they coordinate between each other when multiple requests hit
    the API server?

    The answer to this question does not lie in the Kubernetes itself, but in the
    storage layer, being the `etcd` cluster. The `etcd` cluster, at the time of
    writing, uses the Raft protocol for consensus and coordination between the
    peers.

    And that is what makes the Kubernetes cluster HA, not the API server itself.
    Each instance will talk to the `etcd` cluster to understand the state of the
    cluster and the components inside.

### Step 7: Worker Nodes

This is one of the last steps before we have a non-Ready Kubernetes cluster.

The task includes downloading some of the binaries, passing in some of the TLS
certificates generated earlier, and starting the systemd services.

```yaml title="worker/tasks/cni-config.yml" hl_lines="55 62-63"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/worker/tasks/cni-config.yml"
```

The CNI config for containerd is documented in their repository if you feel
curious[^3].

??? details "Worker Role Default Variables"

    ```yaml title="worker/defaults/main.yml"
    -8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/worker/defaults/main.yml"
    ```


```yaml title="worker/tasks/containerd.yml"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/worker/tasks/containerd.yml"
```

### Step 8: CoreDNS & Cilium

The last step is straightforward.

We plan to run the CoreDNS as Kubernetes Deployment with affinity, and install
the Cilium using its CLI.

```yaml title="coredns/tasks/main.yml" hl_lines="6-17"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/coredns/tasks/main.yml"
```

Notice the slurp tasks because they will be used the pass the TLS certificates
to the CoreDNS instance.

??? details "CoreDNS Kubernetes Manifests"

    ```yaml title="coredns/templates/manifests.yml.j2" hl_lines="38-40"
    -8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/coredns/templates/manifests.yml.j2"
    ```

And finally the Cilium.

```yaml title="cilium/tasks/main.yml"
-8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/cilium/tasks/main.yml"
```

??? details "Cilium Role Default Variables"

    ```yaml title="cilium/defaults/main.yml"
    -8<- "https://github.com/developer-friendly/kubernetes-the-hard-way/raw/v1.29.2/cilium/defaults/main.yml"
    ```

That's it. Believe it or not, the Kubernetes cluster is now ready and if you
run the following command, you will see three nodes in the `Ready` state.

```bash title=""
export KUBECONFIG=share/admin.yml # KubeConfig generated in step 3
kubectl get nodes
```

## How to run it?

If you clone the repository, you would only need `vagrant up` to build everything
from scratch. It will take some time for all the components to be up and ready, but it
will set things up without any further manual intervention.

## Conclusion

This task took me a lot of time to get right. I had to go through a lot of
iterations to make it work. One of the most time-consuming parts was how the
`etcd` cluster was misbehaving, leading to the Kubernetes API server hitting
timeout errors and being inaccessible for the rest of the cluster's components.

I learned a lot from this challenge. I learned how to write efficient Ansible
playbooks, how to create the right mental model for the target host where the
Ansible executes a command, how to deal with all those TLS certificates, and
overall, how to set up a Kubernetes cluster from scratch.

I couldn't be happier reaching the final result, having spent countless hours
debugging and banging my head against the wall.

I recommend everyone giving the challenge a try. You never know how much you
don't know about the inner workings of Kubernetes until you try to set it up
from scratch.

Thanks for reading so far. I hope you enjoyed the journey as much as I did
:hugging:.

## Source Code

As mentioned before, you can find the source code for this challenge on the
GitHub repository[^1].

## FAQ

### Why Cilium?

Cilium has emerged as a cloud-native CNI tool that happens to have a lot of the
features and characteristics of a production-grade CNI. To name a few,
performance, security, and observability are the top ones. I have used Linkerd
in the past but I am using Cilium for any of the current and upcoming projects
I am working on. It will continue to prove itself as a great CNI for Kubernetes
clusters.

### Why use Vagrant?

I'm cheap :grin: and I don't want to pay for cloud resources, even for learning
purposes. I have active subscription on O'Reilly and A Cloud Guru and I would've
gone for their sandboxes, but I initially started this challenge just with Vagrant
and I resisted the urge to change that, even after countless hours was spent on
the terrible network performance of the VirtualBox VMs :shrug:.

[^1]: https://github.com/developer-friendly/kubernetes-the-hard-way/tree/v1.29.2
[^2]: https://github.com/ansible/ansible-lint
[^3]: https://github.com/containerd/containerd/blob/v1.7.13/script/setup/install-cni
