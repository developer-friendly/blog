curl -X POST \
  https://acl.developer-friendly.blog/relation-tuples/check \
  -Hcontent-type:application/json \
  -d'{"namespace":"endpoints",
      "object":"/api/v1/users",
      "relation":"POST",
      "subject_id":"alice@developer-friendly.blog"}' \
  -D -
