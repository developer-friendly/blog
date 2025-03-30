# The first run will result in TCP_MISS
$ curl -D - https://cleanly-quiet-doberman.azureedge.net
HTTP/2 200
date: Sun, 30 Mar 2025 11:05:05 GMT
content-type: text/html
content-length: 259
last-modified: Sun, 30 Mar 2025 10:16:43 GMT
etag: "0x8DD6F73F859103A"
x-ms-request-id: 650b28ca-201e-0003-2563-a1694c000000
x-ms-version: 2018-03-28
x-azure-ref: 20250330T110504Z-18477bc996c8lvv6hC1SG1zcrg000000030000000000cpey
x-fd-int-roxy-purgeid: 4
x-cache: TCP_MISS
accept-ranges: bytes

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Deploy Frontend to Azure CDN</title>
  </head>
  <body>
    <h1>Hello world!</h1>
  </body>
</html>

# But the second one will hit the cache
$ curl -D - https://cleanly-quiet-doberman.azureedge.net
HTTP/2 200
date: Sun, 30 Mar 2025 11:05:08 GMT
content-type: text/html
content-length: 259
last-modified: Sun, 30 Mar 2025 10:16:43 GMT
etag: "0x8DD6F73F859103A"
x-ms-request-id: 650b28ca-201e-0003-2563-a1694c000000
x-ms-version: 2018-03-28
x-azure-ref: 20250330T110508Z-18477bc996ckrzl5hC1SG1eyn0000000058000000000qbc8
x-fd-int-roxy-purgeid: 4
x-cache: TCP_HIT
x-cache-info: L1_T2
accept-ranges: bytes

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Deploy Frontend to Azure CDN</title>
  </head>
  <body>
    <h1>Hello world!</h1>
  </body>
</html>
