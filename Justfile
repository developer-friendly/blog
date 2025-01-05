lint:
  pre-commit run -a

reqs:
  pip install -U pip -r requirements.txt

serve:
  mkdocs serve --no-strict

prod-build:
  CI=true mkdocs build

word-count:
  find docs/posts/ docs/codes/ -type f ! -path '*terra*' ! -name tfplan -print | xargs wc -w

[no-cd]
init:
  terragrunt init -upgrade

[no-cd]
plan *args:
  terragrunt plan -out tfplan {{args}}

[no-cd]
apply:
  terragrunt apply tfplan

[no-cd]
output *args:
  terragrunt output {{args}}

[no-cd]
fmt:
  tofu fmt -recursive
  terragrunt run-all hclfmt --terragrunt-non-interactive

checkov:
  checkov --config-file .checkov_config.yaml -d .

[no-cd]
checkov-here:
  checkov -d .
