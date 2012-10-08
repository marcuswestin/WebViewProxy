#import "AppDelegate.h"
#import "WebViewProxy.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [WebViewProxy handleRequestsWithScheme:@"my_custom_scheme" handler:^(WVPResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" handler:^(WVPResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"foo.com" pathPrefix:@"/bar" handler:^(WVPResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"absoluteString MATCHES[cd] '^http:'"] handler:^(WVPResponse *response) {
        [response respondWithText:@"Hi!"];
    }];

    [WebViewProxy handleRequestsMatching:[NSPredicate predicateWithFormat:@"host MATCHES[cd] '[foo|bar]'"]  handler:^(WVPResponse *response) {
        [response respondWithText:@"Hi!"];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"google_logo" handler:^(WVPResponse *response) {
        UIImage* image = [UIImage imageNamed:@"GoogleLogo.png"];
        [response respondWithImage:image];
    }];

    [WebViewProxy handleRequestsWithHost:@"google_logo_bw" handler:^(WVPResponse *response) {
        UIImage* originalImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://www.google.com/logos/2012/bohr11-hp.jpg"]]];
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
    self.window.rootViewController = [[UIViewController alloc] init]; // "Application windows are expected to have a root view controller at the end of application launch"... why? So silly.
    [self.window makeKeyAndVisible];
    return YES;
}

@end
