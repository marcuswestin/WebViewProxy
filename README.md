WebViewProxy
============

Proxy requests for a UIWebView, easily and without mucking around with NSURLProtocol.

Responses to intercepted requests may be served either synchronously or asynchronously - this stands in contrast to the `UIWebViewDelegate` method `-(NSCachedURLResponse *)cachedResponseForRequest:url:host:path:`, which may only intercept requests and serve responses synchronously (making it impossible to e.g. proxy requests through to the network without blocking on the network request).

API
---

### 1: Register handlers with `WebViewProxy` to intercept requests

##### + (void) handleRequestsWithScheme:(NSString\*)scheme handler:(WVPHandler)handler;

Intercept all UIWebView requests with the given scheme.

Examples:

	[WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsWithHost:(NSString\*)host handler:(WVPHandler)handler;

Intercept all UIWebView requests with the given host.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo" handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];


##### + (void) handleRequestsWithHost:(NSString\*)host path:(NSString\*)path handler:(WVPHandler)handler;

Intercept all UIWebView requests matching the given host and URL path.

Examples

	[WebViewProxy handleRequestsWithHost:@"foo.com" path:@"/bar" handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];


##### + (void) handleRequestsWithHost:(NSString\*)host pathPrefix:(NSString\*)pathPrefix handler:(WVPHandler)handler;

Intercept all UIWebView requests matching the given host and URL path prefix.

For example, a handler registered with `[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:...]` will intercept requests for `http://foo.com/bar`, `https://foo.com/bar/cat?wee=yes`, `http://foo.com/bar/arbitrarily/long/subpath`, etc.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsMatching:(NSPredicate\*)predicate handler:(WVPHandler)handler;

Intercept all UIWebView requests where the `NSURL` matches the given `NSPredicate`.

Examples

	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];
	
	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"]  handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];


### 2: Respond through the `WVPResponse`

All registered handlers are given a `WVPRespone* response`. You respond to the request by calling methods on this object.

There are 3 type of APIs for responding to a request

- High level API for responding with an image, text, html or json
- Low level API for responding with the given HTTP headers and NSData
- Piping API for piping the data from a `NSURLConnection` data through to the `WVPResponse`

#### High level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithImage:(UIImage\*)image;
Respond with an image (sent with Content-Type "image/png" by default, or "image/jpg" for requests that end in `.jpg` or `.jpeg`):

Examples

	[WebViewProxy handleRequestsWithHost:@"imageExample" handler:^(WVPResponse *response) {
		UIImage* image = [UIImage imageNamed:@"GoogleLogo.png"];
		[response respondWithImage:image];
	}];

##### - (void) respondWithText:(NSString\*)text;
Respond with a text response (sent with Content-Type "text/plain"):

	[WebViewProxy handleRequestsWithHost:@"textExample" handler:^(WVPResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### - (void) respondWithHTML:(NSString\*)html;
Respond with HTML (sent with Content-Type "text/html"):

	[WebViewProxy handleRequestsWithHost:@"htmlExample" handler:^(WVPResponse *response) {
		[response respondWithText:@"<div class='notification'>Hi!</div>"];
	}];

##### - (void) respondWithJSON:(NSDictionary\*)jsonObject;
Respond with JSON (sent with Content-Type "application/json"):

	[WebViewProxy handleRequestsWithHost:@"textExample" handler:^(WVPResponse *response) {
		NSDictionary* jsonObject = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
		[response respondWithJSON:jsonObject]; // sends '{ "bar":"foo" }'
	}];


#### Low level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithError:(NSInteger)statusCode text:(NSString\*)text;
Respond with the given HTTP status error code and text.

Examples

	[response respondWithError:400 text:@"Bad request"];
	[response respondWithError:404 text:@"Not found"];

##### - (void) setHeader:(NSString\*)headerName value:(NSString\*)headerValue;
Set response headers before responding.

Examples

	[response setHeader:@"Content-Type" value:@"image/gif"];
	[response setHeader:@"Content-Type" value:@"audio/wav"];
	[response setHeader:@"Host" value:@"WebViewProxy"];

##### - (void) respondWithData:(NSData\*)data mimeType:(NSString\*)mimeType;

Respond with the given data and mime type (the mime type gets sent as the HTTP header `Content-Type`).

If mimeType is nil, WebWiewProxy attempts to infer it from the request URL path extension.

Examples

	NSString* greeting = @"Hi!";
	NSData* data = [greeting dataUsingEncoding:NSUTF8StringEncoding];
	[response respondWithData:data mimeType:@"text/plain"];

##### - (void) respondWithData:(NSData\*)data mimeType:(NSString\*)mimeType statusCode:(NSInteger)statusCode;

Respond with the given data, mime type and HTTP status code (the mime type gets sent as the HTTP header `Content-Type`).

If mimeType is nil, WebWiewProxy attempts to infer it from the request URL path extension.

Examples

	NSData* data = [@"<div>Item has been created</div>" dataUsingEncoding:NSUTF8StringEncoding];
	[response respondWithData:data mimeType:@"text/html" statusCode:201];
	[response respondWithData:nil mimeType:nil statusCode:304]; // HTTP status code 304 "Not modified"
	[response respondWithData:nil mimeType:nil statusCode:204]; // HTTP status code 204 "No Content"

##### NSURLCacheStoragePolicy cachePolicy (property)

The cache policy for the response. Default value is `NSURLCacheStorageNotAllowed`

Examples

	response.cachePolicy = NSURLCacheStorageAllowed;
	response.cachePolicy = NSURLCacheStorageAllowedInMemoryOnly;
	response.cachePolicy = NSURLCacheStorageNotAllowed;


#### Piping response API

Pipe an `NSURLResponse` and its data into the `WVPResponse`. This makes it simple to e.g. proxy a request and its response through an NSURLConnection.

Examples to be written.

##### - (void) pipeResponse:(NSURLResponse\*)response;

Pipe an NSURLResponse into the response.

##### - (void) pipeData:(NSData\*)data;

Pipe data into the response.

##### - (void) pipeEnd;

Finish a piped response.
