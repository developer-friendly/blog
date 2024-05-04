data "terraform_remote_state" "hosted_zone" {
  backend = "local"

  config = {
    path = "../hosted-zone/terraform.tfstate"
  }
}

resource "kubernetes_manifest" "external_secret" {
  manifest = yamldecode(<<-EOF
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: route53-issuer-aws-creds
      namespace: cert-manager
    spec:
      data:
        - remoteRef:
            key: /cert-manager/access-key
          secretKey: awsAccessKeyID
        - remoteRef:
            key: /cert-manager/secret-key
          secretKey: awsSecretAccessKey
      refreshInterval: 5m
      secretStoreRef:
        kind: ClusterSecretStore
        name: aws-parameter-store
      target:
        immutable: false
  EOF
  )
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(<<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: route53-issuer
    spec:
      acme:
        email: admin@developer-friendly.blog
        enableDurationFeature: true
        privateKeySecretRef:
          name: route53-issuer
        server: https://acme-v02.api.letsencrypt.org/directory
        solvers:
        - dns01:
            route53:
              hostedZoneID: ${data.terraform_remote_state.hosted_zone.outputs.hosted_zone_id}
              region: eu-central-1
              accessKeyIDSecretRef:
                key: awsAccessKeyID
                name: route53-issuer-aws-creds
              secretAccessKeySecretRef:
                key: awsSecretAccessKey
                name: route53-issuer-aws-creds
  EOF
  )
}
