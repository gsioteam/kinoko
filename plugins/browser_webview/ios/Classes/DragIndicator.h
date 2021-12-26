//
//  DragIndicator.h
//  browser_webview
//
//  Created by gen on 9/19/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DragIndicator : UIView

- (void)onStartDrag;
- (void)onScroll:(CGPoint)offset;
- (BOOL)onEndScroll;

@end

NS_ASSUME_NONNULL_END
