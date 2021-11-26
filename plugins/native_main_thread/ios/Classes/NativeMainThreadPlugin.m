#import "NativeMainThreadPlugin.h"

static __weak NativeMainThreadPlugin *NativeMainThread_current = NULL;

@interface NativeMainThreadPlugin ()

@property (nonatomic, strong) FlutterMethodChannel *channel;

@end

@implementation NativeMainThreadPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"native_main_thread"
              binaryMessenger:[registrar messenger]];
    NativeMainThreadPlugin* instance = [[NativeMainThreadPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(FlutterMethodNotImplemented);
}

- (id)init {
    self = [super init];
    if (self) {
        @synchronized (NativeMainThreadPlugin.class) {
            NativeMainThread_current = self;
        }
    }
    return self;
}

+ (void)sendEvent:(const char *)event withData:(const char *)data {
    @synchronized (NativeMainThreadPlugin.class) {
        if (NativeMainThread_current) {
            NSString *nameStr = [NSString stringWithUTF8String:event];
            NSString *dataStr = [NSString stringWithUTF8String:data];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [NativeMainThread_current.channel invokeMethod:@"event"
                                                     arguments:@{
                    @"name": nameStr,
                    @"data": dataStr,
                }];
            });
        }
    }
}

@end
