---
date: 2024-02-16
draft: false
description: >-
  What does the immutable flag on External Secrets operator entails and how it
  can affect your secret management in the Kubernetes cluster.
categories:
  - Kubernetes
  - Secrets Management
  - AWS
  - OpenTofu
image: assets/images/social/2024/02/16/external-secrets-and-immutable-target.png
---

# External Secrets and Immutable Target

If you have worked with [External Secrets Operator](https://external-secrets.io)
before, then you know how it eases the operation of managing the secrets in the
Kubernetes cluster. It supports many backends and is very powerful.

However, there is a nuance. The External Secrets Operator allows you to define
an immutable target secret, sealing the secret shut from future changes unless
explicitly deleted and recreated, which is perfect if you never want to modify
the secret. But, change is the only constant in the world of IT, and you might
want to change the secret in the future. This is where `immutable` can catch
you off guard, as it did mine. This is my story and how I solved it.

<!-- more -->

## Introduction

External Secrets Operator has support for a variety of secret backends,
including AWS Secrets Manager, Azure Key Vault, Google Secret Manager,
HashiCorp Vault, etc. That said, if you have different backends for your
secret management, this is the perfect solution for you.

With External Secrets, you can define one or more `SecretStore` or `ClusterSecretStore`
to read the secrets from a specific backend and create the Kubernetes Secret
resource with the name and namespace you specify. This is a great way to
store secrets in a secure and encrypted location, e.g., AWS Parameter Store,
and granting the External Secret Operator the permission to fetch (and if desired
create/update secrets) in the backend.

## A Working Example

First things first, let's spin up a Kubernetes cluster. I am using kind[^1] to
create a local and lightweight Kubernetes cluster.

```shell
kind create cluster --image=kindest/node:v1.29.2
```

!!! tip "On Versioning"

    It's always a good idea to pin your dependencies to a specific version. I
    would go as far as to say that you should do it even in your personal
    projects. You will ensure reproducibility and avoid surprises for others
    and for your future self.

After this command, I will see a single-node cluster on my machine.

### Install the External Secrets Operator[^2]


I prefer the Helm installation method since it is deterministic and behaves
as expected when pinning to a specific version.

```shell
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets --version=0.9.x
```

### Create a Secret Store

A Secret Store (or Cluster Secret Store) is the resource talking to your
encrypted secrets management backend. Here's an example of how to create
a Cluster Secret Store with the backend of AWS Parameter Store.

```yaml title="css.yml" hl_lines="12 16"
-8<- "docs/codes/2024/0002-external-secrets/css.yml"
```

### AWS IAM User

Be mindful that this secret store will need a way to access the secrets in your
backend. In our example, that means we have to create an IAM User with access
key and secret access key, and pass the credentials as Kubernetes Secret with
the name `aws-ssm-user` (the highlighting lines in the above snippet).

To do that, we'll get help from our good friend OpenTofu.

```hcl title="variables.tf"
-8<- "docs/codes/2024/0002-external-secrets/variables.tf"
```

```hcl title="iam.tf"
-8<- "docs/codes/2024/0002-external-secrets/iam.tf"
```

!!! info

    All the examples in this post are tested and working. To reproduce it,
    simply run `tofu init` and `tofu apply`.

So far, so good. There is only one issue! The Cluster Secret Store is not a
templated resource and as such, except for the secret keys `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`, we would have to specify both `region` and the
`role` manually as hard-coded values in the YAML manifest.

That is not ideal, not by a long shot.

That's why, we'll use the same powerful HCL syntax we've been using so far to
create the Cluster Secret Store from inside the OpenTofu files.

### Create the Cluster Secret Store

```hcl title="kubernetes.tf"
-8<- "docs/codes/2024/0002-external-secrets/kubernetes.tf"
```

You will notice, promptly, that we no longer have to write any hard-coded values
as we had to do earlier in the [`css.yml` example](#create-a-secret-store) in
our definitions and everything is being initialized from the resources being
created in the same stack.

That's a powerful approach when provisioning and maintaining your infrastructure
as it gives you, at its minimum, a reproducible and consistent environment where
you can use for your day-to-day operations as well as your disaster recovery
plans.

### Reference a Secret Stored in AWS SSM

Now, onwards we go. The next task is to create a secret in AWS SSM and
use it inside our cluster by the way of External Secrets Operator.

The task is simple, but we'll keep the tradition alive by using OpenTofu to
create an encrypted secret in AWS SSM.

Let's imagine we want to store some fake password in our secret store.

```hcl title="ssm.tf"
-8<- "docs/codes/2024/0002-external-secrets/ssm.tf"
```

### Reference the Secret From Inside the Cluster

Now, the moment of truth. This is where it all comes together. We'll create
the External Secret resource to reference the secret we created in the previous
step.

```yaml title="external-secret.yml" hl_lines="16"
-8<- "docs/codes/2024/0002-external-secrets/external-secret.yml"
```

To create this resource, simply use `kubectl`:

```shell
kubectl apply -f external-secret.yml
```

Notice the highlighted lines as it is the topic of this post.

#### Is the Secre Correct?

To realize if the secret is initialized correctly, we can investigate the
Kubernetes Secret resource:

```shell
$ kubectl get secret my-app -o jsonpath='{.data.MONGO_ROOT_PASSWORD}' | base64 --decode && echo
ThisIsNotASecurePassword
```

And lo and behold, the secret is there and it is correct.

!!! tip

    The use of `echo` at the end of the last command is not mandatory, however,
    it will clear the line after the password is printed and your shell prompt
    will not stay on the same line as the password.

### Let's Change the Password Now

Now, this is all good and sexy. But what happens if we wanted to rotate our
password, i.e., change it in the backend (AWS SSM in this case). The expected
behavior is that the External Secret Operator would pick up the change as
frequent as its `refreshInterval` and update the secret in the cluster.

However, as mentioned at the beginning of this post, `immutable` plays a huge
role in this expectation as we shall see shortly.

Let's modify the password using the OpenTofu again.

```shell
tofu apply -var mongo_root_password=SomethingDifferent
```

We will have to wait for the maximum of `refreshInterval` (1m in this case) for
the External Secret Operator to pick up the change and update the secret.

After that, another look at the secret will reveal that the password.

```shell
$ kubectl get secret my-app \
  -o jsonpath='{.data.MONGO_ROOT_PASSWORD}' | \
  base64 --decode && echo
SomethingDifferent
```

It indeed change the password.

### Let's Break it a Little

Now, we have seen that the External Secret is behaving as expected. But, let's
change the `immutable` field in its spec and observe the behavior.

```yaml title="external-secret-v2.yml" hl_lines="16"
-8<- "docs/codes/2024/0002-external-secrets/external-secret-v2.yml"
```

Updating the External Secret will not prove our point here! But, if we remove
and recreat the External Secret, we won't embarass ourselves by opening such
topic.

```shell
kubectl delete -f external-secret.yml
kubectl apply -f external-secret-v2.yml
```

Now, as we can see from the target Secret, the `immutable` flag is set to `true`.

```shell
$ kubectl get secret my-app -o jsonpath='{.immutable}' && echo
true
```

You should have noticed that we haven't changed the second version of the secret
and it should still be `SomethingDifferent`.

This is the point and we can even make sure by looking into the secret again.

```shell
$ kubectl get secret my-app \
  -o jsonpath='{.data.MONGO_ROOT_PASSWORD}' | \
  base64 --decode && echo
SomethingDifferent
```


But, what if we want to update the secret again?

```shell
tofu apply -var mongo_root_password=AnotherPassword
```

Even after waiting for as long as more than the `refreshInterval`, the secret
will not change.

```shell
$ kubectl get secret my-app \
  -o jsonpath='{.data.MONGO_ROOT_PASSWORD}' | \
  base64 --decode && echo
SomethingDifferent
```

But, wait. Didn't we just change the password? Shall we check the AWS SSM?

```shell
$ aws ssm get-parameters \
  --names /prod/mongodb-atlas/passwords/root \
  --with-decryption \
  --query Parameters[0].Value --output text
AnotherPassword
```

Wow. :exploding_head:

This is not what we expected. The app will surely break.

And so, that is the whole point of writing this long post. The `immutable` flag
is a double-edged sword. It is a great feature if you want to make sure that
the secret is not changed, but it is a disaster if you want to change the secret
in the future.

In other words, secret rotation, which is a industry security best practice, is
not possible with the `immutable` flag set to `true`.

The alternative is of course to set it to `false`, which is even a worse idea
in my opinion, since if there isn't a proper policy or RBAC in place, anyone
with access to the cluster can, accidentally or otherwise, change the content
of the secret.

## Conclusion

The External Secrets Operator is a powerful tool to manage secrets in the
Kubernetes cluster. It supports many backends and is very flexible. However,
the `immutable` flag is not at its best behavior and you should be extra
cautious when using it in your production environment.

Thanks for reading and I hope you enjoyed this post. If you have any questions
or comments, please feel free to reach out.

Happy hacking!

If you enjoy these contents, please consider consider supporting the blog by
the way of [GitHub Sponsors](https://github.com/sponsors/meysam81) :heartbeat:.

## Versions

To help with reproducibility, I will include the versions of the providers in
this post.

```hcl title="versions.tf"
-8<- "docs/codes/2024/0002-external-secrets/versions.tf"
```

## Source Code

The code for this post is available from the following link.

[Source code](https://github.com/developer-friendly/blog/blob/main/docs/codes/2024/0002-external-secrets)

[^1]: https://github.com/kubernetes-sigs/kind
[^2]: https://external-secrets.io/latest/introduction/getting-started/
