//
//  WebVIewContainer.m
//  browser_webview
//
//  Created by gen on 9/1/21.
//

#import "WebViewContainer.h"
#import "DragIndicator.h"
#import "GrabGestureRecognizer.h"

NSString *WebViewResumeNotification = @"WebViewResumeNotification";
NSString *WebViewPauseNotification = @"WebViewPauseNotification";


@interface BWContainerView : UIView

@end

@implementation BWContainerView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

@end

@interface WebMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, copy) void(^block)(WKScriptMessage *message);

+ (id)handlerWithBlock:(void(^)(WKScriptMessage *))block;

@end

@implementation WebMessageHandler

+ (id)handlerWithBlock:(void (^)(WKScriptMessage *))block {
    WebMessageHandler *handler = [[self alloc] init];
    handler.block = block;
    return handler;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.block) self.block(message);
}

@end

@interface WebViewContainer() <WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>

@end

@implementation WebViewContainer {
    NSMutableArray<NSURLRequest *> *_cachedRequests;
    id _args;
    
    UIView  *_dragDownView;
    DragIndicator *_indicator;
    
    id _impactFeedback;
    
    
}

- (id)initWithConfiguration:(WKWebViewConfiguration *)configuration withChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
        CGSize size = UIScreen.mainScreen.bounds.size;
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                      configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        _webView.scrollView.delegate = self;
        _webView.opaque = NO;
        _webView.backgroundColor = UIColor.clearColor;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_webView addObserver:self
                   forKeyPath:@"URL"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        [_webView addObserver:self
                   forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        [_webView addObserver:self
                   forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        
        self.downloadExtensions = @[
           @"zip",
           @"dmg",
           @"apk",
           @"ipa",
       ];
        _cachedRequests = [NSMutableArray array];
        
        if (@available(iOS 10.0, *)) {
            _impactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        }
        
#define DRAG_BG_SIZE 400
        _dragDownView = [[UIView alloc] initWithFrame:CGRectMake(0, -DRAG_BG_SIZE, _webView.bounds.size.width, DRAG_BG_SIZE)];
        _dragDownView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _indicator = [[DragIndicator alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        _indicator.center = CGPointMake(_webView.bounds.size.width / 2, DRAG_BG_SIZE - 20);
        _indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_dragDownView addSubview:_indicator];
        [_webView.scrollView addSubview:_dragDownView];
        
        _contentView = [[BWContainerView alloc] initWithFrame:_webView.frame];
        
        _backgroundView = [[UIView alloc] initWithFrame:_contentView.bounds];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_contentView addSubview:_backgroundView];
        
        [_contentView addSubview:_webView];
        
        GrabGestureRecognizer *grap = [[GrabGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(onPinch:)];
        [_contentView addGestureRecognizer:grap];
    }
    return self;
}

- (id)initWithParams:(id)params withChannel:(FlutterMethodChannel *)channel {
    return [self initWithParams:params withConfiguration:nil withChannel:channel];
}

- (id)initWithParams:(id)params withConfiguration:(nullable WKWebViewConfiguration *)configuration withChannel:(nonnull FlutterMethodChannel *)channel {
    if (!configuration) {
        configuration = [WKWebViewConfiguration new];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.allowsAirPlayForMediaPlayback = YES;
        configuration.allowsPictureInPictureMediaPlayback = YES;
        if (@available(iOS 10.0, *)) {
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
        configuration.requiresUserActionForMediaPlayback = NO;
        
        NSArray *scripts = params[@"scripts"];
        for (id item in scripts) {
            NSMutableString *script = [NSMutableString stringWithString:item[@"script"]];
            NSInteger position = [item[@"position"] integerValue];
            NSDictionary *arguments = item[@"arguments"];
            [arguments enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([@"POST_MESSAGE" isEqual:obj]) {
                    obj = @"window.webkit.messageHandlers.messenger.postMessage({event: arguments[0], data: arguments[1]})";
                }
                [script replaceOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                        withString:[NSString stringWithFormat:@"%@", obj]
                                           options:0
                                             range:NSMakeRange(0, script.length)];
            }];
            [configuration.userContentController addUserScript:
             [[WKUserScript alloc] initWithSource:script
                                    injectionTime:position == 0 ? WKUserScriptInjectionTimeAtDocumentStart : WKUserScriptInjectionTimeAtDocumentEnd
                                 forMainFrameOnly:false]];
            
        }
        __weak WebViewContainer *that = self;
        [configuration.userContentController addScriptMessageHandler:[WebMessageHandler handlerWithBlock:^(WKScriptMessage *message) {
            [that onEvent:message];
        }]
                                                                         name:@"messenger"];
    }
    self = [self initWithConfiguration:configuration withChannel:channel];
    if (self) {
        _args = params;
        _webId = [params[@"id"] integerValue];
        
        NSString *url = params[@"url"];
        if ([url isKindOfClass:NSString.class]) {
            [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        }
        _webView.allowsBackForwardNavigationGestures = [params[@"allowsBackForwardGestures"] boolValue];
        
    }
    return self;
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"URL"];
    [_webView removeObserver:self forKeyPath:@"title"];
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)setWebId:(NSInteger)webId {
    _webId = webId;
}

- (void)takeCaptureWithSize:(CGFloat)size withBlock:(nonnull void (^)(NSString * _Nullable, NSError *))block {
    if (@available(iOS 11.0, *)) {
        WKSnapshotConfiguration *config = [[WKSnapshotConfiguration alloc] init];
        config.snapshotWidth = @(size);
        [_webView takeSnapshotWithConfiguration:config
                              completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
            if (!error) {
                NSData *data = UIImageJPEGRepresentation(snapshotImage, 0.8);
                NSString *dirPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
                NSString *filePath = [dirPath stringByAppendingPathComponent:
                                      [NSString stringWithFormat:@"capture_%ld_%f.jpg",
                                       random(), NSDate.new.timeIntervalSince1970]];
                [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
                block(filePath, error);
            } else {
                block(nil, error);
            }
        }];
    } else {
        UIGraphicsBeginImageContextWithOptions(_webView.bounds.size, YES, 0);
        [_webView drawViewHierarchyInRect:_webView.bounds afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (image) {
            NSError *error;
            NSData *data = UIImageJPEGRepresentation(image, 0.8);
            NSString *dirPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
            NSString *filePath = [dirPath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"capture_%ld_%f.jpg",
                                   random(), NSDate.new.timeIntervalSince1970]];
            [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
            block(filePath, error);
        } else {
            block(nil, [NSError errorWithDomain:@"CaptureFailed"
                                           code:800
                                       userInfo:nil]);
        }
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self.channel invokeMethod:@"loadStart"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": _webView.URL.absoluteString == nil ? @"" : _webView.URL.absoluteString,
                     }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.channel invokeMethod:@"loadEnd"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": _webView.URL.absoluteString == nil ? @"" : _webView.URL.absoluteString,
                     }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self.channel invokeMethod:@"loadError"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": _webView.URL.absoluteString == nil ? @"" : _webView.URL.absoluteString,
                         @"error": error.description
                     }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == _webView && [keyPath isEqualToString:@"URL"]) {
        NSURL *url = change[NSKeyValueChangeNewKey];
        if ([url isKindOfClass:NSURL.class]) {
            [self.channel invokeMethod:@"urlChanged"
                             arguments:@{
                                 @"id": @(self.webId),
                                 @"url": url.absoluteString,
                             }];
        }
    } else if (object == _webView && [keyPath isEqualToString:@"title"]) {
        NSString *title = change[NSKeyValueChangeNewKey];
        if ([title isKindOfClass:NSString.class]) {
            [self.channel invokeMethod:@"titleChanged"
                             arguments:@{
                                 @"id": @(self.webId),
                                 @"title": title
                             }];
        }
    } else if (object == _webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        NSNumber *progress = change[NSKeyValueChangeNewKey];
        if ([progress isKindOfClass:NSNumber.class]) {
            [self.channel invokeMethod:@"onProgress"
                             arguments:@{
                                 @"id": @(self.webId),
                                 @"progress": progress
                             }];
        }
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self.channel invokeMethod:@"onAlert"
                     arguments:@{
                         @"id": @(self.webId),
                         @"message": message
                     } result:^(id  _Nullable result) {
        completionHandler();
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    [self.channel invokeMethod:@"onConfirm"
                     arguments:@{
                         @"id": @(self.webId),
                         @"message": message
                     } result:^(id  _Nullable result) {
        completionHandler([result boolValue]);
    }];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSString *url = navigationAction.request.URL.absoluteString;
    if (!url) url = @"http://null";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_args];
    [params removeObjectForKey:@"id"];
    [params setObject:url forKey:@"url"];
    WebViewContainer *container = [[WebViewContainer alloc] initWithParams:params withConfiguration:configuration
                                                               withChannel:self.channel];
    [container.webView loadRequest:navigationAction.request];
    container.webView.allowsBackForwardNavigationGestures = self.webView.allowsBackForwardNavigationGestures;
    [self.channel invokeMethod:@"onCreateWindow"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": url,
                     } result:^(id  _Nullable result) {
        if ([result isKindOfClass:NSDictionary.class] && result[@"id"]) {
            NSInteger webId = [result[@"id"]  integerValue];
            [container setWebId:webId];
            if ([self.delegate respondsToSelector:@selector(webViewContrainer:createSubWindow:)]) {
                [self.delegate webViewContrainer:self
                                 createSubWindow:container];
            }
        } else {
            [container.webView stopLoading];
            [container.webView evaluateJavaScript:@"close()"
                                completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            }];
        }
    }];
    return container.webView;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *extension = [navigationAction.request.URL pathExtension].lowercaseString;
    NSString *scheme = navigationAction.request.URL.scheme;
    
    if ([extension isEqualToString:@"mobileconfig"] ||
        ![@[@"http", @"https", @"ftp", @"about"] containsObject:scheme]) {
        [_channel invokeMethod:@"onOpenInBrowser"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": navigationAction.request.URL.absoluteString,
                     } result:^(id  _Nullable result) {
            BOOL willOpen = [result isKindOfClass:NSNumber.class] ? [result boolValue] : NO;
            decisionHandler(willOpen ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
        }];
        return;
    }
    if ([self testString:extension withList:self.downloadExtensions]) {
        [_channel invokeMethod:@"onDownload"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": navigationAction.request.URL.absoluteString,
                         @"method": navigationAction.request.HTTPMethod,
                         @"headers": navigationAction.request.allHTTPHeaderFields,
                     }
                        result:^(id  _Nullable result) {
            BOOL willDownload = [result isKindOfClass:NSNumber.class] ? [result boolValue] : NO;
            decisionHandler(willDownload ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
        }];
        return;
    }
    
    while (_cachedRequests.count > 10) {
        [_cachedRequests removeObjectAtIndex:0];
    }
    [_cachedRequests addObject:navigationAction.request];
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (NSURLRequest *)findRequest:(NSURL *)url {
    for (NSURLRequest *request in _cachedRequests) {
        if ([request.URL isEqual:url]) {
            return request;
        }
    }
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
    
    NSString *extension = [response.suggestedFilename pathExtension].lowercaseString;
    NSString *scheme = response.URL.scheme;
    if ([extension isEqualToString:@"mobileconfig"] ||
        ![@[@"http", @"https", @"ftp", @"about"] containsObject:scheme]) {
        [_channel invokeMethod:@"onOpenInBrowser"
                     arguments:@{
                         @"id": @(self.webId),
                         @"url": response.URL.absoluteString,
                     } result:^(id  _Nullable result) {
            BOOL willOpen = [result isKindOfClass:NSNumber.class] ? [result boolValue] : NO;
            decisionHandler(willOpen ? WKNavigationResponsePolicyCancel : WKNavigationResponsePolicyAllow);
        }];
        return;
    }
    
    NSString *disposition = [response.allHeaderFields objectForKey:@"Content-Disposition"];
    if ([disposition isEqualToString:@"inline"]) {
        disposition = nil;
    }
    
    BOOL tested = NO;
    if (disposition && response.suggestedFilename != NULL) {
        tested = YES;
    }
    if (!tested) {
        NSString *contentType = response.allHeaderFields[@"Content-Type"];
        if (!contentType) {
            contentType = response.allHeaderFields[@"content-type"];
        }
        if (contentType && [self testString:contentType withList:self.downloadMimeTypes]) {
            tested = YES;
        }
    }
    if (tested) {
        NSURLRequest *request = [self findRequest:response.URL];
        if (request) {
            [_channel invokeMethod:@"onDownload"
                         arguments:@{
                             @"id": @(self.webId),
                             @"url": response.URL.absoluteString,
                             @"method": request.HTTPMethod,
                             @"headers": request.allHTTPHeaderFields,
                             @"filename": response.suggestedFilename,
                         }
                            result:^(id  _Nullable result) {
                BOOL willDownload = [result isKindOfClass:NSNumber.class] ? [result boolValue] : NO;
                decisionHandler(willDownload ? WKNavigationResponsePolicyCancel : WKNavigationResponsePolicyAllow);
            }];
            return;
        }
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (BOOL)testString:(NSString *)string withList:(NSArray<NSString *> *)list {
    for (NSString *temp in list) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self LIKE %@", temp];
        if ([predicate evaluateWithObject:string]) return YES;
    }
    return NO;
}

- (void)onEvent:(WKScriptMessage *)message {
    NSString *event = message.body[@"event"];
    id data = message.body[@"data"];
    if (!event) return;
    if (!data) {
        data = NSNull.null;
    }
    [self.channel invokeMethod:@"onEvent"
                     arguments:@{
                         @"id": @(self.webId),
                         @"event": event,
                         @"data": data,
                     }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_enablePullDown) {
        [_indicator onScroll:scrollView.contentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_enablePullDown) {
        if ([_indicator onEndScroll]) {
            [_impactFeedback impactOccurred];
            [self.channel invokeMethod:@"onOverDrag"
                             arguments:@{
                                 @"id": @(self.webId),
                             }];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_enablePullDown) {
        [_indicator onStartDrag];
    }
}

- (void)onPause {
    [NSNotificationCenter.defaultCenter postNotificationName:WebViewPauseNotification
                                                      object:@{
                                                          @"id": @(self.webId),
                                                      }];
}

- (void)onResume {
    [NSNotificationCenter.defaultCenter postNotificationName:WebViewResumeNotification
                                                      object:@{
                                                          @"id": @(self.webId),
                                                      }];
}

- (void)onPinch:(GrabGestureRecognizer *)pinch {
    switch (pinch.state) {
        case UIGestureRecognizerStateRecognized:
            [self.channel invokeMethod:@"onGrab"
                             arguments:@{
                                 @"id": @(self.webId),
                             }];
            break;
            
        default:
            break;
    }
}

@end
