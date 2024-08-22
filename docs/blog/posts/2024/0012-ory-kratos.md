---
date: 2024-05-20
draft: false
description: >-
  Integrate custom UI with Kratos, the opensource identity and user management
  solution. Build and deploy a Single Page Application (SPA) to GitHub Pages.
categories:
  - Kratos
  - JavaScript
  - CI/CD
  - GitHub Pages
  - Authentication
  - cert-manager
  - Cloudflare
  - CSS
  - External Secrets
  - FluxCD
  - GitHub
  - GitHub Actions
  - GitOps
  - HTML
  - IaC
  - IAM
  - Identity Management
  - Infrastructure as Code
  - Kubernetes
  - Kustomization
  - OpenTofu
  - Ory
  - Security
  - Terraform
  - User Management
links:
  - ./blog/posts/2024/0005-install-k3s-on-ubuntu22.md
  - ./blog/posts/2024/0007-oidc-authentication.md
  - ./blog/posts/2024/0004-github-actions-dynamic-matrix.md
  - Source Code: https://github.com/developer-friendly/ory
social:
  cards_layout_options:
    description: >-
      Learn what Ory Kratos has to offer when it comes to authentication and
      identity management to offload the typical workflows off your application.
image: assets/images/social/2024/05/20/ory-kratos-headless-authentication-identity-and-user-management.png
---

# Ory Kratos: Headless Authentication, Identity and User Management

Authentication flows are quite common in the modern day software development.
What we want from one authentication has a lot of overlapping funcionality with
what our other applications need. Even across different industries, you can
still see the same patterns apply when it comes to Identity and User Management.

Ory Kratos solves all that user management under one umbrella of identity server,
providing a clean headless API that you can ship your own UI with. It empowers
you to customize the frontend, while preserving the ever-common backend that
is backed by the robust SQL database.

In this blog post, we will cover the introduction and basics of Ory Kratos,
as well as the steps and guides to write your integration client.

If you've always wanted to stop reinventing the wheel, reduce code duplication
and to follow security best practices, then Ory Kratos and this blog post is
for you!

<!-- more -->

## Kratos Auth

Over the entire course of my professional career, I have seen countless times
where the application needed the same type and pattern of authentication
protection.

A user signs up, logs in, logs out, and resets their password. The same idea,
the same pattern, the same flow!

I have looked over different solutions and the way they handled their
authentication system. Some are good, some are terrible, some are paid, some
open-source.

This blog post is not here to tell you which to choose.

It's here to give you an idea of what Ory Kratos is, what problem it solves,
and how **you** can use it to solve your own problem if you so choose to.

You should do your own research and decide for yourself whether or not what Ory
Kratos provides fit your need; every problem's context is different and your
technology stack may or may not be adaptable to Ory Kratos.

<!-- subscribe -->

## Who is this for?

The reality is, if you're reading this, you're likely an engineer of some sort.
Perhaps an individual contributor, or maybe a decision maker somewhere down the
organization hierarchy.

The guide to follow for the rest of this post is intuitive and easy to follow.
If you've read any of the authentication RFCs, or worked with authentication
systems before in anyway, you have a good understanding of what's about to come:
_what is and what isn't authentication_ that is.

I will mention the highlighting factors when it comes to theories, but this
blog post is mainly hands-on with a lot of codes and examples.

## Ory Kratos

We should set a clear objective of what we're trying to achieve here so that
we can best prepare for the journey ahead.

The main goal is to write a frontend client for Ory Kratos so that the users
of our application(s) can sign-up, sign-in, etc. The nature of the backend
application (the app we are trying to protect behind authentication) doesn't
matter here.

The user management and the database records of the identities will be kept on
the Ory Kratos side and as such, any user-related authentication flow will
be solely handled by Ory Kratos.

<figure markdown="span">
  ![System Diagram](/blog/static/img/2024/0012/ory-kratos.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>System Diagram</figcaption>
</figure>

In a future post, we will learn how to protect the backend service in a private
network and only send authenticated requests to the backend application using
a combination of Ory Kratos[^1] and Ory Oathkeeper[^2].

## Installation

This blog post does not make any assumptions on how you want to run Ory Kratos,
nor its corresponding frontend code. That is your responsibility to figure out!

However, since for the purpose of demo we had to deploy both somewhere and
somehow, the technology stack picked here is as follows. Feel free to adapt
to your own stack:

- [x] The Kratos server has been installed as a Helm installation[^3] on a
      Kubernetes cluster. The Kratos public endpoints are exposed to the
      internet using the Gateway API[^4] and with the help of
      Cilium. We have guides in our archive for [Kubernetes](/category/kubernetes/)
      and [Cilium](/category/cilium/) installation if you need further help.
- [x] The source code for the frontend[^5] is written in pure Vanilla JavaScript,
      bundled with ViteJS[^6] and built with Bun[^7]. I am by no means a frontender
      as you shall see shortly for yourself, however, the code is
      a Single Page Application without any JS framework; cause that's how
      Maximiliano Firtman[^8] taught the rest of us possible, among many
      disbeliefs!
- [x] The CI takes care of the deployment to the GitHub Pages[^9]. Both are
      free for public repositories.

With that somewhat unconventional stack, let's see how we can create our own
custom UI for the Ory Kratos[^10].

## Kratos Configuration

The first step when it comes to Ory Kratos, is to have your config file ready.
That is the starting point you should worry about before starting anything
else.

There are many different attributes you can configure in Ory Kratos. Some of
which are required fields, all of which defines the way you want Kratos to work
for you.

In this blog post, we can't cover all the attributes and the combination of
different values you can assign to them. However, we will cover the essentials
to get you going. You won't have a hard time following the rest for yourself
(they have a decent documentation[^11]).

To get started, and to have a complete reference of all the available keys,
you can copy the entire configuration from the official documentation[^12] and
modify and customize it as you see fit. Below is the screenshot of how to do
that.

<figure markdown="span">
  ![Kratos Configuration Reference](/blog/static/img/2024/0012/kratos-config-reference.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Kratos Configuration Reference</figcaption>
</figure>

The basic configuration that can kick things off looks something like this:

```yaml title="kratos/kratos-server-config.yml"
-8<- "docs/blog/codes/2024/0012/kratos/kratos-server-config.yml"
```

There is a lot to uncover in this configuration file, and believe me there are
many others trimmed for the sake of brevity.

But, let's explain some of the highlights from this file.

### Identity Schema

The first section defines what type of schema you want to use. This "schema"
is the definition of your users signing up and their attributes saved in the
database. This will be an HTML form with all the fields you like filled by your
users.

You can have more than one schema definition, which is a perfect use case for
having different types of users, e.g., _admin_, _employee_, _customer_, etc.[^13]

For our simple use case, there's only one.

You can pass the identity schema definition from either a file, a remote URL,
or even a base64 encoded string. The choice is yours. However, keep in mind
that readability matters and you have to be able to make sense of the schema
by looking at it and base64 is not it!

In essence, the following identity schema JSON definition will result in the
HTML form you see in the next screenshot.

```yaml title=""
-8<- "docs/blog/codes/2024/0012/junk/kratos.identity-schema.json"
```

<figure markdown="span">
  ![HTML Sign Up Form](/blog/static/img/2024/0012/ory-example-register-page.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>HTML Sign Up Form</figcaption>
</figure>

### UI URLs

This part of the configuration file defines the way you want Kratos to redirect
requests to your frontend.

The path to your frontend endpoints are custom to your application; pick what's
best for you. However, bear in mind that the Kratos server and your frontend
application **MUST** be hosted under the same root domain.

The reason is for the cookies and the constraint around not being able to set
a cookie from one domain to another; imagine if anyone could set a cookie on
your domain from their own domain! :scream:

### Cookie and Session

This section of the configuration file specifies the domain you want to set
cookies for. It is essentially THE key to keeping consistency and correctness
between the Ory Kratos server and your frontend. Else, they won't work!

The key point to keep in mind, again, is to host both the frontend and the
Kratos server under the same root-level domain. For example:

- :white_check_mark: `auth.example.com` for Kratos and `ui.example.com` or
  `example.com` for the frontend are fine.
- :x: `something.com` for Kratos and `something-else.com` for frontend are not.

We will provide more details on the cookie and the domain later in this post.

## Kratos Deployment

Skip this section if you have Kratos deployed elsewhere or are using the
Ory Network[^14] with a paid plan. :airplane:

You don't have to self-host your Ory Kratos server if you don't want to. The
Ory team provides a hosted version of Ory Kratos, as well as other Ory products
on their Ory Network.

However, as of writing this blog post, they don't allow custom domains on their
free version. Not having the same top-level root domain is a big no-no for
Kratos and its UI and as such, we'll deploy the opensource version in our
Kubernetes deployment.

If you need assistance setting up a [Kubernetes](/category/kubernetes/) cluster,
follow one of our earlier guides. The main requirement, however, is that the
cluster needs to be internet-facing.

We are using FluxCD CRDs here. If you're new to FluxCD, check out our earlier
[beginner's guide][fluxcd-guide] to get up to speed.

We are also using [External Secrets Operator][eso-guide] and [cert-manager] in
this setup. We have guides on those as well, so feel free to check them out.

```yaml title="kratos/repository.yml"
-8<- "docs/blog/codes/2024/0012/kratos/repository.yml"
```

Kratos server is able to read the config file from the specified file, or from
the environment variables[^15]. Which is why we are capitalizing all the environments
in the following ExternalSecret resource; remember all those values in our
`kratos/kratos-server-config.yml` where we passed `PLACEHOLDER` as value!?

```yaml title="kratos/externalsecret.yml" hl_lines="4"
-8<- "docs/blog/codes/2024/0012/kratos/externalsecret.yml"
```

The following [Kustomization](/category/kustomization/) patches applied to the
HelmRelease are just because of the lack of flexibility in the Ory Kratos' Helm
chart. We have to manually pass some of the otherwise missing values.

```yaml title="kratos/release.yml" hl_lines="25 66 78"
-8<- "docs/blog/codes/2024/0012/kratos/release.yml"
```

```yaml title="kratos/helm-values.yml" hl_lines="13 23"
-8<- "docs/blog/codes/2024/0012/kratos/helm-values.yml"
```

```yaml title="kratos/httproute.yml"
-8<- "docs/blog/codes/2024/0012/kratos/httproute.yml"
```

```yaml title="kratos/kustomizeconfig.yml"
-8<- "docs/blog/codes/2024/0012/kratos/kustomizeconfig.yml"
```

```yaml title="kratos/kustomization.yml" hl_lines="7"
-8<- "docs/blog/codes/2024/0012/kratos/kustomization.yml"
```

Finally, we will create this stack as follow:

```yaml title="kratos/kustomize.yml"
-8<- "docs/blog/codes/2024/0012/kratos/kustomize.yml"
```

```shell title="" linenums="0"
kubectl apply -f kratos/kustomize.yml
```

This is all the Kubernetes knowledge we will need for this blog post. Promise!
:fingers_crossed:

That is to say, if you're not a Kubernetes guy, don't worry. All you need from
this step, is an internet-accessible Ory Kratos server hosted under the same
top-level domain as your UI frontend.

Moving forward, we will only work on [JavaScript](/category/javascript/),
[HTML](/category/html/), and [CSS](/category/css/). :nerd:

## Frontend Code

If you've been waiting for the UI part, this is it! :tada:

At this point, we will shift our focus to the frontend code; The custom UI
for our Kratos server.

This will be the page that our users will see once they open the application.
Everything else, is the communication between this frontend and the Ory Kratos.

To start things off, we will need a couple of unavoidable static files for
template and styling.

**NOTE**: I am by no means a frontender. That is not my strong suit. Yet the
following SPA gets the job done. Believe me, I have tested it! :innocent:
And, if you see any flaw with the code style, or something that you don't like,
the repository of this website is publicly available and welcomes your pull
requests.
:hugging:

### HTML

The app's starting page is the following `index.html` file. It's simple, and
that is its superpower. :superhero:

```html title="frontend/index.html"
-8<- "docs/blog/codes/2024/0012/junk/index-without-spa-hack.html"
```

### CSS

Beside the header, footer and the flex container for the form and table, there
is nothing special about the styling either. :point_down:

??? example "Click to expand"

    ```css title="frontend/assets/styles.css"
    -8<- "docs/blog/codes/2024/0012/frontend/assets/styles.css"
    ```

## Flow 101

Now the main business logic of the app we're trying to build.

But, before we jump into code, here's the diagram you should be aware of when
it comes to Ory Kratos.

<figure markdown="span">
  ![Ory Kratos and Frontend Flow](/blog/static/img/2024/0012/frontend-and-kratos-flow.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Ory Kratos and Frontend Flow</figcaption>
</figure>

This diagram has all the steps to initiate and complete a **flow** in Ory Kratos.
And be very mindful of the word **flow** here cause this is the most important
thing Kratos understands and responds with.

Anytime you need something from Ory Kratos, it will find its way, one way or
another, through a flow.

There are different types of flows in Ory Kratos. Six to be specific:

- Login flow
- Registration flow
- Recovery flow
- Verification flow
- Settings flow
- Logout flow

These flows are something you should be aware of, and implement the frontend
counterpart for. The backend is already taken care of by Ory Kratos.

Although, fret not, these flows are quite similar in nature and a general piece
of code can handle most, if not all.

## Implement One Flow For All

Any application will start with registration and that is where we start our
journey.

In the registration flow, we are asking Ory Kratos what it takes for us to
start and submit a registration request and Ory Kratos will respond with the
fields you need to submit by consulting the very same identity schema we
passed it earlier.

If you know `curl`, this will be the registration flow in a nutshell:

```shell title="" linenums="0"
-8<- "docs/blog/codes/2024/0012/junk/registration-flow-by-curl.sh"
```

If that sounds too complicated to comprehend, don't worry. We'll break it down
in our upcoming JavaScript code.

Remember the diagram we saw earlier between the frontend and the Ory Kratos?
We will start by initiating a flow.

```javascript title="frontend/src/utils.js" hl_lines="4"
-8<- "docs/blog/codes/2024/0012/junk/init-flow.js"
```

Pay close attention that we are explicitly asking the fetch API to **include the
credentials** in our call to the Ory Kratos server. Ignoring that will result
in the required cookies not being sent to the server and your flow will never
go pass the initial step! :warning:

```javascript title="frontend/src/flow.js"
-8<- "docs/blog/codes/2024/0012/junk/get-flow-json.js"
```

:material-check-all: Note the `accept` header we pass to the fetch API on line
8. This will make sure that the Kratos server responds with the JSON and won't
redirect us to the same URL as we are in right now. Ignore doing so and it will
result in double redirection to the current web address, which will nullify the
`origin` header and you'll face a CORS error[^16].

At this point, we have the JSON response from the Kratos server. We have to
use that information to dynamically create an HTML form to render for the user.

In order to be able to parse the JSON and render an HTML form from it, you have
to know what type of JSON response you can expect from the Kratos server.

The JSON response from the registration flow looks something like the following.
:point_down: If you pay close attention, you will notice that the JSON response
resembles a lot like the identity schema we passed to the Kratos server earlier.

??? example "Click to expand"

    ```json title=""
    -8<- "docs/blog/codes/2024/0012/junk/registration-flow-response.json"
    ```

By visualizing the JSON response, we can see that the `.ui.nodes` has all the
fields we specified in our identity schema. We would only need to use this info
to build the HTML form.

This step is a lot subjective and you can get very creative. Yet we simply
create a bunch of inputs and labels inside an HTML form.

```javascript title="frontend/src/utils.js" hl_lines="22-92"
-8<- "docs/blog/codes/2024/0012/frontend/src/utils.js"
```

Not much is to say regarding the logic happening here. However, notice that
we are intentionally deferring the creation of the password input until the
very end. That is just a bit unfortunate since Kratos' JSON response does not
send the orders of inputs as we'd like it; I would expect Kratos to do
this out of the box!

```javascript title="frontend/src/flow.js" hl_lines="1 4 11-15 19 21"
-8<- "docs/blog/codes/2024/0012/frontend/src/flow.js"
```

We have most of what we need as far as JavaScript goes, yet there is still the
entrypoint as well as the Vanilla JS router to take care of.

```javascript title="frontend/src/router.js"
-8<- "docs/blog/codes/2024/0012/frontend/src/router.js"
```

```javascript title="frontend/app.js"
-8<- "docs/blog/codes/2024/0012/frontend/app.js"
```

## Bundling the Frontend

We mentioned that we are using ViteJS[^6] for bundling our code. We don't do a lot
of crazy stuff in this code. Yet one crucial feature we need (not present in
VanillaJS) is the ability to override the variables from the environment
variables. That is where ViteJS provides a great hand. :handshake:

```javascript title="frontend/src/config.js"
-8<- "docs/blog/codes/2024/0012/frontend/src/config.js"
```

This way, whenever we want to customize the target Kratos server URL, all we
have to do is to pass it as an environment variable as below before building
the code:

```shell title="" linenums="0"
export VITE_KRATOS_HOST="https://kratos.example.com"
```

## Building the frontend

For this project, we have picked Bun[^7] as our build tool. It's simple & fast
:zap: and does the job well. :muscle:

```json title="frontend/package.json"
-8<- "docs/blog/codes/2024/0012/frontend/package.json"
```

```shell title="" linenums="0"
bun install
bun run build
```

## CI Definition

When our project is ready to be published, we will use
[GitHub Actions](/category/github-actions/) to build and deploy the frontend to
the [GitHub Pages](/category/github-pages/).

```yaml title=".github/workflows/ci.yml"
-8<- "docs/blog/codes/2024/0012/junk/ci.yml"
```

With this workflow, upon every push to the `main` branch we will have our
application ready to be served on the GitHub Pages. In our case, this
repository is public and there is no charge for the CI, as well as for the
GitHub Pages.

## GitHub Pages SPA Hack

As of writing this blog post, GitHub Pages does **not** natively support Single
Page Applications[^17]. This is a blocker for our application
since it is a SPA. To get around that, we will get help from the community to
come up with something a bit creative[^18].

The idea is to create a custom `404.html` which will have enough JavaScript code
to redirect the page to our SPA's `index.html`, having it's URI as query parameter.
On the other hand, the `index.html` will also include a JavaScript code to
parse the query parameter and let our Vanilla JS router take care of the rest.

```html title="frontend/404.html"
-8<- "docs/blog/codes/2024/0012/frontend/404.html"
```

**NOTE**: The parsing of the query parameter in the `index.html` has to happen
before the our own JS code is loaded. This allows for our router not to worry
about this hacky redirection. :exclamation:

```html title="frontend/index.html" hl_lines="9-20"
-8<- "docs/blog/codes/2024/0012/frontend/index.html"
```

And now we need to include the new `404.html` as an asset in ViteJS config:

```javascript title="frontend/vite.config.js"
-8<- "docs/blog/codes/2024/0012/frontend/vite.config.js"
```

## Logout Flow

Among the flows we mentioned earlier, all can be handled by our "general"
flow implementation. However, the logout flow is a bit different[^19]. It
requires its own implementation as there will no longer be a form. You may want
to include a confirmation page for your app but that's out of scope as far as
Kratos server is concerned.

```javascript title="frontend/src/logout.js"
-8<- "docs/blog/codes/2024/0012/frontend/src/logout.js"
```

## Bonus: GitHub Pages Custom Domain

The application we have deployed in the GitHub Pages so far is accessible with
the URL assigned by GitHub to each repository's Pages instance.

[https://USERNAME.github.io/REPOSITORY](#)

In our case, that turns out to be the following format:

<https://developer-friendly.github.io/ory>

There is nothing wrong with this URL. However, in a serious production
application, you would want to have your own domain name. This is where the
custom domain name comes in; And unlike other service providers, GitHub **does
not** charge you extra for this feature.

The DNS record we want to create should be the following:

{{ read_csv('docs/blog/codes/2024/0012/junk/dns.csv') }}

And since the [developer-friendly.blog] domain is hosted on Cloudflare, here's
how the [IaC](/category/iac/) will look like for such a change.

```hcl title="dns/variables.tf"
-8<- "docs/blog/codes/2024/0012/dns/variables.tf"
```

```hcl title="dns/versions.tf"
-8<- "docs/blog/codes/2024/0012/dns/versions.tf"
```

```hcl title="dns/main.tf"
-8<- "docs/blog/codes/2024/0012/dns/main.tf"
```

Now, let's apply this stack using [OpenTofu](/category/opentofu/):

```shell title="" linenums="0"
export TF_VAR_cloudflare_api_token="PLACEHOLDER"
tofu init
tofu plan -out tfplan
tofu apply tfplan
```

## Conclusion

That wraps up all we had to say for this blog post. The main objective was to
create a custom frontend for the Ory Kratos server.

As you saw in the post, the root domain for both the Kratos server and the
frontend **should** be the same for the cookies to work.

Among many benefits that Kratos brings to the table, many years of development
and feedback from the community, following security best practices based on the
well-known recommendations and standards[^20], not reinventing the wheel, and
separation of concern are just a few to name.

I honestly rarely think of writing my own authentication and identity
management system these days anymore. Cause Kratos does a perfect job at what
it was meant to. I invite you to also tip your toes and give it a fair shot if
you haven't already.

I know many folks might prefer other alternatives like Keycloak, Auth0, or
Firebase. And that's perfectly fine. The choice is yours to make. However, don't
let that stop you from exploring what Ory Kratos has to offer.

In a future post, I will explore more of the Ory products and the intersection
of them all when it comes to delivering a robust auth solution on top of your
application logic.

I wish you have gained something from this post, and I hope you forgive me for
the possible awful frontend code an SRE guy has provided before your eyes.
:sweat_smile:

I have learned a lot from Kyle Simpson's[^21] _You Don't Know JS_
series and most of the code you've seen here are following the patterns he
teaches. That is to say that I have no regret not using arrow functions,
avoiding the overloaded use of `const` keyword, and not using triple equals
`===` everywhere. :wink:

Until next time :saluting_face:, _ciao_ :cowboy: and happy hacking! :penguin:
 :crab:

[^1]: https://www.ory.sh/docs/kratos/ory-kratos-intro
[^2]: https://www.ory.sh/docs/oathkeeper/
[^3]: https://artifacthub.io/packages/helm/ory/kratos/0.42.0
[^4]: https://gateway-api.sigs.k8s.io/
[^5]: https://github.com/developer-friendly/ory
[^6]: https://v4.vitejs.dev/
[^7]: https://bun.sh/docs
[^8]: https://firtman.github.io/vanilla/
[^9]: https://pages.github.com/
[^10]: https://www.ory.sh/docs/kratos/bring-your-own-ui/custom-ui-overview
[^11]: https://www.ory.sh/docs/
[^12]: https://www.ory.sh/docs/kratos/reference/configuration
[^13]: https://www.ory.sh/docs/kratos/manage-identities/identity-schema
[^14]: https://console.ory.sh/
[^15]: https://www.ory.sh/docs/kratos/configuring
[^16]: https://stackoverflow.com/questions/30193851/ajax-call-following-302-redirect-sets-origin-to-null
[^17]: https://github.com/orgs/community/discussions/64096
[^18]: https://github.com/rafgraph/spa-github-pages
[^19]: https://www.ory.sh/docs/kratos/self-service/flows/user-logout
[^20]: https://www.ory.sh/docs/ecosystem/projects#ory-kratos
[^21]: https://frontendmasters.com/teachers/kyle-simpson/

[fluxcd-guide]: ./0006-gettings-started-with-gitops-and-fluxcd.md
[eso-guide]: ./0009-external-secrets-aks-to-aws-ssm.md
[cert-manager]: ./0010-cert-manager.md
[developer-friendly.blog]: https://developer-friendly.blog
