//
//  WebVIewContainer.h
//  browser_webview
//
//  Created by gen on 9/1/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN


@class WebViewContainer;

extern NSString *WebViewResumeNotification;
extern NSString *WebViewPauseNotification;

@protocol WebViewContainerDelegate <NSObject>

- (void)webViewContrainer:(WebViewContainer *)container createSubWindow:(WebViewContainer *)subContainer;

@end

@interface WebViewContainer : NSObject

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UIView *backgroundView;
@property (nonatomic, readonly) WKWebView *webView;
@property (nonatomic, readonly) NSInteger webId;
@property (nonatomic, readonly) FlutterMethodChannel *channel;

@property (nonatomic, strong) NSArray<NSString *> *downloadExtensions;
@property (nonatomic, strong) NSArray<NSString *> *downloadMimeTypes;

@property (nonatomic, assign) BOOL enablePullDown;

@property (nonatomic, weak) id<WebViewContainerDelegate> delegate;

- (id)initWithParams:(id)params withChannel:(FlutterMethodChannel *)channel;
- (id)initWithParams:(id)params withConfiguration:(nullable WKWebViewConfiguration *)configuration withChannel:(FlutterMethodChannel *)channel;

- (void)takeCaptureWithSize:(CGFloat)size withBlock:(void (^)(NSString *_Nullable path, NSError *_Nullable))block;

- (void)onPause;
- (void)onResume;

@end

NS_ASSUME_NONNULL_END
