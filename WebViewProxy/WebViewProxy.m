#include "WebViewProxy.h"

/* A single path matcher */
@interface WebViewProxyRequestMatcher : NSObject
@property (strong,nonatomic) NSPredicate* schemePredicate;
@property (strong,nonatomic) NSPredicate* hostPredicate;
@property (strong,nonatomic) NSPredicate* pathPredicate;
@property (strong,nonatomic) NSPredicate* fullPredicate;
@property (copy) WebViewProxyHandler handler;
- (WebViewProxyRequestMatcher*)init:(WebViewProxyHandler)handler scheme:(NSString*)scheme host:(NSString*)host paths:(NSString*)paths;
@end
@implementation WebViewProxyRequestMatcher
@synthesize schemePredicate, hostPredicate, pathPredicate, handler=_handler;
- (WebViewProxyRequestMatcher*)init:(WebViewProxyHandler)handler scheme:(NSString *)scheme host:(NSString *)host paths:(NSString *)paths {
    if (self = [super init]) {
        self.handler = handler;
        self.schemePredicate = [NSPredicate predicateWithFormat:@""];
    }
    return self;
}
@end

/* This is the actual WebViewProxy API */
static NSMutableArray* handlers;
@implementation WebViewProxy
+ (void)setup {
    handlers = [NSMutableArray array];
}
+ (void)handleScheme:(NSString *)scheme handler:(WebViewProxyHandler)handler {
    
}
+ (void)handleHost:(NSString *)host handler:(WebViewProxyHandler)handler {
    
}
+ (void)handlePaths:(NSString *)pathPrefix handler:(WebViewProxyHandler)handler {
    
}
+ (void)handleRegex:(NSString*)regex handler:(WebViewProxyHandler)handler {
    
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