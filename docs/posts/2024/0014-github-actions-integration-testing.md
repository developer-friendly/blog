---
date: 2024-06-03
description: >-
  TODO
categories:
  - GitHub
  - GitHub Actions
---

# Integration Testing with GitHub Actions

GitHub Actions is a great CI/CD tool to automate the daily operations of your
application lifecycle in many ways. It comes with many features out of the box
and even the ones that are missing are wholeheartedly provided by the community.

There are many great and brilliant engineers working daily to provide a
fantastic experience for the rest of us.

In this blog post, you will learn how to perform your integration testing
using GitHub Actions with all its dependencies and serivces spun up beforehand.

Stick around till the end to find out how.

<!-- more -->

## Introduction

If you're a fan of writing tests for your software, there's a good chance that
you like to run the fast and small tests on your machine, and delegate the task
of long-running test execution to another host.

This allows for improved productivity as you can continue to enhance your
software while the tests are running in the background.

It also allows for a high confidence and a robust delivery, knowing that all
the changes are gated behind a set of tests that are run automatically for
every push.

Thanks to GitHub and the huge productivity boost it has provided for the
developer community, we have to worry about test infrastructure less these days
than what used to be the case a few years ago.

Let's see how we can leverage this great technology in our advantage so that
our typical flow is not interrupted and every push to the repository triggers
and enforces the passing of our previously written tests.

## Objective

As per our tradition in this blog post, we should set a clear goal of what we
aim to achieve in this blog post. If things work for the best, we should
accomplish the following tasks:

- [x] Find an application that has a couple of dependencies (e.g. database,
      caching, etc.) during its runtime operation. Make it so that the app is
      quite useless without them. This is a required objective as we aim to
      provide a solution to this very common problem.
- [x] Have a bunch of integrations tests actually talking to those dependencies
      and verifying that the application is working as expected.
- [x] Write a GitHub Actions workflow that spins up the dependencies before
      the app, and then run the integration tests against the app with
      the correct set of configurations so that the app knows where to look for
      its dependent services.

If that is something you have seen and dealt with before, this blog post may
provide you a reliable yet so underutilized solution to this problem.

## CRUD Application

There are numerous apps that fall into this category, especially opensource
products where we are able to grab the source code and tweak it to our needs.

The one picked for this blog post comes from the famous [Sebastián Ramírez],
the creator of [FastAPI]. The app is called [Full-Stack FastAPI Template].

It has both frontend and backend. However, the focus of this blog post will
be mainly on the backend part of the application.

The backend needs a PostgreSQL database to run and operate and the same goes
for its integration tests.

The framework of the test and other aspects of writing tests is not in the scope
for this blog post. We are mainly interested in:

1. Having integration tests
2. Running them in GitHub Actions

Since running the tests in the CI means having the database up and running,
it's a great example to show how you can run your integration tests in
[GitHub Actions](/category/github-actions/).

## Run Tests Locally

Let us first run the tests locally, track the dependencies and understand the
interconnection between the app and the database.

```bash title="" linenums="0"
git clone github.com:tiangolo/full-stack-fastapi-template
cd full-stack-fastapi-template
```

At this point, we should have the repo in the local machine.

We are not gonna do lots of crazy stuff here, so let us just run the database.

```bash title="" linenums="0"
docker compose up -d db
```

[Sebastián Ramírez]: https://github.com/tiangolo/
[FastAPI]: https://fastapi.tiangolo.com/
[Full-Stack FastAPI Template]: https://github.com/tiangolo/full-stack-fastapi-template/
