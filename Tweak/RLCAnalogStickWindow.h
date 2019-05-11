@interface RLCAnalogStickWindow : UIWindow

@property (nonatomic, assign) CGRect circleFrame;
@property (nonatomic, assign) CGPoint circleCenter;
@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, assign) CGFloat stickThickness;
@property (nonatomic, assign) CGFloat inputX;
@property (nonatomic, assign) CGFloat inputY;
@property (nonatomic, retain) CAShapeLayer *circleLayer;
@property (nonatomic, retain) CAShapeLayer *stickLayer;
@property (nonatomic, assign) BOOL hitsBorder;

-(instancetype)initWithFrame:(CGRect)frame;
-(void)setStickPosition:(CGPoint)point;
-(void)revertStickToDefault;

@end