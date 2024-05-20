---
date: 2024-05-27
draft: true
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
of long-running tests to another host, possibly not blocking your day-to-day
development so that you can speed up your delivery and improve your efficiency.

Thanks to GitHub and the huge opportunity it has provided for the developer
community, we have to worry about test infrastructure less these days than what
used to be the case a few years ago.

Let's see how we can leverage this great technology in our advantage so that
our typical flow is not interrupted and every push to the repository triggers
and enforces the passing of our previously written tests.

## Objective

As per our tradition in this blog post, we should set a clear goal of what we
aim to achieve in this blog post. If things work for the best, we should
accomplish the following tasks:

- [x] Write an application that has a couple of dependencies during its runtime
      operation. Make it so that the app is quite useless without them. This is
      a required objective as we aim to provide a solution to this very common
      problem.
- [x] Have a bunch of integrations tests actually talking to those dependencies
      and verifying that the application is working as expected.
- [x] Write a GitHub Actions workflow that spins up the dependencies before
      the app does, and then runs the integration tests against the app with
      the correct set of configurations so that the app knows where to look for
      its dependent services.
