#include "WebViewProxy.h"

static NSMutableArray* requestMatchers;
static NSPredicate* webViewUserAgentTest;
static NSPredicate* webViewProxyLoopDetection;

// A request matcher, which matches a UIWebView request to a registered WebViewProxyHandler
@interface WVPRequestMatcher : NSObject
@property (strong,nonatomic) NSPredicate* predicate;
@property (copy) WVPHandler handler;
+ (WVPRequestMatcher*)matchWithPredicate:(NSPredicate*)predicate handler:(WVPHandler)handler;
@end
@implementation WVPRequestMatcher
@synthesize predicate=_predicate, handler=_handler;
+ (WVPRequestMatcher*)matchWithPredicate:(NSPredicate *)predicate handler:(WVPHandler)handler {
    WVPRequestMatcher* matcher = [[WVPRequestMatcher alloc] init];
    matcher.handler = handler;
    matcher.predicate = predicate;
    return matcher;
}
@end



// This is the proxy response object, through which we send responses
@implementation WVPResponse {
    NSURLProtocol* _protocol;
    NSMutableDictionary* _headers;
}
@synthesize cachePolicy=_cachePolicy;
- (id)_initWithProtocol:(NSURLProtocol*)protocol {
    if (self = [super init]) {
        _protocol = protocol;
        _headers = [NSMutableDictionary dictionary];
        _cachePolicy = NSURLCacheStorageNotAllowed;
    }
    return self;
}
// High level API
- (void)respondWithImage:(UIImage *)image {
    [self respondWithImage:image mimeType:nil];
}
- (void)respondWithImage:(UIImage *)image mimeType:(NSString *)mimeType {
    NSData* data = nil;
    if (!mimeType) {
        NSString* extension = _protocol.request.URL.pathExtension;
        if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
            mimeType = @"image/jpg";
        } else {
            if (![extension isEqualToString:@"png"]) {
                NSLog(@"WebViewProxy: responding with default mimetype image/png");
            }
            mimeType = @"image/png";
        }
    }
    if ([mimeType isEqualToString:@"image/jpg"]) {
        data = UIImageJPEGRepresentation(image, 1.0);
    } else if ([mimeType isEqualToString:@"image/png"]) {
        data = UIImagePNGRepresentation(image);
    }
    [self respondWithData:data mimeType:mimeType];
}
- (void)respondWithJSON:(NSDictionary *)jsonObject {
    NSData* data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
    [self respondWithData:data mimeType:@"application/json"];
}
- (void)respondWithText:(NSString *)text {
    NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/plain"];
}
- (void)respondWithHTML:(NSString *)html {
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/html"];
}
// Low level API
- (void)setHeader:(NSString *)headerName value:(NSString *)headerValue {
    [_headers setValue:headerValue forKey:headerName];
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType {
    [self respondWithData:data mimeType:mimeType statusCode:200];
}
- (void)respondWithError:(NSInteger)statusCode text:(NSString *)text {
    // TODO We need to add an error responder to signal a network error, as opposed to an HTTP error
    NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/plain" statusCode:statusCode];
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType statusCode:(NSInteger)statusCode {
    if (![_headers objectForKey:@"Content-Type"]) {
        if (!mimeType) {
            NSString* extension = _protocol.request.URL.pathExtension;
            if ([extension isEqualToString:@"png"]) {
                mimeType = @"image/png";
            } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
                mimeType = @"image/jpg";
            } else if ([extension isEqualToString:@"woff"]) {
                mimeType = @"font/woff";
            } else if ([extension isEqualToString:@"ttf"]) {
                mimeType = @"font/opentype";
            } else if ([extension isEqualToString:@"m4a"]) {
                mimeType = @"audio/mp4a-latm";
            }
        }
        if (mimeType) {
            [_headers setValue:mimeType forKey:@"Content-Type"];
        }
    }
    if (![_headers objectForKey:@"Content-Length"]) {
        [_headers setValue:[NSString stringWithFormat:@"%d", data.length] forKey:@"Content-Length"];
    }
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:_protocol.request.URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:_headers];
    [_protocol.client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:_cachePolicy];
    [_protocol.client URLProtocol:_protocol didLoadData:data];
    [_protocol.client URLProtocolDidFinishLoading:_protocol];
}
// Pipe API
- (void)pipeResponse:(NSURLResponse *)response {
    [self pipeResponse:response cachingAllowed:NO];
}
- (void)pipeResponse:(NSURLResponse *)response cachingAllowed:(BOOL)cachingAllowed {
    NSURLCacheStoragePolicy cachePolicy = cachingAllowed ? NSURLCacheStorageAllowed : NSURLCacheStorageNotAllowed;
    [_protocol.client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:cachePolicy];
}
- (void)pipeData:(NSData *)data {
    [_protocol.client URLProtocol:_protocol didLoadData:data];
}
- (void)pipeEnd {
    [_protocol.client URLProtocolDidFinishLoading:_protocol];
}
@end



// The NSURLProtocol implementation that allows us to intercept requests.
@interface WebViewProxyURLProtocol : NSURLProtocol
@property (strong,nonatomic) WVPResponse* proxyResponse;
@property (strong,nonatomic) WVPRequestMatcher* requestMatcher;
+ (WVPRequestMatcher*)findRequestMatcher:(NSURL*)url;
@end
@implementation WebViewProxyURLProtocol {
    NSMutableURLRequest* _correctedRequest;
}
@synthesize proxyResponse=_proxyResponse, requestMatcher=_requestMatcher;
+ (WVPRequestMatcher *)findRequestMatcher:(NSURL *)url {
    for (WVPRequestMatcher* requestMatcher in requestMatchers) {
        if ([requestMatcher.predicate evaluateWithObject:url]) {
            return requestMatcher;
        }
    }
    return nil;
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString* userAgent = [request.allHTTPHeaderFields valueForKey:@"User-Agent"];
    if (userAgent && ![webViewUserAgentTest evaluateWithObject:userAgent]) { return NO; }
    if ([webViewProxyLoopDetection evaluateWithObject:request.URL]) { return NO; }
    return ([self findRequestMatcher:request.URL] != nil);
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    // TODO Implement this here, or expose it through WebViewProxyResponse?
    return NO;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    if (self = [super initWithRequest:request cachedResponse:cachedResponse client:client]) {
        // TODO How to handle cachedResponse?
        _correctedRequest = request.mutableCopy;
        NSString* correctedFragment;
        if (_correctedRequest.URL.fragment) {
            correctedFragment = @"__webviewproxyreq__";
        } else {
            correctedFragment = @"#__webviewproxyreq__";
        }
        _correctedRequest.URL = [NSURL URLWithString:[request.URL.absoluteString stringByAppendingString:correctedFragment]];

        self.requestMatcher = [self.class findRequestMatcher:request.URL];
        self.proxyResponse = [[WVPResponse alloc] _initWithProtocol:self];
    }
    return self;
}
- (void)startLoading {
    self.requestMatcher.handler(_correctedRequest, self.proxyResponse);
}
- (void)stopLoading {
    // TODO Notify self.requestMatcher to stop loading, which in turn should notify WVPResponse handler (which in turn registered with e.g. [response onStopLoading:^(void) { ... }];. Regardless of if an onStopLoading handler is registered, requestMather needs to stop sending signals to _client
}
@end


// This is the actual WebViewProxy API
@interface WebViewProxy (hidden)
+ (NSString *)_normalizePath:(NSString *)path;
@end
@implementation WebViewProxy
+ (void)handleRequestsWithScheme:(NSString *)scheme handler:(WVPHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"scheme MATCHES[cd] %@", scheme];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithHost:(NSString *)host handler:(WVPHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"host MATCHES[cd] %@", host];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithHost:(NSString *)host path:(NSString *)path handler:(WVPHandler)handler {
    path = [self _normalizePath:path];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"host MATCHES[cd] %@ AND path MATCHES[cd] %@", host, path];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithHost:(NSString *)host pathPrefix:(NSString *)pathPrefix handler:(WVPHandler)handler {
    pathPrefix = [self _normalizePath:pathPrefix];
    NSString* pathPrefixRegex = [NSString stringWithFormat:@"^%@.*", pathPrefix];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"host MATCHES[cd] %@ AND path MATCHES[cd] %@", host, pathPrefixRegex];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsMatching:(NSPredicate*)predicate handler:(WVPHandler)handler {
    if (!requestMatchers) {
        requestMatchers = [NSMutableArray array];
        webViewUserAgentTest = [NSPredicate predicateWithFormat:@"self MATCHES '^Mozilla.*Mac OS X.*'"];
        webViewProxyLoopDetection = [NSPredicate predicateWithFormat:@"self.fragment MATCHES '__webviewproxyreq__'"];
        // e.g. "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10A403"
        [NSURLProtocol registerClass:[WebViewProxyURLProtocol class]];
    }
    // Match on any property of NSURL, e.g. "scheme MATCHES 'http' AND host MATCHES 'www.google.com'"
    [requestMatchers addObject:[WVPRequestMatcher matchWithPredicate:predicate handler:handler]];
}
@end
@implementation WebViewProxy (hidden)
+ (NSString *)_normalizePath:(NSString *)path {
    if (![path hasPrefix:@"/"]) {
        // Paths always being with "/", so help out people who forget it
        path = [@"/" stringByAppendingString:path];
    }
    return path;
}
@end
