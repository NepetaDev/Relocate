#import <MapKit/MapKit.h>
#import "RLCLocationPickerAdvancedSettingsView.h"
#import "RLCHelpView.h"

#define GRABBER_HEIGHT 55

@interface RLCLocationPickerView : UIView <MKMapViewDelegate>

@property (nonatomic, retain) UITableView *searchResultsView;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) RLCHelpView *helpView;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic, retain) MKPointAnnotation *pin;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressRecognizer;

@property (nonatomic, retain) RLCLocationPickerAdvancedSettingsView *advancedSettingsView;
@property (nonatomic, retain) NSLayoutConstraint *advancedSettingsViewHeightConstraintVisible;
@property (nonatomic, retain) NSLayoutConstraint *advancedSettingsViewHeightConstraintHidden;

-(void)hideCallouts;
-(id)initWithFrame:(CGRect)frame controller:(UIViewController*)controller;
-(void)createPinAt:(CLLocationCoordinate2D)coord;
-(void)showHelpView;
-(void)hideHelpView;

@end