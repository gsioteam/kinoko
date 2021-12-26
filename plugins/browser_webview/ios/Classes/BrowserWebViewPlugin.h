#import <Flutter/Flutter.h>
#import "WebViewContainer.h"

@interface BrowserWebViewPlugin : NSObject<FlutterPlugin>

+ (WebViewContainer *)find:(id)idObj;

@end
