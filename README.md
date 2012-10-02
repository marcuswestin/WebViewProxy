WebViewProxy
============

Easily proxy requests for a UIWebView (without mucking around with NSURLProtocol).

API Sketch
----------

### Register handlers

Intercept all requests for `example.com`:

	[WebViewProxy handleRequestsWithHost:@"example.com" handler:^(WebViewProxyResponse *response) { ... }];

Intercept all `http://` requests:

	[WebViewProxy handleRequestsWithScheme:@"https" handler:^(WebViewProxyResponse *response) { ... }];

Intercept all requests for sub-paths of `/path/to/foo*`:

	[WebViewProxy handleRequestsWithPathPrefix:@"/path/to/foo" handler:^(WebViewProxyResponse *response) { ... }];

Intercept all requests matching a given `NSPredicate`:

	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"scheme MATCHES 'http' AND host MATCHES 'www.google.com'"];
	[WebViewProxy handleRequestsMatching:predicate handler:^(WebViewProxyResponse *response) { ... }];

### Handle requests with `WebViewProxyResponse*`

Respond with a text response (sent with Content-Type "text/plain"):

	[response respondWithText:@"Hello there!"];

Respond with JSON (sent with Content-Type "application/json"):

	NSDictionary* jsonObject = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
	[response respondWithJSON:jsonObject];

Respond with HTML (sent with Content-Type "text/html"):

	[response respondWithHTML:@"<div>Some text</div>"];

Respond with an image (sent with Content-Type "image/png" by default, or "image/jpg" for requests that end in `.jpg` or `.jpeg`):

	UIImage* image = [UIImage imageNamed:@"ExampleImage"];
	[response respondWithImage:image];

Set response headers before responding:

	[response setHeader:@"X-WasIntercepted" value:@"yes"];
	[response respondWithText:@"Hi!"];

Pipe data as you receive it from a `NSURLConnection`:

	NSURLResponse* response = ...;
	[response pipeResponse:response];
	...
	[response pipeData:data];
	...
	[response pipeEnd];
