helm install -n flux-system \
  flux-operator \
  oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --version=0.17.0
