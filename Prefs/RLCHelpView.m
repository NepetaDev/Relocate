#import "RLCHelpView.h"

@implementation RLCHelpView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    self.layer.cornerRadius = 10;
    self.backgroundColor = [UIColor clearColor];

    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        blurEffectView.layer.cornerRadius = 10;
        blurEffectView.layer.masksToBounds = YES;

        [self addSubview:blurEffectView];
    } else {
        self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    }

    self.textLabel = [[UILabel alloc] initWithFrame:frame];
    [self.textLabel setText:@""];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.font = [UIFont systemFontOfSize:14];
    self.textLabel.numberOfLines = 0;

    [self addSubview:self.textLabel];

    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.textLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
        [self.textLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
        [self.textLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        [self.textLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
    ]];

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowOffset = CGSizeMake(0.0, -2.5);
    self.layer.shadowRadius = 10;
    self.layer.masksToBounds = NO;

    return self;
}

-(void)setText:(NSString *)text {
    [self.textLabel setText:text];
    _text = text;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [UIView animateWithDuration:0.3
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.0;
    } completion:NULL];
}

@end