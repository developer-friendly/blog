cookie_jar=$(mktemp)
output="$(curl -sS --cookie $cookie_jar --cookie-jar $cookie_jar \
  -H "accept: application/json" \
  https://auth.developer-friendly.blog/self-service/registration/browser)"

csrf_token="$(echo $output | \
  jq -r '.ui.nodes[] |
    select(.attributes.name == "csrf_token") |
    .attributes.value')"
email=hi@developer-friendly.blog
password=123456

action=$(echo $output | jq -r '.ui.action')

curl -XPOST -sS --cookie $cookie_jar --cookie-jar $cookie_jar \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -d "{\"traits.email\":\"$email\",
       \"password\":\"$password\",
       \"csrf_token\":\"$csrf_token\",
       \"method\":\"password\"}" \
  $action
