#import "RLCCrossHairView.h"

@implementation RLCCrossHairView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    _verticalLayer = [CALayer new];
    _horizontalLayer = [CALayer new];

    _verticalLayer.backgroundColor = [UIColor blackColor].CGColor;
    _horizontalLayer.backgroundColor = [UIColor blackColor].CGColor;

    [self.layer addSublayer:_verticalLayer];
    [self.layer addSublayer:_horizontalLayer];

    /* how to use:

    _crosshair = [[RLCCrossHairView alloc] initWithFrame:CGRectMake(0,0,10,10)];
    _crosshair.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mapView addSubview:_crosshair];
    [NSLayoutConstraint activateConstraints:@[
        [_crosshair.centerXAnchor constraintEqualToAnchor:self.mapView.centerXAnchor],
        [_crosshair.centerYAnchor constraintEqualToAnchor:self.mapView.centerYAnchor],
        [_crosshair.heightAnchor constraintEqualToConstant:20],
        [_crosshair.widthAnchor constraintEqualToConstant:20],
    ]];
    
    */

    return self;
}

-(void)layoutSubviews {
    _horizontalLayer.frame = CGRectMake(0, self.bounds.size.height/2.0 - 2.0, self.bounds.size.width, 4.0);
    _verticalLayer.frame = CGRectMake(self.bounds.size.width/2.0 - 2.0, 0, 4.0, self.bounds.size.height);
}

@end