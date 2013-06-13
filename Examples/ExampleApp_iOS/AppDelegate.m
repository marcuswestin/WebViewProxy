//
//  AppDelegate.m
//  ExampleApp_iOS
//
//  Created by Marcus Westin on 6/13/13.
//  Copyright (c) 2013 WebViewProxy. All rights reserved.
//

#import "AppDelegate.h"
#import "WebViewProxy.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self _setupProxy];
    [self _createWebView];
    
    return YES;
}

- (void) _createWebView {
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.window.bounds];
    [_window addSubview:webView];
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"WebViewContent" ofType:@"html"];
    NSString* html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:html baseURL:nil];
}

- (void) _setupProxy {
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    
    [WebViewProxy handleRequestsWithHost:@"www.google.com" path:@"/images/srpr/logo3w.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:req.URL] queue:queue completionHandler:^(NSURLResponse *netRes, NSData *data, NSError *netErr) {
            if (netErr || ((NSHTTPURLResponse*)netRes).statusCode >= 400) { return [res respondWithError:500 text:@":("]; }
            [res respondWithData:data mimeType:@"image/png"];
        }];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"intercept" path:@"/Galaxy.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Galaxy" ofType:@"png"];
        UIImage* image = [UIImage imageWithContentsOfFile:filePath];
        [res respondWithImage:image];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"example.proxy" handler:^(NSURLRequest *req, WVPResponse *res) {
        NSString* proxyUrl = [req.URL.absoluteString stringByReplacingOccurrencesOfString:@"example.proxy" withString:@"example.com"];
        NSURLRequest* proxyReq = [NSURLRequest requestWithURL:[NSURL URLWithString:proxyUrl]];
        [NSURLConnection connectionWithRequest:proxyReq delegate:res];
    }];
}

@end
