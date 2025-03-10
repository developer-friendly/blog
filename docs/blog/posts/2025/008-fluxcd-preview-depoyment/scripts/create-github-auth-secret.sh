flux -n staging create secret git github-auth \
  --url=https://github.com/developer-friendly/fluxy-dummy \
  --username=meysam81 \
  --password=${GITHUB_TOKEN}
