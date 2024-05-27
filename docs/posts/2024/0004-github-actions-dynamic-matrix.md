---
date: 2024-03-09
draft: false
description: >-
  Learn how to leverage GitHub Actions to define a dynamic matrix that can
  parallelize your jobs and increases your CI/CD throughput on-demand.
categories:
  - GitHub
  - CI/CD
social:
  cards_layout_options:
    description: >-
      Learn how to increase the bandwidth of your CI/CD pipeline by defining a
      dynamic matrix in GitHub Actions for maximum efficiency and cost optimization.
image: assets/images/social/2024/03/09/github-actions-dynamic-matrix.png
---

# GitHub Actions Dynamic Matrix

GitHub Actions is a powerful CI/CD tool that allows you to automate your
software development workflow. It provides a wide range of features and
capabilities.

One of the features that I found very useful is the ability to define a matrix
strategy for your jobs. This allows you to run the same job with different
parameters, such as different versions of a programming language.

However, there are times when you need to define the matrix dynamically based on
the output of a previous job. For example, you may want to run a job for each
directory if and only if the directory contains a specific file or has changed
since the last commit.

In this post, I will show you how to define a dynamic strategy matrix in GitHub
Actions using a real-world example.

<!-- more -->

## First, a Static Matrix

Let's start with a simple example. Let's suppose we want to build our Rust
application for different platforms.

To get started, we'll create the project as below.

```bash
cargo new hello-world
```

This will give me the following directory structure.

```plaintext title=""
.
└── hello-world
    ├── Cargo.toml
    └── src
        └── main.rs
```

Now, let's create a GitHub Actions workflow file.

```yaml title=".github/workflows/ci.yml" hl_lines="21 23-29 47"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/build-rust-ci.yml"
```

The highlighted lines are the focus of this post. We will expand on this as
we go along.

## Dynamic Matrix

Now, the CI workflow above is great, and it works perfectly fine. Here's
proof of the successful run and its uploaded artifacts.

<figure markdown="span">
  ![Successful run](/static/img/2024/0004/successful-ci-run.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Static matrix result</figcaption>
</figure>

However, there are some cases where you might benefit from having the matrix
defined in a dynamic way. That way, you have more control and flexibility over
which of those matrix items should be included in the build.

For example, let's say you have a monorepo with multiple services, and you want
to build a Docker image if and only if the service has changed since the
last build.

Let's see how we can achieve this.

### Step 0: Separating the jobs

You might have noticed that in the first example, we explicitly specified the
jobs we wanted to run. That is static yet very simple and straightforward.

In our mission to have a dynamic matrix, we need to separate the jobs into at least
two jobs. This way, we can prepare the list of parallel jobs from the first
pipeline and then use that list to pass on to the `matrix` in the second.

### Step 1: Fetching a list of changed files

Since we aim to build the Docker image if only the service has changed, we need
a way to determine if the service has changed.

There are different ways we can achieve this. One way we're employing in this
post is to use a community GitHub Action.

Let's see how.

```yaml title="Fetch changed files" hl_lines="21 26"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step1-prepare.yml"
```

The key here is to fetch all the repository, hence the `fetch-depth: 0`. This
will ensure that the `since_last_remote_commit: true` in line 23 is accurate.

The rationale is that there might be cases where we push one or more commits
to the repository, and none of them change any of the services that aim to
trigger the Docker image build.

### Step 2: Did any of the services change?

Next step is to realize if any of the changed files in the previous step modified
any of the services we're interested in.

```yaml title="Filter services only" hl_lines="12 14 19 25 31"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml"
```

Wait a minute! There's a lot going on here. Let's break it down.

#### Changed files or an empty list

In this loop, we will either get a list of changed files from the previous step
in the happy path or resort to an empty list if the output of the last step
is empty. (1)
{ .annotate }

1.  This is the syntax of GitHub Expressions. You can read more about it
    in their documentations[^1].

```yaml title="" linenums="12"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml:12:12"
```

#### Filter only the top-level directories

Since we're holding a monorepo, all the services are in the top-level directories.
This will allow us to trim down on all the files that are not inherently related
to the services.

```yaml title="" linenums="14"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml:14:14"
```

It's important to mention here that the `actions/checkout` is necessary before
this step to ensure that we have access to the repository structure.

#### Minify the JSON output

In our Python code, we make sure to remove any spaces after the `,` and `:` in
the `json.dumps` to avoid running into issue at later steps when decoding the
JSON.

```yaml title="" linenums="19"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml:19:19"
```

#### Prepare the matrix

Finally, we prepare the matrix for the next step. This is a list of all the
directories that have changed since the last commit.

We will also proactively set the length of the list as an output so that the
next GitHub job can use it as a conditional on whether or not to run. It may
happen that you changes haven't affected any of the services, and in that case
we don't want to run the Docker image build job.

```yaml title="" linenums="25"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml:25:25"
```

```yaml title="" linenums="31"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step2-determine.yml:31:31"
```

### Step 3: Build the Docker image(s)

The idea is that this step will only execute if the previous step has determined
that there are changes in the services. We have provided the `length` as a hint
for this next step to ensure no unnecessary job runs, nor do we hit any error
due to an empty list in the `matrix` input.

```yaml title="Build the Image" hl_lines="4 7 25 32"
-8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step3-build-image.yml"
```

As you see in the conditional, this job will only run if the length of the list
is greater than zero, i.e., there are changes in the services.

The `matrix` value has taken a new form in this case compared to our initial
example. In this case, we're asking GitHub to parse the JSON string and
pass the value to the `matrix` input.

If two of our services have changed, the `matrix` will take the following form.

=== "Implied `matrix`"

    ```yaml title="" linenums="0"
      build:
        strategy:
          fail-fast: false
          matrix:
            services:
              - service1
              - service2
    ```

=== "Configured `matrix`"

    ```yaml title="" linenums="7"
    -8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/step3-build-image.yml:7:7"
    ```

Lastly, the `matrix` passed from the first job is accessed in lines 25 and 32.
The key `service` is explicitly defined in the earlier job and is not
a reserved keyword in GitHub Actions, nor a special keyword in the `matrix`.

## What does it look like?

Now that you've seen the definitions, let's see how it looks like in action
(Click to zoom in).

<div class="grid cards" markdown>

- <figure markdown="span">
    ![Preparing the dynamic matrix](/static/img/2024/0004/stage0.webp "Click to zoom in"){ width="300" loading=lazy }
    <figcaption>Step 0: Preparing the dynamic `matrix`</figcaption>
  </figure>

- <figure markdown="span">
    ![Running the dynamic matrix](/static/img/2024/0004/stage1.webp "Click to zoom in"){ width="300" loading=lazy }
    <figcaption>Step 1: Running the dynamic `matrix`</figcaption>
  </figure>

- <figure markdown="span">
    ![Expand the two jobs](/static/img/2024/0004/stage2.webp "Click to zoom in"){ width="300" loading=lazy }
    <figcaption>Step 2: Click open the two jobs</figcaption>
  </figure>

- <figure markdown="span">
    ![Successful run of all jobs](/static/img/2024/0004/stage3.webp "Click to zoom in"){ width="300" loading=lazy }
    <figcaption>Step 3: Successful run of all jobs</figcaption>
  </figure>

</div>

And in case you push a commit that hasn't changed any service, the second
job will be skipped, as expected.

<figure markdown="span">
  ![no-run](/static/img/2024/0004/no-run.webp "Click to zoom in"){ loading=lazy }
  <figcaption>Skipped build</figcaption>
</figure>

??? details "The full definition of the CI workflow"

    ```yaml title=".github/workflows/ci.yml"
    -8<- "docs/codes/2024/0004-dynamic-github-actions-matrix/full-ci-definition.yml"
    ```

## Conclusion

That's the whole story. We started with a simple static `matrix` and then
moved to a dynamic `matrix` that is more flexible and gives us more
control of what workflows we want to run.

Knowing that CI/CD costs really dollar money :money_mouth:, it's important to
optimize your workloads and only run the necessary jobs. This will enhance
your cost efficiency and reduce your bill at the end of the month.

I hope you found this post useful. If you have any questions or comments, feel
free to reach out to me.

Until next time, _ciao_, and happy hacking!

## Source Code

To access the source code for this post, head over to the corresponding
GitHub repository[^2].

[^1]: https://docs.github.com/en/actions/learn-github-actions/expressions
[^2]: https://github.com/meysam81/github-actions-dynamic-matrix/tree/v0.2.0
