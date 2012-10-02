#include "WebViewProxy.h"

/* A single path matcher */
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

/* This is the actual WebViewProxy API */
static NSMutableArray* requestMatchers;
@implementation WebViewProxy
+ (void)setup {
    requestMatchers = [NSMutableArray array];
}
+ (void)handleRequestsWithScheme:(NSString *)scheme handler:(WebViewProxyHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"scheme MATCHES '%@'", scheme];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithHost:(NSString *)host handler:(WebViewProxyHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"host MATCHES '%@'", host];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsWithPathPrefix:(NSString *)pathPrefix handler:(WebViewProxyHandler)handler {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"path MATCHES '^%@.*'", pathPrefix];
    [self handleRequestsMatching:predicate handler:handler];
}
+ (void)handleRequestsMatching:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler {
    // Match on any property of NSURL, e.g. "scheme MATCHES 'http' AND host MATCHES 'www.google.com'"
    [requestMatchers addObject:[WebViewProxyRequestMatcher matchWithPredicate:predicate handler:handler]];
}
@end

/* This is the proxy response object, through which we send responses */
@implementation WebViewProxyResponse
// Convenience API
- (void)respondWithData:(NSData *)data encoding:(NSStringEncoding)encoding {

}
- (void)respondWithImage:(UIImage *)image {
    
}
- (void)respondWithJSON:(NSDictionary *)jsonObject {
    
}
- (void)respondWithString:(NSString *)string {
    
}
// Core API
- (void)setHeader:(NSString *)headerName value:(NSString *)headerValue {
    
}
- (void)sendData:(NSData *)data {
    
}
- (void)end {
    
}
@end


/* The NSURLProtocol implementation that allows us to intercept requests. */
@interface WebViewProxyURLProtocol : NSURLProtocol
@property (strong,nonatomic) NSURLConnection* connection;
@property (strong,nonatomic) NSURLRequest* request;
@end

/* The actual implementation of our NSURLProtocol subclass */
@implementation WebViewProxyURLProtocol

@synthesize connection, request;

@end