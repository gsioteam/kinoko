#import "BrowserWebViewPlugin.h"
#import "WebViewContainer.h"

NSMutableDictionary<NSNumber *, WebViewContainer *> *_containers;

@interface BrowserWebViewFactory : NSObject <FlutterPlatformViewFactory>

@end

@interface BrowserWebViewPlugin() <WebViewContainerDelegate>

@property (nonatomic, strong) FlutterMethodChannel *channel;

@end

id valueOr(id obj, id other) {
    return obj ? obj : other;
}

@implementation BrowserWebViewPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"browser_webview"
              binaryMessenger:[registrar messenger]];
    BrowserWebViewPlugin* instance = [[BrowserWebViewPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    
    BrowserWebViewFactory* factory = [[BrowserWebViewFactory alloc] init];
    [registrar registerViewFactory:factory
                            withId:@"browser_web_view"];
}

- (id)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        self.channel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        WebViewContainer *container = [[WebViewContainer alloc] initWithParams:call.arguments
                                                                   withChannel:self.channel];
        container.delegate = self;
        if (!_containers) {
            _containers = [NSMutableDictionary dictionary];
        }
        id _id = call.arguments[@"id"];
        if (_id) {
            [_containers setObject:container
                            forKey:_id];
            result(@YES);
        } else {
            result(@NO);
        }
    } else if ([@"dispose" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            [_containers removeObjectForKey:_id];
        }
        result(nil);
    } else if ([@"loadUrl" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        NSString *url = call.arguments[@"url"];
        if (_id && [url isKindOfClass:NSString.class]) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        }
        result(nil);
    } else if ([@"takeCapture" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        NSNumber *width = call.arguments[@"width"];
        if (_id && [width isKindOfClass:NSNumber.class]) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container takeCaptureWithSize:[width floatValue]
                                 withBlock:^(NSString * _Nullable path, NSError * _Nullable error) {
                if (error) {
                    result(@{
                        @"error": [error description]
                           });
                } else {
                    result(@{
                        @"path": path
                           });
                }
            }];
        } else {
            result(@{
                @"error": @"no id"
                   });
        }
    } else if ([@"getHistoryList" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            NSMutableArray *arr = [NSMutableArray array];
            WKBackForwardList *historyList = container.webView.backForwardList;
            for (WKBackForwardListItem *item in historyList.backList) {
                [arr addObject:@{
                    @"url": item.URL.absoluteString,
                    @"title": valueOr(item.title, @""),
                }];
            }
            WKBackForwardListItem *item = historyList.currentItem;
            if (item) {
                [arr addObject:@{
                    @"url": item.URL.absoluteString,
                    @"title": valueOr(item.title, @""),
                    @"current": @YES,
                }];
            }
            for (WKBackForwardListItem *item in historyList.forwardList) {
                [arr addObject:@{
                    @"url": item.URL.absoluteString,
                    @"title": valueOr(item.title, @""),
                }];
            }
            result(@{
                @"list": arr
                   });
        } else {
            result(@{
                @"error": @"no id"
                   });
        }
    } else if ([@"reload" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container.webView reload];
        }
        result(nil);
    } else if ([@"goBack" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container.webView goBack];
        }
        result(nil);
    } else if ([@"goForward" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container.webView goForward];
        }
        result(nil);
    } else if ([@"eval" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            if (container) {
                [container.webView evaluateJavaScript:call.arguments[@"script"]
                                    completionHandler:^(id _Nullable object, NSError * _Nullable error) {
                    result(object);
                }];
            } else {
                result(nil);
            }
        } else {
            result(nil);
        }
    } else if ([@"stop" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            [container.webView stopLoading];
        }
        result(nil);
    } else if ([@"clear" isEqualToString:call.method]) {
        WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
        NSString *type = call.arguments[@"type"];
        NSMutableSet *types = [NSMutableSet set];
        if ([@"cookies" isEqualToString:type]) {
            [types addObject:WKWebsiteDataTypeCookies];
        } else if ([@"cache" isEqualToString:type]) {
            [types addObject:WKWebsiteDataTypeDiskCache];
            if (@available(iOS 11.3, *)) {
                [types addObject:WKWebsiteDataTypeFetchCache];
            }
            [types addObject:WKWebsiteDataTypeMemoryCache];
        } else if ([@"session" isEqualToString:type]) {
            [types addObject:WKWebsiteDataTypeSessionStorage];
            [types addObject:WKWebsiteDataTypeLocalStorage];
            [types addObject:WKWebsiteDataTypeWebSQLDatabases];
            [types addObject:WKWebsiteDataTypeIndexedDBDatabases];
        } else {
            result(@NO);
            return;
        }
        [dataStore fetchDataRecordsOfTypes:types
                         completionHandler:^(NSArray<WKWebsiteDataRecord *> * _Nonnull records) {
            [dataStore removeDataOfTypes:types
                          forDataRecords:records
                       completionHandler:^{
                result(@YES);
            }];
        }];
    } else if ([@"setDownloadDetector" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            container.downloadExtensions = [call.arguments[@"extensions"] copy];
            container.downloadMimeTypes = [call.arguments[@"mime_types"] copy];
        }
        result(nil);
    } else if ([@"setEnablePullDown" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            container.enablePullDown = [call.arguments[@"value"] boolValue];
        }
        result(nil);
    } else if ([@"setScrollEnabled" isEqualToString:call.method]) {
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            container.webView.scrollView.scrollEnabled = [call.arguments[@"value"] boolValue];
        }
        result(nil);
    } else if ([@"getCookies" isEqualToString:call.method]) {
        NSURL *url = [NSURL URLWithString:call.arguments[@"url"]];
        NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:url];
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:cookies.count];
        for (NSHTTPCookie *cookie in cookies) {
            [arr addObject:@{
                @"name": cookie.name,
                @"value": cookie.value,
            }];
        }
        result(@{
            @"cookies": arr
               });
    } else if ([call.method isEqualToString:@"postMessage"]) {
        NSString *method = call.arguments[@"method"];
        id data = call.arguments[@"data"];
        id _id = call.arguments[@"id"];
        if (_id) {
            WebViewContainer *container = [_containers objectForKey:_id];
            NSString *dataStr = @"null";
            if (data) {
                NSData *res = [NSJSONSerialization dataWithJSONObject:data
                                                options:NSJSONWritingFragmentsAllowed
                                                  error:nil];
                if (res) {
                    dataStr = [[NSString alloc] initWithData:res encoding:NSUTF8StringEncoding];
                }
            }
            NSString *script = [NSString stringWithFormat:@"window.messenger._event('%@', %@)", method, dataStr];
            [container.webView evaluateJavaScript:script completionHandler:^(id _Nullable ret, NSError * _Nullable error) {
                result(nil);
            }];
        } else {
            result(nil);
        }
    } else {
      result(FlutterMethodNotImplemented);
    }
}

- (void)webViewContrainer:(WebViewContainer *)container createSubWindow:(WebViewContainer *)subContainer {
    if (subContainer.webId > 0) {
        [_containers setObject:subContainer
                        forKey:@(subContainer.webId)];
    }
}

+ (WebViewContainer *)find:(id)idObj {
    return _containers[idObj];
}

@end

@interface BrowserWebView : NSObject <FlutterPlatformView>

- (id)initWithFrame:(CGRect)frame withArguments:(id _Nullable)args;

@end

@implementation BrowserWebViewFactory


- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                  viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    return [[BrowserWebView alloc] initWithFrame:frame
                                   withArguments:args];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return FlutterStandardMessageCodec.sharedInstance;
}

@end

@implementation BrowserWebView {
    WebViewContainer *_container;
    UIView *_view;
}

- (id)initWithFrame:(CGRect)frame withArguments:(id)args {
    self = [super init];
    if (self) {
        id _id = args[@"id"];
        if (_id) {
            _container = _containers[_id];
        }
        _view = [[UIView alloc] initWithFrame:frame];
        if (_container) {
            _container.contentView.frame = _view.bounds;
            _container.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_view addSubview:_container.contentView];
            [_container onResume];
        }
    }
    return self;
}

- (void)dealloc {
    [_container onPause];
}

- (UIView*)view {
    return _view;
}

@end
