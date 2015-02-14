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
    NSURLRequest* _request;
    NSURLProtocol* _protocol;
    NSMutableDictionary* _headers;
    BOOL _stopped;
    StopLoadingHandler _stopLoadingHandler;
}
@synthesize cachePolicy=_cachePolicy, request=_request;
- (id)_initWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol*)protocol {
    if (self = [super init]) {
        _request = request;
        _protocol = protocol;
        _headers = [NSMutableDictionary dictionary];
        _cachePolicy = NSURLCacheStorageNotAllowed;
    }
    return self;
}
- (void) _stopLoading {
    _stopped = YES;
    if (_stopLoadingHandler) {
        _stopLoadingHandler();
        _stopLoadingHandler = nil;
    }
}
// High level API
- (void)respondWithImage:(WVPImageType *)image {
    [self respondWithImage:image mimeType:nil];
}
- (void)respondWithImage:(WVPImageType *)image mimeType:(NSString *)mimeType {
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
    [self _respondWithImage:image mimeType:mimeType];
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
- (void)handleStopLoadingRequest:(StopLoadingHandler)handler {
    _stopLoadingHandler = handler;
}
// Low level API
- (void)setHeader:(NSString *)headerName value:(NSString *)headerValue {
    _headers[headerName] = headerValue;
}
- (void)setHeaders:(NSDictionary *)headers {
    for (NSString* headerName in headers) {
        [self setHeader:headerName value:headers[headerName]];
    }
}
- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType {
    [self respondWithData:data mimeType:mimeType statusCode:200];
}
- (void)respondWithStatusCode:(NSInteger)statusCode text:(NSString *)text {
    NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:@"text/plain" statusCode:statusCode];
}

- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType statusCode:(NSInteger)statusCode {
    if (_stopped) { return; }
    if (!_headers[@"Content-Type"]) {
        if (!mimeType) {
            mimeType = [self _mimeTypeOf:_protocol.request.URL.pathExtension];
        }
        if (mimeType) {
            _headers[@"Content-Type"] = mimeType;
        }
    }
    if (!_headers[@"Content-Length"]) {
        _headers[@"Content-Length"] = [self _contentLength:data];
    }
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:_protocol.request.URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:_headers];
    [_protocol.client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:_cachePolicy];
    [_protocol.client URLProtocol:_protocol didLoadData:data];
    [_protocol.client URLProtocolDidFinishLoading:_protocol];
}
- (NSString*) _mimeTypeOf:(NSString*)pathExtension {
    static NSDictionary* mimeTypes = nil;
    if (mimeTypes == nil) {
        mimeTypes = @{
                    @"png": @"image/png",
                    @"jpg": @"image/jpg",
                    @"jpeg": @"image/jpg",
                    @"woff": @"font/woff",
                    @"ttf": @"font/opentype",
                    @"m4a": @"audio/mp4a-latm",
                    @"js": @"application/javascript; charset=utf-8",
                    @"html": @"text/html; charset=utf-8"
                    };
    }
    return mimeTypes[pathExtension];
}
// Pipe API
- (void)pipeResponse:(NSURLResponse *)response {
    [self pipeResponse:response cachingAllowed:NO];
}
- (void)pipeResponse:(NSURLResponse *)response cachingAllowed:(BOOL)cachingAllowed {
    if (_stopped) { return; }
    NSURLCacheStoragePolicy cachePolicy = cachingAllowed ? NSURLCacheStorageAllowed : NSURLCacheStorageNotAllowed;
    [_protocol.client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:cachePolicy];
}
- (void)pipeData:(NSData *)data {
    if (_stopped) { return; }
    [_protocol.client URLProtocol:_protocol didLoadData:data];
}
- (void)pipeEnd {
    if (_stopped) { return; }
    [_protocol.client URLProtocolDidFinishLoading:_protocol];
}
- (void)pipeError:(NSError *)error {
    if (_stopped) { return; }
    [_protocol.client URLProtocol:_protocol didFailWithError:error];
}
// NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self pipeResponse:response];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self pipeData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self pipeEnd];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self pipeError:error];
}

#ifdef WVP_OSX
// OSX version
- (void)_respondWithImage:(NSImage*)image mimeType:(NSString*)mimeType {
    NSData* data = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
    if ([mimeType isEqualToString:@"image/jpg"]) {
        data = [imageRep
                representationUsingType:NSJPEGFileType
                properties:@{ NSImageCompressionFactor:[NSNumber numberWithFloat:1.0] }];
    } else if ([mimeType isEqualToString:@"image/png"]) {
        data = [imageRep
                representationUsingType:NSPNGFileType
                properties:@{ NSImageInterlaced:[NSNumber numberWithBool:NO] }];
    }
    [self respondWithData:data mimeType:mimeType];
}
- (NSString*)_contentLength:(NSData*)data {
    return [NSString stringWithFormat:@"%ld", data.length];
}
#else
// iOS Version
- (void)_respondWithImage:(UIImage*)image mimeType:(NSString*)mimeType {
    NSData* data;
    if ([mimeType isEqualToString:@"image/jpg"]) {
        data = UIImageJPEGRepresentation(image, 1.0);
    } else if ([mimeType isEqualToString:@"image/png"]) {
        data = UIImagePNGRepresentation(image);
    }
    [self respondWithData:data mimeType:mimeType];
}
- (NSString*)_contentLength:(NSData*)data {
    return [NSString stringWithFormat:@"%lu", (unsigned long)data.length];
}
#endif

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
    NSString* userAgent = request.allHTTPHeaderFields[@"User-Agent"];
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
        self.proxyResponse = [[WVPResponse alloc] _initWithRequest:request protocol:self];
    }
    return self;
}
- (void)startLoading {
    self.requestMatcher.handler(_correctedRequest, self.proxyResponse);
}
- (void)stopLoading {
    _correctedRequest = nil;
    [self.proxyResponse _stopLoading];
    self.proxyResponse = nil;
}
@end


// This is the actual WebViewProxy API
@implementation WebViewProxy
+ (void)load {
#if ! __has_feature(objc_arc)
    [NSException raise:@"ARC_Required" format:@"WebViewProxy requires Automatic Reference Counting (ARC) to function properly. Bailing."];
#endif
}
+ (void)initialize {
    [WebViewProxy removeAllHandlers];
    webViewUserAgentTest = [NSPredicate predicateWithFormat:@"self MATCHES '^Mozilla.*Mac OS X.*'"];
    webViewProxyLoopDetection = [NSPredicate predicateWithFormat:@"self.fragment MATCHES '__webviewproxyreq__'"];
    // e.g. "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10A403"
    [NSURLProtocol registerClass:[WebViewProxyURLProtocol class]];
}
+ (void)removeAllHandlers {
    requestMatchers = [NSMutableArray array];
}
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
    // Match on any property of NSURL, e.g. "scheme MATCHES 'http' AND host MATCHES 'www.google.com'"
    [requestMatchers addObject:[WVPRequestMatcher matchWithPredicate:predicate handler:handler]];
}
+ (NSString *)_normalizePath:(NSString *)path {
    if (![path hasPrefix:@"/"]) {
        // Paths always being with "/", so help out people who forget it
        path = [@"/" stringByAppendingString:path];
    }
    return path;
}

@end
