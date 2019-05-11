#import "RLCLocationPickerAdvancedSettingsListViewController.h"

@interface RLCLocationPickerAdvancedSettingsView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UILabel *advancedSettingsLabel;
@property (nonatomic, retain) UIButton *chevronButton;
@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, retain) RLCLocationPickerAdvancedSettingsListViewController *listController;

-(id)initWithFrame:(CGRect)frame controller:(UIViewController*)controller;
-(void)show;
-(void)hide;
-(void)toggle;
-(void)setProgress:(CGFloat)progress;

@end