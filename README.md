WebViewProxy
============

Proxy requests for a UIWebView, easily and without mucking around with NSURLProtocol.

Responses to intercepted requests may be served either synchronously or asynchronously - this stands in contrast to the `UIWebViewDelegate` method `-(NSCachedURLResponse *)cachedResponseForRequest:url:host:path:`, which may only intercept requests and serve responses synchronously).

API
---

### 1: Register handlers with `WebViewProxy` to intercept requests

##### + (void) handleRequestsWithScheme:(NSString\*)scheme handler:(WebViewProxyHandler)handler;

Intercept all UIWebView requests with the given scheme.

Examples:

	[WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(WebViewProxyResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsWithHost:(NSString\*)host handler:(WebViewProxyHandler)handler;

Intercept all UIWebView requests with the given host.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo" handler:^(WebViewProxyResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsWithHost:(NSString\*)host pathPrefix:(NSString\*)pathPrefix handler:(WebViewProxyHandler)handler;

Intercept all UIWebView requests matching the given URL path prefix for the given host.

For example, a handler registered with `[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:...]` will intercept requests for `http://foo.com/bar`, `https://foo.com/bar/cat?wee=yes`, `http://foo.com/bar/arbitrarily/long/subpath`, etc.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(WebViewProxyResponse *response) {
		[response respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsMatching:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler;

Intercept all UIWebView requests where the `NSURL` matches the given `NSPredicate`.

Examples

	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(WebViewProxyResponse *response) {
		[response respondWithText:@"Hi!"];
	}];
	
	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"]  handler:^(WebViewProxyResponse *response) {
		[response respondWithText:@"Hi!"];
	}];


### 2: Respond through the `WebViewProxyResponse`

All registered handlers are given a `WebViewProxyRespone* response`. You respond to the request by calling methods on this object.

There are 3 type of APIs for responding to a request

- High level API for responding with an image, text, html or json
- Low level API for responding with the given HTTP headers and NSData
- Piping API for piping the data from a `NSURLConnection` data through to the `WebViewProxyResponse`

#### High level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithImage:(UIImage*)image;
Respond with an image (sent with Content-Type "image/png" by default, or "image/jpg" for requests that end in `.jpg` or `.jpeg`):
##### - (void) respondWithImage:(UIImage*)image cachingAllowed:(BOOL)cachingAllowed;
##### - (void) respondWithText:(NSString*)text;
Respond with a text response (sent with Content-Type "text/plain"):
##### - (void) respondWithHTML:(NSString*)html;
Respond with HTML (sent with Content-Type "text/html"):
##### - (void) respondWithJSON:(NSDictionary*)jsonObject;
Respond with JSON (sent with Content-Type "application/json"):

#### Low level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithError:(NSInteger)statusCode text:(NSString*)text;
##### - (void) setHeader:(NSString*)headerName value:(NSString*)headerValue;
Set response headers before responding:
##### - (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType;
##### - (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType cachingAllowed:(BOOL)cachingAllowed;
##### - (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType cachingAllowed:(BOOL)cachingAllowed statusCode:(NSInteger)statusCode;

#### Piping response API

Descriptions and examples will be fleshed out.

##### - (void) pipeResponse:(NSURLResponse*)response cachingAllowed:(BOOL)cachingAllowed;
##### - (void) pipeResponse:(NSURLResponse*)response;
##### - (void) pipeData:(NSData*)data;
##### - (void) pipeEnd;
