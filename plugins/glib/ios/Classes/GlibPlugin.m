#import "GlibPlugin.h"
#import "dart_main_ios.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#define DART_EXPORT __attribute__((visibility("default"))) __attribute__((used))

FlutterMethodChannel *glibChannel = nil;
#define CHANNEL @"com.ero.kinoko/volume_button"

@interface GlibPlugin()

@property (nonatomic, readonly) MPVolumeView *volumeView;
@property (nonatomic, strong) FlutterMethodChannel *channel;

@end

@implementation GlibPlugin {
    BOOL _handleVolumeButton;
    MPVolumeView    *_volumeView;
    UISlider    *_volumeSlider;
    CGFloat     _currentValue;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"glib"
            binaryMessenger:[registrar messenger]];
  GlibPlugin* instance = [[GlibPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    glibChannel = channel;
    
    channel = [FlutterMethodChannel methodChannelWithName:CHANNEL
                                          binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.channel = channel;
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"start"]) {
        _handleVolumeButton = YES;
        MPVolumeView *volumeView = [self volumeView];
        _currentValue = _volumeSlider.value;
        if (_currentValue > 0.8) {
            _volumeSlider.value = _currentValue = 0.8;
        } else if (_currentValue < 0.2) {
            _volumeSlider.value = _currentValue = 0.2;
        }
        AVAudioSession *session = AVAudioSession.sharedInstance;
        [session setActive:YES error:nil];
        [session addObserver:self
                  forKeyPath:@"outputVolume"
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     context:nil];
    } else if ([call.method isEqualToString:@"stop"]) {
        _handleVolumeButton = NO;
    }
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    glibChannel = nil;
}

+ (void)setDebugPath:(NSString *)path {
    setDebugPath(path.UTF8String);
}

- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 120, 130)];
//        _volumeView.alpha = 0;
        for (UIView *subview in _volumeView.subviews) {
            if ([subview isKindOfClass:UISlider.class]) {
                _volumeSlider = (UISlider*)subview;
                break;
            }
        }
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
//        [window addSubview:_volumeView];
        [window insertSubview:_volumeView atIndex:0];
    }
    return _volumeView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"outputVolume"]) {
        if (_handleVolumeButton) {
            CGFloat value = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
            int code = 0;
            if (fabs(value - _currentValue) > 0.01) {
                if (value > _currentValue) {
                    code = 2;
                } else if (value < _currentValue) {
                    code = 1;
                }
            }
            if (code) {
                [self resetValue];
            }
            [self.channel invokeMethod:@"keyDown" arguments:@(code)];
        }
    }
}

- (void)resetValue {
    _volumeSlider.value = _currentValue;
}

@end

void onGlibSignal() {
    [glibChannel invokeMethod:@"sendSignal" arguments:nil];
}

DART_EXPORT
void dart_setupLibrary(CallClass call_class, CallInstance call_instance, CreateFromNative from_native) {
    setupLibrary(call_class, call_instance, from_native, onGlibSignal);
}

DART_EXPORT
void dart_destroyLibrary() {
    destroyLibrary();
}

DART_EXPORT
void dart_postSetup(const char *path) {
    postSetup(path);
}

DART_EXPORT
void dart_setCacertPath(const char *path) {
    setCacertPath(path);
}

DART_EXPORT
void dart_runOnMainThread() {
    runOnMainThread();
}
