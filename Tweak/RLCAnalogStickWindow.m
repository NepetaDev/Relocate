#import "RLCAnalogStickWindow.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation RLCAnalogStickWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.windowLevel = UIWindowLevelAlert + 1;

    [self setUserInteractionEnabled:YES];
    self.hidden = YES;

    self.stickThickness = 20.0;

    self.circleLayer = [CAShapeLayer layer];
    [self.circleLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    [self.circleLayer setFillColor:[[UIColor clearColor] CGColor]];
    self.circleLayer.lineWidth = 5;
    [self.layer addSublayer:self.circleLayer];

    self.stickLayer = [CAShapeLayer layer];
    [self.stickLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    [self.stickLayer setFillColor:[[UIColor blackColor] CGColor]];
    self.stickLayer.lineWidth = 5;
    [self.layer addSublayer:self.stickLayer];

    return self;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.circleFrame, point)) return self;
    else return nil;
}


-(void)setCircleFrame:(CGRect)frame {
    _circleFrame = frame;
    self.circleRadius = MIN(frame.size.width, frame.size.height)/2.0;
    self.circleCenter = CGPointMake(frame.origin.x + self.circleRadius, frame.origin.y + self.circleRadius);
    [self.circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:self.circleFrame] CGPath]];
    [self revertStickToDefault];
}

-(void)setStickPosition:(CGPoint)point {
    [self.stickLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - self.stickThickness/2.0, point.y - self.stickThickness/2.0, self.stickThickness, self.stickThickness)] CGPath]];
}

-(void)revertStickToDefault {
    [self setStickPosition:self.circleCenter];
    self.inputX = 0;
    self.inputY = 0;
    self.hitsBorder = NO;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    CGFloat dx = point.x - self.circleCenter.x;
    CGFloat dy = point.y - self.circleCenter.y;
    CGFloat distance = sqrt(dx*dx + dy*dy);

    if (distance <= self.circleRadius) {
        [self setStickPosition:point];
        self.hitsBorder = NO;
        self.inputX = dx;
        self.inputY = -1 * dy;
    } else {
        if (!self.hitsBorder) {
            AudioServicesPlaySystemSound(1519);
        }
        self.hitsBorder = YES;
        [self setStickPosition:CGPointMake(self.circleCenter.x + (self.circleRadius/distance)*dx, self.circleCenter.y + (self.circleRadius/distance)*dy)];
        self.inputX = (self.circleRadius/distance)*dx;
        self.inputY = -1 * (self.circleRadius/distance)*dy;
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self revertStickToDefault];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self revertStickToDefault];
}

@end