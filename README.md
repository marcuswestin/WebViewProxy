WebViewProxy
============

Proxy requests for a UIWebView, easily and without mucking around with NSURLProtocol.

Responses to intercepted requests may be served either synchronously or asynchronously - this stands in contrast to the `UIWebViewDelegate` method `-(NSCachedURLResponse *)cachedResponseForRequest:url:host:path:`, which may only intercept requests and serve responses synchronously (making it impossible to e.g. proxy requests through to the network without blocking on the network request).

If you like WebViewProxy you should also check out [WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge).

API
---

### 1: Register handlers with `WebViewProxy` to intercept requests

##### + (void) handleRequestsWithScheme:(NSString\*)scheme handler:(WVPHandler)handler;

Intercept all UIWebView requests with the given scheme.

Examples:

	[WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsWithHost:(NSString\*)host handler:(WVPHandler)handler;

Intercept all UIWebView requests with the given host.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];


##### + (void) handleRequestsWithHost:(NSString\*)host path:(NSString\*)path handler:(WVPHandler)handler;

Intercept all UIWebView requests matching the given host and URL path.

Examples

	[WebViewProxy handleRequestsWithHost:@"foo.com" path:@"/bar" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];


##### + (void) handleRequestsWithHost:(NSString\*)host pathPrefix:(NSString\*)pathPrefix handler:(WVPHandler)handler;

Intercept all UIWebView requests matching the given host and URL path prefix.

For example, a handler registered with `[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:...]` will intercept requests for `http://foo.com/bar`, `https://foo.com/bar/cat?wee=yes`, `http://foo.com/bar/arbitrarily/long/subpath`, etc.

Examples
	
	[WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];

##### + (void) handleRequestsMatching:(NSPredicate\*)predicate handler:(WVPHandler)handler;

Intercept all UIWebView requests where the `NSURL` matches the given `NSPredicate`.

Examples

	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];
	
	[WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"]  handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];


### 2: Respond through the `WVPResponse`

All registered handlers are given a `WVPRespone* res`. You respond to the request by calling methods on this object.

There are 3 type of APIs for responding to a request

- High level API for responding with an image, text, html or json
- Low level API for responding with the given HTTP headers and NSData
- Piping API for piping the data from a `NSURLConnection` data through to the `WVPResponse`

#### High level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithImage:(UIImage\*)image;
Respond with an image (sent with Content-Type "image/png" by default, or "image/jpg" for requests that end in `.jpg` or `.jpeg`):

Examples

	[WebViewProxy handleRequestsWithHost:@"imageExample" path:@"GoogleLogo.png" handler:^(NSURLRequest* req, WVPResponse *res) {
		UIImage* image = [UIImage imageNamed:@"GoogleLogo.png"];
		[res respondWithImage:image];
	}];

##### - (void) respondWithImage:(UIImage\*)image mimeType:(NSString*)mimeType;
Respond with an image and the given mime type.

Examples

	[WebViewProxy handleRequestsWithHost:@"imageExample" handler:^(NSURLRequest* req, WVPResponse *res) {
		UIImage* image = [UIImage imageNamed:@"GoogleLogo.png"];
		[res respondWithImage:image mimeType:@"image/png"];
	}];

##### - (void) respondWithText:(NSString\*)text;
Respond with a text response (sent with Content-Type "text/plain"):

	[WebViewProxy handleRequestsWithHost:@"textExample" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"Hi!"];
	}];

##### - (void) respondWithHTML:(NSString\*)html;
Respond with HTML (sent with Content-Type "text/html"):

	[WebViewProxy handleRequestsWithHost:@"htmlExample" handler:^(NSURLRequest* req, WVPResponse *res) {
		[res respondWithText:@"<div class='notification'>Hi!</div>"];
	}];

##### - (void) respondWithJSON:(NSDictionary\*)jsonObject;
Respond with JSON (sent with Content-Type "application/json"):

	[WebViewProxy handleRequestsWithHost:@"textExample" handler:^(NSURLRequest* req, WVPResponse *res) {
		NSDictionary* jsonObject = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
		[res respondWithJSON:jsonObject]; // sends '{ "bar":"foo" }'
	}];


#### Low level response API

Descriptions and examples will be fleshed out.

##### - (void) respondWithError:(NSInteger)statusCode text:(NSString\*)text;
Respond with the given HTTP status error code and text.

Examples

	[res respondWithError:400 text:@"Bad request"];
	[res respondWithError:404 text:@"Not found"];

##### - (void) setHeader:(NSString\*)headerName value:(NSString\*)headerValue;
Set a response header before responding.

Examples

	[res setHeader:@"Content-Type" value:@"image/gif"];
	[res setHeader:@"Content-Type" value:@"audio/wav"];
	[res setHeader:@"Host" value:@"WebViewProxy"];

##### - (void) setHeaders:(NSDictionary*)headers;
Set multiple response headers before responding.

Examples

	[res setHeaders:@{ @"Content-Type":@"image/gif", @"Host":@"WebViewProxy" }];

##### - (void) respondWithData:(NSData\*)data mimeType:(NSString\*)mimeType;

Respond with the given data and mime type (the mime type gets sent as the HTTP header `Content-Type`).

If mimeType is nil, WebWiewProxy attempts to infer it from the request URL path extension.

Examples

	NSString* greeting = @"Hi!";
	NSData* data = [greeting dataUsingEncoding:NSUTF8StringEncoding];
	[res respondWithData:data mimeType:@"text/plain"];

##### - (void) respondWithData:(NSData\*)data mimeType:(NSString\*)mimeType statusCode:(NSInteger)statusCode;

Respond with the given data, mime type and HTTP status code (the mime type gets sent as the HTTP header `Content-Type`).

If mimeType is nil, WebWiewProxy attempts to infer it from the request URL path extension.

Examples

	NSData* data = [@"<div>Item has been created</div>" dataUsingEncoding:NSUTF8StringEncoding];
	[res respondWithData:data mimeType:@"text/html" statusCode:201];
	[res respondWithData:nil mimeType:nil statusCode:304]; // HTTP status code 304 "Not modified"
	[res respondWithData:nil mimeType:nil statusCode:204]; // HTTP status code 204 "No Content"

##### NSURLCacheStoragePolicy cachePolicy (property)

The cache policy for the response. Default value is `NSURLCacheStorageNotAllowed`

Examples

	response.cachePolicy = NSURLCacheStorageAllowed;
	response.cachePolicy = NSURLCacheStorageAllowedInMemoryOnly;
	response.cachePolicy = NSURLCacheStorageNotAllowed;

#### Proxy requests

There are many ways to proxy remote requests with `WebViewProxy`. Here is an example using `NSURLConnection`:

	NSOperationQueue* queue = [[NSOperationQueue alloc] init];
	[WebViewProxy handleRequestsWithHost:@"example.proxy" handler:^(NSURLRequest *req, WVPResponse *res) {
		NSString* proxyUrl = [req.URL.absoluteString stringByReplacingOccurrencesOfString:@"example.proxy" withString:@"example.com"];
		NSURLRequest* proxyReq = [NSURLRequest requestWithURL:[NSURL URLWithString:proxyUrl]];
		[NSURLConnection sendAsynchronousRequest:proxyReq queue:queue completionHandler:^(NSURLResponse* proxyRes, NSData* proxyData, NSError* proxyErr) {
			if (proxyErr) { return [res respondWithError:203 text:@"Could not reach server"]; }
			NSInteger statusCode = [(NSHTTPURLResponse*)proxyRes statusCode];
			[res setHeaders:[(NSHTTPURLResponse*)proxyRes allHeaderFields]];
			[res respondWithData:proxyData mimeType:proxyRes.MIMEType statusCode:statusCode];
		}];
	}];

#### Piping response API

Pipe an `NSURLResponse` and its data into the `WVPResponse`. This makes it simple to e.g. proxy a request and its response through an NSURLConnection.

Examples to be written.

##### - (void) pipeResponse:(NSURLResponse\*)response;

Pipe an NSURLResponse into the response.

##### - (void) pipeData:(NSData\*)data;

Pipe data into the response.

##### - (void) pipeEnd;

Finish a piped response.
