check:
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
plan:
  terragrunt plan -out tfplan

[no-cd]
apply:
  terragrunt apply tfplan

[no-cd]
fmt:
  tofu fmt -recursive
  terragrunt run-all hclfmt --terragrunt-non-interactive
