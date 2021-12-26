//
//  DragIndicator.m
//  browser_webview
//
//  Created by gen on 9/19/21.
//

#import "DragIndicator.h"

#define SIZE 36
#define INNER_SIZE 24
#define OVER_DRAG 68

@interface DragIndicatorInner : UIView

@property (nonatomic, assign) CGFloat percent;

@end

@implementation DragIndicatorInner

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat radius = INNER_SIZE/2;
    CGFloat start = -M_PI_2;
    CGContextAddArc(context, radius, radius, radius - 3, start, start - M_PI * 2 * self.percent, 1);
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetLineWidth(context, 3);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)setPercent:(CGFloat)percent {
    _percent = percent;
    [self setNeedsDisplay];
}

@end

@implementation DragIndicator {
    UIView *_backgroundView;
    DragIndicatorInner *_inner;
    BOOL _overdrag;
    
    BOOL _draging;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SIZE, SIZE)];
        _backgroundView.backgroundColor = [UIColor whiteColor];
        _backgroundView.layer.cornerRadius = SIZE / 2;
        _backgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        _backgroundView.layer.shadowColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        _backgroundView.layer.shadowRadius = 4;
        _backgroundView.layer.shadowOpacity = 1;
        [self addSubview:_backgroundView];
        
        CGFloat off = (SIZE - INNER_SIZE) / 2;
        _inner = [[DragIndicatorInner alloc] initWithFrame:CGRectMake(off, off, INNER_SIZE, INNER_SIZE)];
        [self addSubview:_inner];
        
        self.alpha = 0;
    }
    return self;
}

- (void)onScroll:(CGPoint)offset {
    if (_draging) {
        if (offset.y < 0) {
            _inner.percent = MAX(0, MIN(1, -offset.y / OVER_DRAG));
            
        }
        _overdrag = -offset.y > OVER_DRAG;
    }
    if (offset.y < 0) {
        self.alpha = MAX(0, MIN(1, -offset.y / OVER_DRAG / 0.3));
    } else {
        self.alpha = 0;
    }
}

- (BOOL)onEndScroll {
    _draging = false;
    return _overdrag;
}

- (void)onStartDrag {
    _draging = true;
}

@end
