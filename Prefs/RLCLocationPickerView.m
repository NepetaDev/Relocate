#import "RLCLocationPickerView.h"
#import "RLCLocationPickerViewController.h"

@implementation RLCLocationPickerView

-(id)initWithFrame:(CGRect)frame controller:(UIViewController*)controller {
    self = [super initWithFrame:frame];

    self.overlayView = [[UIView alloc] initWithFrame:frame];
    self.overlayView.backgroundColor = [UIColor blackColor];
    self.overlayView.userInteractionEnabled = NO;
    self.overlayView.alpha = 0.0;
    
    self.mapView = [[MKMapView alloc] initWithFrame:frame];
    self.mapView.delegate = self;

    self.advancedSettingsView = [[RLCLocationPickerAdvancedSettingsView alloc] initWithFrame:frame controller:controller];
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(movePin:)];
    [self.mapView addGestureRecognizer:self.longPressRecognizer];

    self.helpView = [[RLCHelpView alloc] initWithFrame:frame];
    self.helpView.text = @"Long press on the map to select a location,\n\"Save\" to confirm your choice.";

    [self addSubview:self.mapView];
    [self addSubview:self.helpView];
    [self addSubview:self.overlayView];
    [self addSubview:self.advancedSettingsView];

    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.helpView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.advancedSettingsView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.helpView.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:10],
        [self.helpView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [self.helpView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        [self.helpView.heightAnchor constraintEqualToConstant:60],
    ]];

    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = self.safeAreaInsets.bottom;
    }

    self.advancedSettingsViewHeightConstraintHidden = [self.advancedSettingsView.heightAnchor constraintEqualToConstant:GRABBER_HEIGHT + bottomInset];
    self.advancedSettingsViewHeightConstraintVisible = [self.advancedSettingsView.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:-100];
    [NSLayoutConstraint activateConstraints:@[
        [self.advancedSettingsView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.advancedSettingsView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.advancedSettingsView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        self.advancedSettingsViewHeightConstraintHidden
    ]];

    return self;
}

-(void)showHelpView {
    [UIView animateWithDuration:0.3
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.helpView.alpha = 1.0;
    } completion:NULL];
}

-(void)hideHelpView {
    [UIView animateWithDuration:0.3
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.helpView.alpha = 0.0;
    } completion:NULL];
}

-(void)layoutSubviews {
    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = self.safeAreaInsets.bottom;
    }

    self.advancedSettingsViewHeightConstraintHidden.constant = GRABBER_HEIGHT + bottomInset;
    [super layoutSubviews];
}

-(void)createPinAt:(CLLocationCoordinate2D)coord {
    MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
    MKCoordinateRegion region = {coord, span};

    self.pin = [[MKPointAnnotation alloc] init];
    [self.pin setCoordinate:coord];
    [self.pin setTitle:@"Selected location"];

    [self.mapView setRegion:region];
    [self.mapView addAnnotation:self.pin];
}

-(void)hideCallouts {
    for (id annotation in self.mapView.selectedAnnotations) {
        [self.mapView deselectAnnotation:annotation animated:YES];
    }
}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [self hideCallouts];
}


-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKMarkerAnnotationView *view = (id)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
    if (view) {
        view.annotation = annotation;
    } else {
        view = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
        view.canShowCallout = true;
        
        if (annotation != self.pin) return view;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 50, 40);

        [button setBackgroundColor:self.tintColor];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"★" forState:UIControlStateNormal];
        [button addTarget:self.nextResponder action:@selector(favorite:) forControlEvents:UIControlEventPrimaryActionTriggered];

        view.rightCalloutAccessoryView = button;
    }

    return view;
}

-(void)movePin:(UIGestureRecognizer *)recognizer {
    [self hideCallouts];
    [self hideHelpView];

    CGPoint point = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D coord = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    if (!self.pin) [self createPinAt:coord];
    else [self.pin setCoordinate:coord];
    [self.pin setTitle:@"Selected location"];
}

@end