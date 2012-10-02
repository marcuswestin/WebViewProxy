#import <Foundation/Foundation.h>

@interface WebViewProxyResponse : NSObject {
    @private NSURLProtocol* _protocol;
    @private id<NSURLProtocolClient> _client;
    @private NSURLResponse* _response;
    @private NSMutableDictionary* _headers;
}
@property (strong,nonatomic,readonly) NSURLRequest* request;
// Convenience API
- (void) respondWithImage:(UIImage*)image;
- (void) respondWithImage:(UIImage*)image cachingAllowed:(BOOL)cachingAllowed;
- (void) respondWithText:(NSString*)text;
- (void) respondWithHTML:(NSString*)html;
- (void) respondWithJSON:(NSDictionary*)jsonObject;
// Core API
- (void) respondWithError:(NSInteger)statusCode text:(NSString*)text;
- (void) setHeader:(NSString*)headerName value:(NSString*)headerValue;
- (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType;
- (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType cachingAllowed:(BOOL)cachingAllowed;
- (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType cachingAllowed:(BOOL)cachingAllowed statusCode:(NSInteger)statusCode;
// Pipe data API
- (void) pipeResponse:(NSURLResponse*)response cachingAllowed:(BOOL)cachingAllowed;
- (void) pipeResponse:(NSURLResponse*)response;
- (void) pipeData:(NSData*)data;
- (void) pipeEnd;
// Private methods
- (id) _initWithProtocol:(NSURLProtocol*)protocol request:(NSURLRequest*)request client:(id<NSURLProtocolClient>)client;
@end

/* Our block definitions */
typedef void (^WebViewProxyHandler)(WebViewProxyResponse* response);

/* The actual WebViewProxy API itself */
@interface WebViewProxy : NSObject
+ (void) handleRequestsWithScheme:(NSString*)scheme handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsWithHost:(NSString*)host handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsWithPathPrefix:(NSString*)pathPrefix handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsMatching:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler;
@end