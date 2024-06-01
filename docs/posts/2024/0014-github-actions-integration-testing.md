---
date: 2024-06-03
description: >-
  TODO
categories:
  - GitHub
  - GitHub Actions
  - GitHub Pages
  - Testing
  - PostgreSQL
links:
  - Source Code: https://github.com/developer-friendly/full-stack-fastapi-template/
image: assets/images/social/2024/06/03/integration-testing-with-github-actions.png
---

# Integration Testing with GitHub Actions

GitHub Actions is a great CI/CD tool to automate the daily operations of your
application lifecycle in many ways. It comes with a lot of features out of the
box and even the ones that are missing are wholeheartedly provided by the
community.

There are many great and brilliant engineers working daily to provide a
fantastic experience for the rest of us.

In this blog post, you will learn how to perform your integration testing
using GitHub Actions with all its dependencies and services spun up beforehand.

Stick around till the end to find out how.

<!-- more -->

## Introduction

If you're a fan of writing tests for your software, there's a good chance that
you like to run the fast and small tests on your machine, and delegate the task
of long-running test execution to another host, likely the CI machine.

This allows for improved productivity as you continue with your development &
enhancements for your software while the tests are running in the background.

It also allows for a high confidence and a robust delivery, knowing that all
the changes are gated behind a set of tests that will run automatically for
every push.

Thanks to GitHub and the huge productivity boost it has provided to the
developer community, we have less to worry about these days when it comes to
the test infrastructure compared to what used to be the case a few years ago.

Let's see how we can leverage this great technology in our advantage so that
our typical flow is not interrupted and every push to the repository triggers
and enforces the passing of our previously written tests.

## Objective

As per our tradition in this blog post, we should set a clear goal of what we
aim to achieve in here. If things work for the best, we should
accomplish the following tasks:

- [x] Find an application that has a couple of dependencies (e.g. database,
      caching, etc.) during its runtime operation. The requirement is that the
      app has to be useless without these dependencies. This is a required
      objective as we aim to provide a solution to this very common problem.
- [x] Have a bunch of integrations [tests](/category/testing/) actually talking
      to those dependencies and verifying that the application is working as
      expected.
- [x] Write a [GitHub Actions](/category/github-actions/) workflow that spins
      up the dependencies before the app, and then runs the integration tests
      against the app with the correct set of configurations so that the app
      knows how to talk to its dependencies.

If that is something you have seen and dealt with before in the past, this blog
post may provide you a robust yet underutilized approach.

## CRUD Application

  There are numerous apps that [fall into this category], especially opensource
products where we are able to grab the source code and tweak it to our needs.

The one picked for this blog post comes from the famous [Sebastián Ramírez],
the creator of [FastAPI]. The app is called [Full-Stack FastAPI Template].

It has both frontend and backend. However, the focus of this blog post will
be mainly on the backend part of the application.

The backend needs a [PostgreSQL](/category/postgresql/) database to run and
operate and the same goes for its integration tests.

The framework of the test and other aspects of writing tests is not in the scope
for this blog post. We are mainly interested in:

1. Having integration tests
2. Running them in GitHub Actions

Since running the tests in the CI means having the database up and running,
it's a great example to show how you can run your integration tests in
[GitHub Actions](/category/github-actions/), having GitHub taking care of the
dependencies for you.

## Run Tests Locally

Let us first run the tests locally, track the dependencies and understand the
interconnections between the app and the database.

```bash title="" linenums="0"
VERSION="0.6.0"
git clone github.com:tiangolo/full-stack-fastapi-template -b ${VERSION}
cd full-stack-fastapi-template
```

To keep the results consistent, we are using the latest version of the app as
of the time of writing this blog post.

This will complain about a detached `HEAD`, but it's not an issue for what we
want to achieve here.

At this point, we should have the repo in the local machine.

We are not gonna do lots of crazy stuff here, so let us just run the database.

```bash title="" linenums="0"
docker compose up -d db
```

With the database up and running, we will head over to the `backend/` directory
to prepare the dependencies.

```bash title="" linenums="0"
cd backend
poetry install
```

We have our virtual environment set up with all its libraries installed.

For the app to work, we need to set a couple of environment variables.

```bash title="" linenums="0"
# inside the backend/ directory
poetry self add 'poetry-dotenv-plugin<1'
# grab variables from the sample file
egrep '^\w.*' ../.env > .env
```

And finally, let's migrate the database and run the tests.

```bash title="" linenums="0"
poetry run alembic upgrade head
poetry run pytest
```

Two of the tests are failing at this point, but that is not our concern really!
:shrug:

<figure markdown="span">
  ![Pytest Local Result](/static/img/2024/0014/full-stack-fastapi-template-pytest.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Pytest Local Result</figcaption>
</figure>

## Running Tests in the CI

Now that we have a locally working example, let's move on to the CI part.

At this step, we want to have the same setup, spinning up the database and
running the tests.

!!! note "Note"

    The current version of the CI in the target repository is using a simple
    `docker-compose up -d` right [before running the tests].

    Honestly, there is nothing wrong with this approach and if it works for you
    and your team, by all means, go ahead and own your decision and celebrate
    it proudly. :person_running:

    I am not here to tell you which approach is better; that is your
    responsibility to figure out.

    I would only invite you to read this article to see if the proposed solution
    is something that you would like to try out.

[GitHub Actions](/category/github-actions/) provide a way to run services
before the actual job starts. These are great for running dependencies like
databases, caches, etc. in the CI environment.

The idea is just the same as we had in our local environment, and the
implementation and its syntax is specific to GitHub Actions.

For your reference, ^^GitLab^^ also provides the same functionality with the
`services` [directive.]

Let's see how we can achieve this in GitHub Actions.

### Starting the Database

First, we need to start the database before the app.

```yaml title=".github/workflows/ci.yml" linenums="48"
-8<- "docs/codes/2024/0014/junk/service.yml:48:56"
```

If you notice the syntax is very similar to what you see in a `docker-compose.yml`
file. Example from the same target repository
[below][Full-Stack FastAPI Template]. :point_down:

```yaml title="docker-compose.yml"
-8<- "docs/codes/2024/0014/docker-compose.yml:1:13"
```

These so called __services__ in GitHub Actions are spun up before the actual
job starts. That gives a good leverage for all the dependencies we need up and
running before the CI starts its first _step_.

The services defined here will run as soon as possible during the execution
of our job, as you see below.

<figure markdown="span">
  ![CI Run Initializes Containers](/static/img/2024/0014/full-stack-ci-init-containers.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>CI Run Initializes Containers</figcaption>
</figure>

And if you dig deeper, you will find the exact environment variables passed
to the container as specified earlier.

<figure markdown="span">
  ![CI Service Container Flags](/static/img/2024/0014/full-stack-postgres-env-vars.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>CI Service Container Flags</figcaption>
</figure>

### Installing Dependencies & Database Migration

As before, we will require the installed libraries of our application, as well
as the database migration for every new Postgres instance.

```yaml title=".github/workflows/ci.yml" linenums="68"
-8<- "docs/codes/2024/0014/ci.yml:68:74"
```

### Running the Tests

Finally, we will run the tests.

```yaml title=".github/workflows/ci.yml" linenums="75"
-8<- "docs/codes/2024/0014/ci.yml:75:79"
```

### Optionally: Upload Coverage to GitHub Pages

The coverage results is a great measure of how well your tests are covering
your codebase, whether or not you have a dead code anywhere, etc.

These are usually static HTML files that can be viewed in a browser for a
good overall visual on the coverage and the places where you need to improve.

Additionally, [GitHub Pages](/category/github-pages/), is an excellent
choice for serving such static files right inside your GitHub repository; it's
even free of charge if you are using a public repository.

Let's upload the coverage from our last step into GitHub Pages.

```yaml title=".github/workflows/ci.yml" linenums="80" hl_lines="4 9"
-8<- "docs/codes/2024/0014/junk/pages.yml:80:88"
```

The resulting CI run will have an artifact in its summary page just as below.

<figure markdown="span">
  ![CI Summary](/static/img/2024/0014/full-stack-ci-run-summary.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>CI Summary</figcaption>
</figure>

And if you view the deployed GitHub Pages, you will see the coverage report
as shown below, which you can sort based on your custom column.

<figure markdown="span">
  ![Coverage HTML Report](/static/img/2024/0014/full-stack-coverage-html.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Coverage HTML Report</figcaption>
</figure>

## Full Workflow

The final workflow is not rocket science really :rocket:. It's just a typical
workflow you would see elsewhere.

Here is the full workflow for your reference.

```yaml title=".github/workflows/ci.yml"
-8<- "docs/codes/2024/0014/ci.yml"
```

## Conclusion

I use GitHub for all my projects, and close to second to that is GitHub Actions
for all my automation tasks. There is rarely anything that can't be done in a
GitHub CI these days, especially if you look long and hard enough.

I spend most of my day to day operational tasks preparing a working example
locally before pushing it all into the yard of GitHub Actions.

It is such a life saver, and it has gotten even stronger in the recent years
after the acquisition by Microsoft. I'm glad to say that this is one of the few
moments in the history where conglomerates' acquisition have actually improved
the product for the better.

As for you, I hope you have gained some insights and ideas of your own after
seeing the pattern used here. It can go beyond this once you realize that many
of our applications these days aren't just the app itself; it's all the tooling
and dependencies around it as well.

For any of your current and/or upcoming projects, I seriously recommend you to
take a close look at what GitHub and GitHub Actions can bring to your table.
Most of the time, they are a one-size-fits-all, with all the off-the-shelf
tooling you need to get started.

I hope you have enjoyed this blog post and I look forward to seeing you in the
next one :eyes:. Until then, take care and happy hacking! :penguin: :crab:

[Sebastián Ramírez]: https://github.com/tiangolo/
[FastAPI]: https://fastapi.tiangolo.com/
[Full-Stack FastAPI Template]: https://github.com/tiangolo/full-stack-fastapi-template/tree/0.6.0
[before running the tests]: https://github.com/tiangolo/full-stack-fastapi-template/blob/bd8b50308caebd10f0db318ab35f325a64a318b4/.github/workflows/test.yml#L27
[directive.]: https://docs.gitlab.com/17.0/ee/ci/services/
[fall into this category]: https://github.com/topics/crud-application
