#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "GlibPlugin.h"
#import "Firebase/Firebase.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FIRApp configure];
//    [GlibPlugin setDebugPath:[NSBundle.mainBundle pathForResource:@"debug" ofType:@""]];
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

@end
