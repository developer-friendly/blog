$ curl https://pr4.developer-friendly.blog/hello -D -


HTTP/2 200
date: Sat, 08 Mar 2025 09:02:31 GMT
content-type: application/json; charset=utf-8
content-length: 31
x-envoy-upstream-service-time: 0
strict-transport-security: max-age=15552000; includeSubDomains; preload
cf-cache-status: DYNAMIC
report-to: {"endpoints":[{"url":"https:\/\/a.nel.cloudflare.com\/report\/v4?s=70t384ON8YOvLnAKU6%2Bo9%2BoLAhqjcnpjIz2lN6Va4eY1nDPShUtMKfLJPnwpzuRjGo6R%2FwNxy5p6woXODm6brXx5SK5xoln%2B67oKce63xNcxM8AeU4qab%2FoRpgTM1b9pG0%2BrFUEBABQjXuacw2Y%3D"}],"group":"cf-nel","max_age":604800}
nel: {"success_fraction":0,"report_to":"cf-nel","max_age":604800}
speculation-rules: "/cdn-cgi/speculation"
expect-ct: max-age=86400, enforce
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
server: cloudflare
cf-ray: 91d127765f9440fb-SIN
alt-svc: h3=":443"; ma=86400
server-timing: cfL4;desc="?proto=TCP&rtt=94988&min_rtt=85107&rtt_var=28063&sent=7&recv=8&lost=0&retrans=0&sent_bytes=3460&recv_bytes=880&delivery_rate=31641&cwnd=253&unsent_bytes=0&cid=a8621ada7c67c31f&ts=638&x=0"

{"message":"Hello to you too!"}
