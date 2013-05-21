#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) UIWindow *window;

- (UIImage*) blackAndWhite:(UIImage*)image;

@end
