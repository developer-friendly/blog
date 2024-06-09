---
date: 2024-06-10
description: >-
  TODO
categories:
  - Ory
  - Authentication
  - Authorization
  - Kubernetes
  - External Secrets
  - cert-manager
  - FluxCD
  - GitOps
  - Kustomization
  - Jaeger
  - OpenTelemetry
links:
  - ./posts/2024/0012-ory-kratos.md
  - Source Code: https://github.com/developer-friendly/ory/
image: assets/images/social/2024/06/10/ory-oathkeeper-identity-and-access-proxy-server.png
---

# Ory Oathkeeper: Identity and Access Proxy Server

Ory has a great ecosystem of products when it comes to authentication and
authorization. Ory Oathkeeper is an stateless Identity and Access Proxy server.

It is capable of acting as a reverse-proxy as well as a decision maker and
policy enforcer for other proxy servers.

In today's application development world, if you're operating on HTTP layer,
Ory Oathkeeper has a lot to offer to you.

Stick around to find out how.

<!-- more -->

## What is Ory Oathkeeper?

Chances are, your application needs protection from unauthorized access,
whether deployed into the internet and exposed publicly, or gated behind
private network and only accessible to a certain privileged users.

That is what Ory Oathkeeper is good at, making sure that requests won't make
it to the upstream server unless they are explicitly allowed.

It enforces protective measures to ensure unauthorized requests are denied.
It does that by sitting at the frontier of your infrastructure, receiving
traffics as they come in, inspecting its content, and making decisions based
on the rules you've previously defined and instructed it to.

In this blog post, we will explore what Ory Oathkeeper can do & deploy
and configure it in a way that will protect our upstream server.

This use-case is very common and you have likely encountered it or implemented
a custom solution for you application before.

Hold your breath till the end to find out how to leverage this opensource
solution to your advantage so that you won't ever have to reinvent the wheel
again.

## Why Ory Oathkeeper?

There are numerous reasons why Oathkeeper is a good fit at what it does. Here
are some of the highlights you should be aware of:

- [x] **Proxy Server**: One of the superpower of Oathkeeper is its ability to
  sit at the forefront of your infrastructure and denying unauthorized requests.
  :shield:
- [x] **Decision Maker**: Another mode of running Ory Oathkeeper is to use
  it as a policy enforcer, making decisions on whether or not a request should
  be granted access based on the defined rules. :face_with_monocle:
- [x] **Open Source**: Ory Oathkeeper is open source with a permissive license,
  meaning you can inspect the source code, contribute to it, and even fork it
  if you want to. :flag_white:
- [x] **Stateless**: Ory Oathkeeper is stateless, meaning it doesn't store any
  session data. This is a good thing because it makes it horizontally scalable
  and easy to deploy in a distributed environment. :eagle:
- [x] **Pluggable**: Ory products are adhering to plugin architecture; you can
  use all of them, some of them, or only one of them. This allows a lot of
  flexibility when migrating from a current solution or integrating with a
  third party service. **This is the key feature that makes the entire suite
  very appealing to me.** :electric_plug:
- [x] **Full Featured**: It comes with batteries included, providing
  experimental support for gRPC middleware (if you're into Golang), and also
  stable support for WebSockets[^websocket-support]. :battery:
- [x] **Community**: Ory has a great community of developers and users. If you
  ever get stuck, you can always ask for help in the community Slack
  channel[^ory-slack]. :handshake:

In short and more accurately put, Ory Oathkeeper is an Identity and Access
Proxy (IAP for short)[^oathkeeper-intro]. You will see later in this post how
that comes into play.

!!! note "Disclaimer"

    This blog post is not sponsored by Ory(1). I'm just a happy user of their
    products and I want to share my experience with you.
    { .annotate }

    1.  Though, I definitely wouldn't mind seeing some dollars.
        :money_mouth_face:

## How Does Ory Oathkeeper Work?

There are two modes of operation for Ory Oathkeeper:

1. **Reverse Proxy Mode**: Accepting raw traffics from the client and
   forwarding it to the upstream server.
2. **Decision Maker Mode**: Making decisions whether or not a request should
   be granted access. The frontier proxy server will query the decision API of
   Oathkeeper to grant or deny a request[^decision-api].

Both of these modes rely solely on the API access rules written in
human-readable YAML format[^api-access-rules].(1) You can pass multiple rules to
be applied for multiple upstream servers or backends.
{ .annotate }

1.  Some will disgree with YAML files being _human-readable_ . Though we are
    not in the business of picking sides, we are here to provide a technical
    guide. :shrug:

After this rather long introductory, let's get our hands dirty and roll up
our system administration sleeves.

## Pre-requisites

This guide will be built upon our earlier infrastructure setup. You are more
than welcome to stick to your own technology stack, however, since we had to
deploy and make sure everything works perfectly, we picked our preferred stack
as you see below:

- [x] **Kubernetes**: Though you don't have to, this guide is built on top of
      [Kubernetes], heavingly relying on the operator pattern and the CRDs used
      to deploy our infrastructure as well as the Oathkeeper rules.
- [x] **cert-manager**: We will need internet-accessible host to our cluster
      with TLS certificate from a trusted CA. That is where [cert-manager] and
      [Gateway API] are lending a generous hand. :handshake: Take a look at
      [cert-manager: All-in-One Kubernetes TLS Certificate Manager] if you
      don't have it set up yet.
- [x] **External Secrets**: For fetching the TLS certificates, we need access
      to our DNS provider (Cloudflare in this case). That's where we need
      the [ESO] to provide the API token for the cert-manager. Our earlier
      guide is a perfect place to set it up if you haven't already:
      [External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS].
- [x] **Ory Kratos**: The main and most important part of this guide is the
      integration of Oathkeeper with Kratos. We will use Kratos to authenticate
      the users. Ultimately the requests reaching the upstream server will be
      authenticated and granted access by two of [Ory]'s products. If you need
      help setting up Kratos, refer to
      [Ory Kratos: Headless Authentication, Identity and User Management]
- [ ] **FluxCD**: This is our technology of choice when it comes to Kubernetes
      deployments. You are free to pick simpler tools such as Helm CLI. FluxCD
      is a great tool that requires a bit of learning. Check out our guide on
      [GitOps Demystified: Introduction to FluxCD for Kubernetes] if you need
      a starting point or
      [GitOps Continuous Deployment: FluxCD Advanced CRDs] if you are an
      advanced user.
- [ ] **Jaeger**: For the observation of traces between Oathkeeper and Kratos
      we get to configure both to send their traces to a custom endpoint.
      That's where [Jaeger] comes into play.
- [ ] **Azure account**: Optionally, an [Azure] VM having system assigned
      identity attached to it. We have covered this specific case two weeks
      ago in
      [How to Access AWS From Azure VM Using OpenID Connect]. We use this in
      the last part of this guide to send authenticated requests to Oathkeeper
      from an Azure VM.

## Deploying Ory Oathkeeper

Being an stateless application by nature, Oathkeeper is a perfect fit for
[Kubernetes] Deployment. This allows us to horizontally scale it on demand.

Let's write the server configuration and then deploy it to our Kubernetes
cluster using [FluxCD].

### Oathkeeper Server Configuration

As with every other of [Ory] products, Oathkeeper relies heavily on its
configuration file. This is, as usual, written in YAML format, making it easy
to read and maintain as the complexity grows.

The following configuration is fetched in its entirety from the configuration
reference[^oathkeeper-configuration] and customized to fit our need.

An important thing to note is that we are only using the authenticators
and authorizers that are being used in this blog post. The rest and the
complete reference can be found in the official documentation[^oathkeeper-configuration].

```yaml title="oathkeeper/oathkeeper-server-config.yml"
-8<- "docs/codes/2024/0015/oathkeeper/oathkeeper-server-config.yml"
```

There are a lot to unpack. We may not be able to cover all, but let's explain
some of the highlights.

#### Allowed Authentication Methods

Oathkeeper accepts in its configuration, the methods allowed for authentication
and authorization. If you wish to use OAuth2 authentication, before using it
in a Oathkeeper rule, you have to enable it in the configuration.

```yaml title="oathkeeper/oathkeeper-server-config.yml" linenums="5"
-8<- "docs/codes/2024/0015/oathkeeper/oathkeeper-server-config.yml:5:18"
```

You can customize each method further with specific values. However, we will
leave the customization to the Oathkeeper rule later in this blog. The URLs,
however, are a required field and must be specified at the configuration level.

#### Tracing Endoints

In all of the [Ory] products, you can specify where to ship your traces to.

That is possible through the same configuration over all the (currently) four
products as below:

```yaml title="oathkeeper/oathkeeper-server-config.yml" linenums="50"
-8<- "docs/codes/2024/0015/oathkeeper/oathkeeper-server-config.yml:50:58"
```

#### CORS Configuration

If you're access the Oathkeeper from the browser, you have to set the allowed
origin addresses in the configurations.

Those "allowed" URLs are the hostnames that is in the address bar of a browser.
If you specify a wildcard, Oathkeeper will intelligently allow the concrete
value coming from the `Origin` header of the request.

For example, if `*.developer-friendly.blog` is in the allowed origins and the
browser sends the request with `Origin: example.developer-friendly.blog`, the
Oathkeeper will respond with
`Access-Control-Allow-Origin: example.developer-friendly.blog`. Same goes with
other subdomains.

The `allow_credentials: true` is perhaps the second most important part of this
configuration. Without it your browser will not forward the cookies to
the Oathkeeper server and you will always get a `401 Unauthorized` response.

That part that makes it possible is in these configuration lines:

```yaml title="oathkeeper/oathkeeper-server-config.yml" linenums="59"
-8<- "docs/codes/2024/0015/oathkeeper/oathkeeper-server-config.yml:59:66"
```

### Kubernetes Deployment Resources

There are different ways to deploy Oathkeeper[^oathkeeper-installation] and it
highly depends on your infrastructure more than anything else.

In this blog post, we will refrain from using Docker Compose as that is
something publicly available in the corresponding
repository[^oathkeeper-repository] and example repository[^ory-examples].

Instead, we will share how to deploy Ory Oathkeeper in a [Kubernetes] cluster
using [FluxCD]. We have in-depth guide on both topics in our archive if you're
new to them.

!!! note "Note"

    Beware, the following Ory Oathkeeper deployment is using [Kustomization].

    That requires doing a lot of heavy liftings if you're used to simpler
    deployment tools such as Helm.

    However, the upstream Helm chart seems to be quite inflexible and due to
    the lack of customizations allowed, we had to resort to Kustomization.

    Opting for the Helm installation would require us to do a lot of
    post-render Kustomization, both ugly and unmaintainable.

As of writing this blog post, with the help of Oathkeeper
Maester[^maester-repo], Ory Oathkeeper has native Kubernetes support for
*rules*, i.e., you can create Kubernetes resources to have Oathkeeper rules.
:muscle:

However, this will require proper Kubernetes RBAC as you see below.
:point_down:

```yaml title="oathkeeper/clusterrole.yml"
-8<- "docs/codes/2024/0015/oathkeeper/clusterrole.yml"
```

```yaml title="oathkeeper/serviceaccount-maester.yml"
-8<- "docs/codes/2024/0015/oathkeeper/serviceaccount-maester.yml"
```

```yaml title="oathkeeper/clusterrolebinding.yml"
-8<- "docs/codes/2024/0015/oathkeeper/clusterrolebinding.yml"
```

The following two Deployment resources are the core of our Kustomization stack.

```yaml title="oathkeeper/deployment-oathkeeper-maester.yml"
-8<- "docs/codes/2024/0015/oathkeeper/deployment-oathkeeper-maester.yml"
```

```yaml title="oathkeeper/deployment-oathkeeper.yml"
-8<- "docs/codes/2024/0015/oathkeeper/deployment-oathkeeper.yml"
```

We won't need to expose Oathkeeper Maester, but we require the Oathkeeper to
be accessible to the cluster. Hence the Services below.

```yaml title="oathkeeper/service-oathkeeper-api.yml"
-8<- "docs/codes/2024/0015/oathkeeper/service-oathkeeper-api.yml"
```

```yaml title="oathkeeper/service-oathkeeper-proxy.yml"
-8<- "docs/codes/2024/0015/oathkeeper/service-oathkeeper-proxy.yml"
```

Now let's put this all together into a Kustomization file.

```yaml title="oathkeeper/kustomization.yml"
-8<- "docs/codes/2024/0015/oathkeeper/kustomization.yml"
```

### FluxCD Deployment Kustomization

To deploy the Oathkeeper, we need one last YAML file.

```yaml title="oathkeeper/kustomize.yml"
-8<- "docs/codes/2024/0015/oathkeeper/kustomize.yml"
```

Now let's deploy this into our cluster.

```bash title="" linenums="0"
kubectl apply -f oathkeeper/kustomize.yml
```

This will take a few moments to pull the images and prepare everything. In the
end, you should have the stack ready as you see in the screenshot below.

<figure markdown="span">
  ![FluxCD VSCode Extension](/static/img/2024/0015/fluxcd-vscode.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>FluxCD VSCode Extension</figcaption>
</figure>

That is the VSCode Extension by the way. It can give a pretty good visual at
needed times[^vscode-extension].

### Is There a Simpler Way?

Of course there is.

There is _almost_ always a way to less complexity, especially those
complexities that are accidental!

The following Helm commands do all the things we worked so hard to achieve
in the previous sections[^helm-installation].

```bash title="" linenums="0"
helm repo add ory https://k8s.ory.sh/helm/charts
helm install oathkeeper ory/oathkeeper \
    --set oathkeeper.managedAccessRules=false \
    --version 0.43.x
```

Pick whichever you like. The decision between extensive customization and
simplicity is yours to make.

## Upstream Server Deployment

Whichever method you have employed to deploy Oathkeeper, you should have the
server up and running.

At this point we will start using the Oathkeeper by creating rules and testing
the authentication of our upstream server.

To make sure the test is realistic and with a concrete example, we will deploy
[our previous _echo server_ example], an opensource project that echoes back
the request it receives[^echo-server].

To save space for the actual content, we will only provide the Deployment
definition.

```yaml title="echo-server/deployment.yml"
-8<- "docs/codes/2024/0015/echo-server/deployment.yml"
```

If you're interested to see the entire resources, click below. :point_down:

??? example "Click to expand"

    ```ini title="echo-server/configs.env"
    -8<- "docs/codes/2024/0015/echo-server/configs.env"
    ```

    ```yaml title="echo-server/service.yml"
    -8<- "docs/codes/2024/0015/echo-server/service.yml"
    ```

    ```yaml title="echo-server/kustomization.yml"
    -8<- "docs/codes/2024/0015/echo-server/kustomization.yml"
    ```

    ```yaml title="echo-server/kustomize.yml"
    -8<- "docs/codes/2024/0015/echo-server/kustomize.yml"
    ```

    ```bash title="" linenums="0"
    kubectl apply -f echo-server/kustomize.yml
    ```

## Oathkeeper Rules

The final section of this blog post is the main part. Everything we've built
so far was a preparation for this moment.

### Internet Accessible Endpoint

The first step is to route all the traffic targetting the upstream server to
the Oathkeeper proxy endpoint. Based on different types of deployments, you
may end up executing this step differently.

But, if you have followed along with the guide so far, we need two pieces to
make this come to life:

1. A DNS record for the host we want to expose.
2. The Kubernetes HTTPRoute resource that will accept the incoming traffics.

We will skip the first part as that is something we have covered multiple times
in this blog and it is tailored to your DNS provider.

The second part is as you see below.

Notice that this HTTPRoute has to be in the same namespace as the Oathkeeper.
The reason is that the Gateway will only route the traffics to the same
namespace as the HTTPRoute[^httproute-doc].

In short, we send the internet traffics to the Oathkeeper, and if all looks OK,
it will forward the request to the upstream server.

Otherwise, the user will get the proper error message from Oathkeeper before
even a single byte reaches the upstream server. That is the true power of
Oathkeeper.

```yaml title="echo-server-rule/httproute.yml" hl_lines="7 15-18"
-8<- "docs/codes/2024/0015/echo-server-rule/httproute.yml"
```

Let's deploy this as a Kustomization stack.

```yaml title="echo-server-rule/kustomization.yml"
-8<- "docs/codes/2024/0015/junk/just-httproute-ks.yml"
```

```yaml title="echo-server-rule/kustomize.yml"
-8<- "docs/codes/2024/0015/echo-server-rule/kustomize.yml"
```

```bash title="" linenums="0"
kubectl apply -f echo-server-rule/kustomize.yml
```

### Play 1: Anonymous Access

The first rule we will create is to allow anonymous access to the upstream
server. This is a common use-case where you want to allow everyone to access
the server without any authentication.

```yaml title="echo-server-rule/rule.yml" hl_lines="7 25"
-8<- "docs/codes/2024/0015/junk/anon-rule.yml"
```

The flow of the request is as follows[^oathkeeper-proxy-flow]:

1. Is the request authenticated? Yes, it is anonymous.
2. Is it authorized? Yes, the rule allows access to everyone.
3. Do we need to change anything in the request? Yes, add a single `x-user-id`
header (`guest` for anonymous).
4. What if error happens before reaching upstream? Return the error as JSON.

The flow you see above is the most important part of how Ory Oathkeeper works.
If you master this flow, you can create any kind of rule you want.

Notice that in our Rule definition, we are specifying the `upstream_url` as
the `<service_name>.<namespace>`. This is due to the fact that the Oathkeeper
stack and our echo-server are in separate namespaces.

Also note that the `match.url` is using regex format. This is only possible
if you have `access_rules.matching_strategy: regexp` in your
[Oathkeeper server configuration].

Let's apply this stack:

```yaml title="echo-server-rule/kustomization.yml" hl_lines="3"
-8<- "docs/codes/2024/0015/echo-server-rule/kustomization.yml"
```

Let's send an anonymous request to verify it worked.

```bash title="" linenums="0"
curl https://echo.developer-friendly.blog
```

The response is as below.

```json title="" hl_lines="33"
-8<- "docs/codes/2024/0015/junk/anon-response.json"
```


### Play 2: Authenticated by Ory Kratos

At this stage, we should be able to use our
[previously deployed Ory Kratos server].

Let's modify this rule so that the authenticated users and the identities of
Kratos can send their request to this upstream server[^kratos-whoami].

```yaml title="echo-server-rule/rule.yml" hl_lines="7-14"
-8<- "docs/codes/2024/0015/junk/kratos-rule.yml"
```

If we authenticate to Kratos first and send an HTTP request to the echo-server,
this is what we get.

```json title="" hl_lines="42"
-8<- "docs/codes/2024/0015/junk/kratos-response.json"
```

The `x-user-id` in this response is just the same as if we take the session
information from the Kratos itself.

<figure markdown="span">
  ![Kratos Session Information](/static/img/2024/0015/kratos-whoami.webp "Click to zoom in"){ align=left loading=lazy }
  <figcaption>Kratos Session Information</figcaption>
</figure>

### Play 3: Azure VM Access

The idea in this scenario is that the virtual machine in the [Azure] cloud with
system assigned identity can send authenticated requests to the echo-server,
while Oathkeeper verifying the authenticity of the request using the Azure AD
JWKs endpoint.

```yaml title="echo-server-rule/rule.yml" hl_lines="17-22"
-8<- "docs/codes/2024/0015/echo-server-rule/rule.yml"
```

Using this Oathkeeper rule, if we spin up an Azure VM and enable its system
identity, we can get a JWT token[^az-vm-token] from Azure AD and send it to
Oathkeeper.

```bash title="" linenums="0"
# From inside the Azure VM
token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s)
curl https://echo.developer-friendly.blog -H "Authorization $token"
```

The response will be as you see below. The `x-user-id` is the subject or the
identity ID that the Identity Provider (Azure AD) knows the VM by.

```json title="" hl_lines="31"
-8<- "docs/codes/2024/0015/junk/azure-vm-response.json"
```

## Other Types of Authenticators

As you can imagine, these are just a few examples of the capabilities of
Oathkeeper and what it can bring to your table.

There are other types of authenticators, as well as authorizers, that can be
used to gate an application behind a proxy server, granting access only to
those trusted parties that you have explicitly defined.

As an example, if we remove the `anonymous` access from our rule, the request
will be denied with a `401 Unauthorized` status code.

```json title=""
-8<- "docs/codes/2024/0015/junk/unauthorized-response.json"
```

That is to say, the order in which Oathkeeper processes the rules is important.
It will start from the top, and any authenticator that **can** handle the
authentication process will be used and the rest are ignored, even if the
matched authentication denies the request!

From the official documentation[^api-access-rules-order]:

> `authenticators`: A list of authentication handlers that authenticate the
  provided credentials. Authenticators are checked iteratively from index `0`
  to `n` and the first authenticator to return a positive result will be the
  one used. If you want the rule to first check a specific authenticator before
  "falling back" to others, have that authenticator as the first item in the
  array.

All in all, these will help you sleep tight at night, knowing that your
application is safely guarded by a production grade and robust proxy server,
consulting the proper authentication server before handing it to the upstream
backend.

These days, I use the Oathkeeper even for my admin pages; even the ones not
publicly accessible and only exposed to the private network. This helps secure
the backend from unauthorized access.

There are other types of examples we can provide here, but with the ones you
see here, you should have a good idea on what's possible and what you can do
more with Ory Oathkeeper. Even so, we will have more examples of this topic
in the future for other practical and production use-cases.

## Conclusion

Based on my production experience over the years managing different types of
applications and backends in various industries, there is the same pattern and
approach for a desired authentication layer one might want to have.

It usually includes some sort of consulatation with the Identity Provider,
making sure the identity is coming from a trusted source, and then tightening
it further by making an API call to the authorization server, making sure the
identity is indeed allowed and granted access to such resource.

The plugin architecture of Ory makes this back and forth quite straightforward.
There is little you can't do with the provided services and with the right
configuration and architectural mindset, you can secure many of the knowingly
hard-to-protect applications.

I can't recommend their products highly enough, being a happy customer and
whatnot. But, even more so, knowing that it's easy to fall into the trap of
thinking that one's security and authentication needs are beyond the common
pattern happening around the industry and customization and in-house
development is in order.

That is wrong, in my humble opinion. You will lose countless engineering hours
making something not nearly as secure as what is already available as an
off-the-shelf and opensource solution.

Before investing many of your engineering efforts building something from
scratch, I highly recommend trying Ory's products in the tenth of that time.
:clock:

[Ory] is only one of the many solutions out there, but at the very least, you
should have a basic understanding of what is already available to you around
the industry before going all in on a custom solution.

Make your decisions wisely, do the right things before doing things right.

Happy hacking and until next time :saluting_face:, _ciao_. :penguin: :crab:

[Kubernetes]: /category/kubernetes/
[FluxCD]: /category/fluxcd/
[cert-manager]: /category/cert-manager/
[ESO]: /category/external-secrets/
[How to Access AWS From Azure VM Using OpenID Connect]: ./0013-azure-vm-to-aws.md
[Azure]: /category/azure/
[Ory]: /category/ory/
[Kustomization]: /category/kustomization/
[Jaeger]: /category/jaeger/
[Ory Kratos: Headless Authentication, Identity and User Management]: ./0012-ory-kratos.md
[cert-manager: All-in-One Kubernetes TLS Certificate Manager]: ./0010-cert-manager.md
[External Secrets Operator: Fetching AWS SSM Parameters into Azure AKS]: ./0009-external-secrets-aks-to-aws-ssm.md
[GitOps Demystified: Introduction to FluxCD for Kubernetes]: ./0006-gettings-started-with-gitops-and-fluxcd.md
[our previous _echo server_ example]: ./0010-cert-manager.md#step-4-https-application
[previously deployed Ory Kratos server]: ./0012-ory-kratos.md#kratos-deployment
[Gateway API]: /category/gateway-api/
[GitOps Continuous Deployment: FluxCD Advanced CRDs]: ./0011-fluxcd-advanced-topics.md
[Oathkeeper server configuration]: #oathkeeper-server-configuration

[^websocket-support]: https://www.ory.sh/docs/oathkeeper/guides/proxy-websockets
[^ory-slack]: https://slack.ory.sh/
[^oathkeeper-intro]: https://www.ory.sh/docs/oathkeeper/
[^decision-api]: https://github.com/ory/oathkeeper/blob/6d628fbcc6de9428491add8ab3862e9ed2ba5936/api/decision.go#L56:L121
[^api-access-rules]: https://www.ory.sh/docs/oathkeeper/api-access-rules
[^oathkeeper-configuration]: https://www.ory.sh/docs/oathkeeper/reference/configuration
[^oathkeeper-installation]: https://www.ory.sh/docs/oathkeeper/install
[^oathkeeper-repository]: https://github.com/ory/oathkeeper/tree/v0.40.7
[^ory-examples]: https://github.com/ory/examples/tree/a085b65d21d6d31c1cb728a6b8b28f281f074066
[^maester-repo]: https://github.com/ory/oathkeeper-maester/tree/v0.1.10
[^vscode-extension]: https://github.com/weaveworks/vscode-gitops-tools/tree/0.27.0
[^helm-installation]: https://artifacthub.io/packages/helm/ory/oathkeeper/0.43.1
[^echo-server]: https://github.com/Ealenn/Echo-Server/tree/0.9.2
[^httproute-doc]: https://gateway-api.sigs.k8s.io/api-types/httproute/
[^oathkeeper-proxy-flow]: https://www.ory.sh/docs/oathkeeper/#reverse-proxy
[^kratos-whoami]: https://www.ory.sh/docs/kratos/reference/api#tag/frontend/operation/listMySessions
[^az-vm-token]: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-curl
[^api-access-rules-order]: https://www.ory.sh/docs/oathkeeper/api-access-rules#access-rule-format
