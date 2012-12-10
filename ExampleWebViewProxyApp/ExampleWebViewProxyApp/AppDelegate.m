#import "AppDelegate.h"
#import "WebViewProxy.h"

@implementation AppDelegate

static NSOperationQueue* queue;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [WebViewProxy handleRequestsWithHost:@"www.google.com" path:@"/images/srpr/logo3w.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:req.URL] queue:queue completionHandler:^(NSURLResponse *netRes, NSData *data, NSError *netErr) {
            if (netErr || ((NSHTTPURLResponse*)netRes).statusCode >= 400) { return [res respondWithError:500 text:@":("]; }
            [res respondWithData:data mimeType:@"image/png"];
        }];
    }];

    [WebViewProxy handleRequestsWithHost:@"black_and_white.google.com" path:@"/images/srpr/logo3w.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSURL* url = [NSURL URLWithString:[req.URL.absoluteString stringByReplacingOccurrencesOfString:@"black_and_white" withString:@"www"]];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:queue completionHandler:^(NSURLResponse *netRes, NSData *netData, NSError *netErr) {
            if (netErr || ((NSHTTPURLResponse*)netRes).statusCode >= 400) { return [res respondWithError:500 text:@":("]; }
            UIImage* originalImage = [UIImage imageWithData:netData];
            [res respondWithImage:[self blackAndWhite:originalImage]];
        }];
    }];

    [WebViewProxy handleRequestsWithHost:@"intercept" path:@"/Galaxy.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Galaxy" ofType:@"png"];
        UIImage* image = [UIImage imageWithContentsOfFile:filePath];
        [res respondWithImage:image];
    }];

    [WebViewProxy handleRequestsWithHost:@"intercept_black_and_white" path:@"/Galaxy.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Galaxy.png" ofType:nil];
        UIImage* originalImage = [UIImage imageWithContentsOfFile:filePath];
        [res respondWithImage:[self blackAndWhite:originalImage]];
    }];

    UIWebView* webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    NSString* webViewContentPath = [[NSBundle mainBundle] pathForResource:@"WebViewContent" ofType:@"html"];
    NSString* htmlContent = [NSString stringWithContentsOfFile:webViewContentPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:htmlContent baseURL:nil];
    [self.window addSubview:webView];
    
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UIViewController alloc] init]; // "Application windows are expected to have a root view controller at the end of application launch"... why? So silly.
    [self.window makeKeyAndVisible];
    
    // More examples that won't do anything in this app
    [WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" path:@"/bar" handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];
    
    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];
    
    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"] handler:^(NSURLRequest* req, WVPResponse *res) {
        // ...
    }];

    return YES;
}

- (UIImage *)blackAndWhite:(UIImage *)originalImage {
    CGColorSpaceRef colorSapce = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, originalImage.size.width, originalImage.size.height, 8, originalImage.size.width, colorSapce, kCGImageAlphaNone);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, originalImage.size.width, originalImage.size.height), [originalImage CGImage]);
    
    CGImageRef bwImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSapce);
    
    UIImage *resultImage = [UIImage imageWithCGImage:bwImage]; // This is result B/W image.
    CGImageRelease(bwImage);
    return resultImage;
}

@end
