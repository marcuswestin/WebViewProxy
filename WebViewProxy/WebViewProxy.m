#include "WebViewProxy.h"

static NSMutableArray* requestMatchers;
static NSPredicate* webViewUserAgentTest;

// A single path matcher
@interface WebViewProxyRequestMatcher : NSObject
@property (strong,nonatomic) NSPredicate* predicate;
@property (copy) WebViewProxyHandler handler;
+ (WebViewProxyRequestMatcher*)matchWithPredicate:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler;
@end
@implementation WebViewProxyRequestMatcher
@synthesize predicate=_predicate, handler=_handler;
+ (WebViewProxyRequestMatcher*)matchWithPredicate:(NSPredicate *)predicate handler:(WebViewProxyHandler)handler {
    WebViewProxyRequestMatcher* matcher = [[WebViewProxyRequestMatcher alloc] init];
    matcher.handler = handler;
    matcher.predicate = predicate;
    return matcher;
}
@end

// This is the proxy response object, through which we send responses
@implementation WebViewProxyResponse {
    @private NSURLProtocol* _protocol;
    @private id<NSURLProtocolClient> _client;
    @private NSURLResponse* _response;
    @private NSMutableDictionary* _headers;
}
@synthesize request=_request;
- (id)_initWithProtocol:(NSURLProtocol *)protocol request:(NSURLRequest *)request client:(id<NSURLProtocolClient>)client {
    if (self = [super init]) {
        _protocol = protocol;
        _request = request;
        _client = client;
        _headers = [NSMutableDictionary dictionary];
    }
    return self;
}
// Convenience API
- (void)respondWithImage:(UIImage *)image {
    [self respondWithImage:image cachingAllowed:YES];
}
- (void)respondWithImage:(UIImage *)image cachingAllowed:(BOOL)cachingAllowed {
    NSURL* url = _request.URL;
    NSString* mimeType = nil;
    NSData* data = nil;
    if ([url.pathExtension isEqualToString:@"jpg"] || [url.pathExtension isEqualToString:@"jpeg"]) {
        mimeType = @"image/jpg";
        data = UIImageJPEGRepresentation(image, 1.0);
    } else {
        if (![url.pathExtension isEqualToString:@"png"]) {
            NSLog(@"WARNING WebViewProxy respondWithImage called for unknown type \"%@\". Defaulting to image/png", url.absoluteString);
        }
        // Default to PNG
        mimeType = @"image/png";
        data = UIImagePNGRepresentation(image);
    }
    [self respondWithData:data mimeType:mimeType cachingAllowed:cachingAllowed];
}
- (void)respondWithJSON:(NSDictionary *)jsonObject {
    NSData* data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
    [self respondWithData:data mimeType:@"application/json" cachingAllowed:NO];
}
- (void)respondWithText:(NSString *)text {
    NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/plain" cachingAllowed:NO];
}
- (void)respondWithHTML:(NSString *)html {
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/html" cachingAllowed:NO];
}
// Core API
- (void)setHeader:(NSString *)headerName value:(NSString *)headerValue {
    [_headers setValue:headerValue forKey:headerName];
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType {
    [self respondWithData:data mimeType:mimeType cachingAllowed:NO];
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType cachingAllowed:(BOOL)cachingAllowed {
    [self respondWithData:data mimeType:mimeType cachingAllowed:cachingAllowed statusCode:200];
}
- (void)respondWithError:(NSInteger)statusCode text:(NSString *)text {
    NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/plain" cachingAllowed:NO statusCode:statusCode];
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType cachingAllowed:(BOOL)cachingAllowed statusCode:(NSInteger)statusCode {
    NSURLCacheStoragePolicy cachePolicy = cachingAllowed ? NSURLCacheStorageAllowed : NSURLCacheStorageNotAllowed;
    [_headers setValue:mimeType forKey:@"Content-Type"];
//    [_headers setValue:[NSNumber numberWithInt:data.length] forKey:@"Content-Length"]; Why does this make throw the NSHTTPURLResponse initiator throw???
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:_request.URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:_headers];
    [_client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:cachePolicy];
    [_client URLProtocol:_protocol didLoadData:data];
//    [_client URLProtocolDidFinishLoading:_protocol]; Why does this cause a memory exception?
}
// Pipe API
- (void)pipeResponse:(NSURLResponse *)response {
    [self pipeResponse:response cachingAllowed:NO];
}
- (void)pipeResponse:(NSURLResponse *)response cachingAllowed:(BOOL)cachingAllowed {
    NSURLCacheStoragePolicy cachePolicy = cachingAllowed ? NSURLCacheStorageAllowed : NSURLCacheStorageNotAllowed;
    [_client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:cachePolicy];
}
- (void)pipeData:(NSData *)data {
    [_client URLProtocol:_protocol didLoadData:data];
}
- (void)pipeEnd {
    [_client URLProtocolDidFinishLoading:_protocol];
}
@end


// The NSURLProtocol implementation that allows us to intercept requests.
@interface WebViewProxyURLProtocol : NSURLProtocol
@property (strong,nonatomic) WebViewProxyResponse* proxyResponse;
@property (strong,nonatomic) WebViewProxyRequestMatcher* requestMatcher;
+ (WebViewProxyRequestMatcher*)findRequestMatcher:(NSURL*)url;
@end

// The actual implementation of our NSURLProtocol subclass
@implementation WebViewProxyURLProtocol
@synthesize proxyResponse=_proxyResponse, requestMatcher=_requestMatcher;

+ (WebViewProxyRequestMatcher *)findRequestMatcher:(NSURL *)url {
    for (WebViewProxyRequestMatcher* requestMatcher in requestMatchers) {
        if ([requestMatcher.predicate evaluateWithObject:url]) {
            return requestMatcher;
        }
    }
    return nil;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString* userAgent = [request.allHTTPHeaderFields valueForKey:@"User-Agent"];
    if (userAgent && ![webViewUserAgentTest evaluateWithObject:userAgent]) { return NO; }
    return ([self findRequestMatcher:request.URL] != nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    // TODO How to handle cachedResponse?
    self.requestMatcher = [self.class findRequestMatcher:request.URL];
    self.proxyResponse = [[WebViewProxyResponse alloc] _initWithProtocol:self request:request client:client];
    return self;
}

- (void)startLoading {
    self.requestMatcher.handler(self.proxyResponse);
}

- (void)stopLoading {
}


@end

// This is the actual WebViewProxy API
@implementation WebViewProxy
+ (void)handleRequestsWithScheme:(NSString *)scheme handler:(WebViewProxyHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"scheme MATCHES[cd] %@", scheme];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithHost:(NSString *)host handler:(WebViewProxyHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"host MATCHES[cd] %@", host];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithPathPrefix:(NSString *)pathPrefix handler:(WebViewProxyHandler)handler {
    NSString* pathPrefixRegex = [NSString stringWithFormat:@"^%@.*", pathPrefix];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"path MATCHES[cd] %@", pathPrefixRegex];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsMatching:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler {
    if (!requestMatchers) {
        requestMatchers = [NSMutableArray array];
        webViewUserAgentTest = [NSPredicate predicateWithFormat:@"self MATCHES '^Mozilla.*Mac OS X.*'"];
        // e.g. "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10A403"
        [NSURLProtocol registerClass:[WebViewProxyURLProtocol class]];
    }
    // Match on any property of NSURL, e.g. "scheme MATCHES 'http' AND host MATCHES 'www.google.com'"
    [requestMatchers addObject:[WebViewProxyRequestMatcher matchWithPredicate:predicate handler:handler]];
}
@end
