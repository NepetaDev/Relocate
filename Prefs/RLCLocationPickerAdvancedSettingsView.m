#import "RLCLocationPickerAdvancedSettingsView.h"
#import "RLCLocationPickerView.h"
#import "RLCLocationPickerViewController.h"

@implementation RLCLocationPickerAdvancedSettingsView

-(id)initWithFrame:(CGRect)frame controller:(UIViewController*)controller {
    self = [super initWithFrame:frame];

    self.layer.cornerRadius = 10;
    self.backgroundColor = [UIColor clearColor];

    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        blurEffectView.layer.cornerRadius = 10;
        blurEffectView.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
        blurEffectView.layer.masksToBounds = YES;

        [self addSubview:blurEffectView];
    } else {
        self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    }

    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.panGestureRecognizer];

    self.advancedSettingsLabel = [[UILabel alloc] initWithFrame:frame];
    [self.advancedSettingsLabel setText:@"Advanced settings"];
    self.advancedSettingsLabel.textAlignment = NSTextAlignmentCenter;
    self.advancedSettingsLabel.font = [UIFont systemFontOfSize:14];

    self.chevronButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.chevronButton.tintColor = [UIColor blackColor];
    self.chevronButton.transform = CGAffineTransformMakeRotation(M_PI);
    self.chevronButton.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
    [self.chevronButton addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    self.chevronButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.chevronButton setTitle:NULL forState:UIControlStateNormal];
    [self.chevronButton setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/RelocatePrefs.bundle/chevron.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self addSubview:self.advancedSettingsLabel];
    [self addSubview:self.chevronButton];

    self.chevronButton.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.chevronButton.heightAnchor constraintEqualToConstant:30],
        [self.chevronButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
        [self.chevronButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        [self.chevronButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:0]
    ]];

    self.advancedSettingsLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.advancedSettingsLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
        [self.advancedSettingsLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        [self.advancedSettingsLabel.topAnchor constraintEqualToAnchor:self.chevronButton.bottomAnchor]
    ]];

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowOffset = CGSizeMake(0.0, -2.5);
    self.layer.shadowRadius = 10;
    self.layer.masksToBounds = NO;

    self.listController = [[RLCLocationPickerAdvancedSettingsListViewController alloc] init];
    self.listController.view.alpha = 0.0;

    [controller addChildViewController:self.listController];
    [self addSubview:self.listController.view];
    [self.listController didMoveToParentViewController:controller];

    self.listController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.listController.view.topAnchor constraintEqualToAnchor:self.chevronButton.bottomAnchor],
        [self.listController.view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.listController.view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.listController.view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:10],
    ]];

    return self;
}

-(void)setProgress:(CGFloat)progress {
    RLCLocationPickerView *parent = (RLCLocationPickerView *)self.superview;

    self.advancedSettingsLabel.alpha = 1.0 - progress;
    self.listController.view.alpha = progress;
    parent.overlayView.alpha = progress * 0.75;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (recognizer != self.panGestureRecognizer) return false;

    CGPoint velocity = [((UIPanGestureRecognizer *)recognizer) velocityInView:self];
    if ([self.listController table].contentOffset.y <= 0 && velocity.y > 0) {
        [self.listController table].scrollEnabled = false;
        return true;
    } else {
        [self.listController table].scrollEnabled = true;
    }

    return false;
}

-(void)panGesture:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.frame.origin.y > self.superview.bounds.size.height * 2.5/3.0) {
            [self hide];
            return;
        }

        CGPoint velocity = [recognizer velocityInView:self];
        if (velocity.y > 5) {
            [self hide];
            return;
        } else if (velocity.y < -5) {
            [self show];
            return;
        }
        
        RLCLocationPickerView *parent = (RLCLocationPickerView *)self.superview;
        [UIView animateWithDuration:0.4
                delay:0.0
                usingSpringWithDamping:0.75
                initialSpringVelocity:0.2
                options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [parent setNeedsLayout];
            [parent layoutIfNeeded];
        } completion:NULL];
    } else {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y + translation.y, self.frame.size.width, self.frame.size.height - translation.y);
        CGFloat progress = 1.0 - (self.frame.origin.y + translation.y - 150.0)/(self.superview.frame.size.height - 150.0);
        if (progress > 1) progress = 1;
        if (progress < 0) progress = 0;
        [self setProgress:progress];
    }

    [recognizer setTranslation:CGPointZero inView:self];
}

-(void)show {
    RLCLocationPickerView *parent = (RLCLocationPickerView *)self.superview;
    self.chevronButton.transform = CGAffineTransformMakeRotation(0);
    parent.advancedSettingsViewHeightConstraintHidden.active = NO;
    parent.advancedSettingsViewHeightConstraintVisible.active = YES;
    [parent hideHelpView];
    
    [UIView animateWithDuration:0.4
            delay:0.0
            usingSpringWithDamping:0.75
            initialSpringVelocity:0.2
            options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setProgress:1];
        [parent setNeedsLayout];
        [parent layoutIfNeeded];
    } completion:NULL];
}

-(void)hide {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];

    RLCLocationPickerView *parent = (RLCLocationPickerView *)self.superview;
    self.chevronButton.transform = CGAffineTransformMakeRotation(M_PI);
    parent.advancedSettingsViewHeightConstraintHidden.active = YES;
    parent.advancedSettingsViewHeightConstraintVisible.active = NO;
    [UIView animateWithDuration:0.4
            delay:0.0
            usingSpringWithDamping:0.75
            initialSpringVelocity:0.2
            options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setProgress:0];
        [parent setNeedsLayout];
        [parent layoutIfNeeded];
    } completion:NULL];
}

-(void)toggle {
    RLCLocationPickerView *parent = (RLCLocationPickerView *)self.superview;
    if (parent.advancedSettingsViewHeightConstraintHidden.active) {
        [self show];
    } else {
        [self hide];
    }
}

@end