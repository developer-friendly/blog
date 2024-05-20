reqs:
  pip install -U pip -r requirements.txt

serve:
  mkdocs serve --no-strict

prod-build:
  URL_DOWNLOAD=true CI=true mkdocs build
