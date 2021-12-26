//
//  GrapGestureRecognizer.m
//  browser_webview
//
//  Created by gen on 10/4/21.
//

#import "GrabGestureRecognizer.h"

@implementation GrabGestureRecognizer {
    CGFloat _startRadius;
    CGPoint _startCenter;
    NSTimeInterval _startTime;
}

- (CGPoint)caculateTouches:(NSSet <UITouch *> *)touches radius:(CGFloat *)radius {
    CGPoint center = CGPointZero;
    if (touches.count > 1) {
        for (UITouch *touch in touches) {
            CGPoint pointer = [touch locationInView:self.view];
            center.x += pointer.x;
            center.y += pointer.y;
        }
        center.x /= touches.count;
        center.y /= touches.count;
        
        CGFloat r = 0;
        for (UITouch *touch in touches) {
            CGPoint pointer = [touch locationInView:self.view];
            r += sqrtf((center.x - pointer.x) * (center.x - pointer.x) + (center.y - pointer.y) * (center.y - pointer.y));
        }
        r /= touches.count;
        *radius = r;
    }
    return center;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _startRadius = 0;
    if (event.allTouches.count >= 3) {
        _startCenter = [self caculateTouches:event.allTouches radius:&_startRadius];
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (event.allTouches.count >= 3) {
        CGFloat radius;
        CGPoint center = [self caculateTouches:event.allTouches radius:&radius];
        if (_startRadius == 0) {
            _startRadius = radius;
            _startCenter = center;
            self.state = UIGestureRecognizerStateBegan;
        } else {
            CGFloat p = radius / _startRadius;
            if (p < 0.7) {
                self.state = UIGestureRecognizerStateRecognized;
            } else if (p > 1) {
                self.state = UIGestureRecognizerStateFailed;
            }
        }
    } else {
        if (_startRadius == 0 && NSDate.new.timeIntervalSince1970 - _startTime > 0.15) {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.state == UIGestureRecognizerStatePossible ||
        self.state == UIGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateFailed;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.state == UIGestureRecognizerStatePossible ||
        self.state == UIGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateCancelled;
    }
}

@end
