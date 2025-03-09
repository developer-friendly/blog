$ curl https://pr3.developer-friendly.blog/ -D -


HTTP/2 200
date: Sat, 08 Mar 2025 09:02:37 GMT
content-type: application/json; charset=utf-8
content-length: 27
x-envoy-upstream-service-time: 0
strict-transport-security: max-age=15552000; includeSubDomains; preload
cf-cache-status: DYNAMIC
report-to: {"endpoints":[{"url":"https:\/\/a.nel.cloudflare.com\/report\/v4?s=ogzBE6LUJ2LTjON%2FW7%2Fhes8VBPZABnT9gqLx07b30%2FmZH6Z7BgIm7mFae509jeya%2BOktiefT6fsoDx6yiahQOdlBcY9qFmb6%2Bt3VfK548i02s%2BokGLc3%2FseKGep1Nj35zgoUMr9xHyJJsOc%2F0%2FI%3D"}],"group":"cf-nel","max_age":604800}
nel: {"success_fraction":0,"report_to":"cf-nel","max_age":604800}
expect-ct: max-age=86400, enforce
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
server: cloudflare
cf-ray: 91d12798385f4900-SIN
alt-svc: h3=":443"; ma=86400
server-timing: cfL4;desc="?proto=TCP&rtt=87909&min_rtt=82834&rtt_var=30301&sent=6&recv=8&lost=0&retrans=0&sent_bytes=3439&recv_bytes=874&delivery_rate=34961&cwnd=172&unsent_bytes=0&cid=e015ecd88c5a5cc5&ts=642&x=0"

{"message":"Hello, World!"}
