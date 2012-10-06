#import "AppDelegate.h"
#import "WebViewProxy.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(WebViewProxyResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" handler:^(WebViewProxyResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(WebViewProxyResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(WebViewProxyResponse *response) {
        [response respondWithText:@"Hi!"];
    }];

    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"]  handler:^(WebViewProxyResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    
    
    [WebViewProxy handleRequestsWithHost:@"google_logo" handler:^(WebViewProxyResponse *response) {
        UIImage* image = [UIImage imageNamed:@"GoogleLogo.png"];
        [response respondWithImage:image];
    }];

    [WebViewProxy handleRequestsWithHost:@"google_logo_bw" handler:^(WebViewProxyResponse *response) {
        UIImage* originalImage = [UIImage imageNamed:@"GoogleLogo.png"];
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
        
        [response respondWithImage:resultImage];
    }];

    UIWebView* webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    NSString* webViewContentPath = [[NSBundle mainBundle] pathForResource:@"WebViewContent" ofType:@"html"];
    NSString* htmlContent = [NSString stringWithContentsOfFile:webViewContentPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:htmlContent baseURL:nil];
    [self.window addSubview:webView];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
