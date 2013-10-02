#import <Foundation/Foundation.h>

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    #import <Cocoa/Cocoa.h>
    #define WVPImageType NSImage
    #define WVP_OSX
#else
    #define WVPImageType UIImage
#endif

typedef void (^StopLoadingHandler)();
@interface WVPResponse : NSObject <NSURLConnectionDataDelegate>
@property (assign,nonatomic) NSURLCacheStoragePolicy cachePolicy;
@property (strong,nonatomic) NSURLRequest* request;
// High level API
- (void) respondWithImage:(WVPImageType*)image;
- (void) respondWithImage:(WVPImageType*)image mimeType:(NSString*)mimeType;
- (void) respondWithText:(NSString*)text;
- (void) respondWithHTML:(NSString*)html;
- (void) respondWithJSON:(NSDictionary*)jsonObject;
- (void) handleStopLoadingRequest:(StopLoadingHandler)stopLoadingHandler;
// Low level API
- (void) respondWithError:(NSInteger)statusCode text:(NSString*)text;
- (void) setHeader:(NSString*)headerName value:(NSString*)headerValue;
- (void) setHeaders:(NSDictionary*)headers;
- (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType;
- (void) respondWithData:(NSData*)data mimeType:(NSString*)mimeType statusCode:(NSInteger)statusCode;
// Pipe data API
- (void) pipeResponse:(NSURLResponse*)response;
- (void) pipeData:(NSData*)data;
- (void) pipeEnd;
// Private methods
- (id) _initWithRequest:(NSURLRequest*)request protocol:(NSURLProtocol*)protocol;
- (void) _stopLoading;
@end

// The actual WebViewProxy API itself
typedef void (^WVPHandler)(NSURLRequest* req, WVPResponse* res);
@interface WebViewProxy : NSObject
+ (void) handleRequestsWithScheme:(NSString*)scheme handler:(WVPHandler)handler;
+ (void) handleRequestsWithHost:(NSString*)host handler:(WVPHandler)handler;
+ (void) handleRequestsWithHost:(NSString*)host path:(NSString*)path handler:(WVPHandler)handler;
+ (void) handleRequestsWithHost:(NSString*)host pathPrefix:(NSString*)pathPrefix handler:(WVPHandler)handler;
+ (void) handleRequestsMatching:(NSPredicate*)predicate handler:(WVPHandler)handler;
@end