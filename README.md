Connect to raw TCP using WebSockets!

Run:

```sh
    $ tcpws 0.0.0.0 3000
```

Then, in your Javascript:

```js
    var ws = new WebSocket("ws://localhost:3000/www.twilio.com/80");
    ws.onmessage = function(e) { console.log(e.data) };
    ws.send("GET / HTTP/1.1\r\nHost: www.twilio.com\r\n\r\n")
```

## Usage

The WebSocket server receives URLs in the format `/{hostname}/{port}`. If I
want to connect my WebSocket to `www.twilio.com` on port 80, I use
`/www.twilio.com/80`:

```js
    new WebSocket("ws://.../www.twilio.com/80");
```
