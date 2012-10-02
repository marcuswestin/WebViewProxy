#import <Foundation/Foundation.h>

@interface WebViewProxyResponse : NSObject
@property (strong,nonatomic) NSURLResponse* response;
// Convenience API
- (void) respondWithData:(NSData*)data encoding:(NSStringEncoding)encoding;
- (void) respondWithImage:(UIImage*)image;
- (void) respondWithString:(NSString*)string;
- (void) respondWithJSON:(NSDictionary*)jsonObject;
// Core API
- (void) setHeader:(NSString*)headerName value:(NSString*)headerValue;
- (void) sendData:(NSData*)data;
- (void) end;
@end

/* Our block definitions */
typedef void (^WebViewProxyHandler)(NSURLRequest* request, WebViewProxyResponse* response);

/* The actual WebViewProxy API itself */
@interface WebViewProxy : NSObject
+ (void) setup;
+ (void) handleRequestsWithScheme:(NSString*)scheme handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsWithHost:(NSString*)host handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsWithPathPrefix:(NSString*)pathPrefix handler:(WebViewProxyHandler)handler;
+ (void) handleRequestsMatching:(NSPredicate*)predicate handler:(WebViewProxyHandler)handler;
@end