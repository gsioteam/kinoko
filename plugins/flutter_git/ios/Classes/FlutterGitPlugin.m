#import "FlutterGitPlugin.h"
#import "flutter_git.h"

@protocol MainThread <NSObject>

+ (void)sendEvent:(NSString *)event withData:(NSString *)data;

@end

@implementation FlutterGitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_git"
            binaryMessenger:[registrar messenger]];
  FlutterGitPlugin* instance = [[FlutterGitPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    // Just make sure the library is linked.
    NSLog(@"%lu", (unsigned long)&flutter_init);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(FlutterMethodNotImplemented);
}

@end
