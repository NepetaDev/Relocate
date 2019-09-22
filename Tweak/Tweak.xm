#import <Cephei/HBPreferences.h>
#import "Tweak.h"
#import "RLCLocationManagerDelegate.h"
#import "RLCAnalogStickWindow.h"

#define PLIST_PATH @"/var/lib/dpkg/info/me.nepeta.relocate.list"

HBPreferences *preferences;

bool rlcEnabled;
bool globalEnabled;
bool globalNoGPS;
bool appEnabled;
int currentAppEnabled;
bool dpkgInvalid;
bool noGPSMode;
bool managerInitialized;

bool enabled;
bool joystick;
CLLocationCoordinate2D coordinate;
NSDictionary *locationDict;
RLCAnalogStickWindow *analogStickWindow;

@interface NSNull (Relocate)
-(int)intValue;
-(BOOL)boolValue;
@end

@implementation NSNull (Relocate)

-(int)intValue {
    return 0;
}

-(BOOL)boolValue {
    return false;
}

@end

@implementation RLCManager

+(instancetype)sharedInstance {
    static RLCManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [RLCManager alloc];
        managerInitialized = YES;
    });
    return sharedInstance;
}

+(CLLocation *)getOverridenLocation:(CLLocation *)location {
    double altitude = location.altitude;
    if (locationDict[@"AltitudeOverride"] && [locationDict[@"AltitudeOverride"] boolValue] && locationDict[@"Altitude"]) {
        altitude = [locationDict[@"Altitude"] doubleValue];
    }

    return [[CLLocation alloc] initWithCoordinate:coordinate
        altitude:altitude
        horizontalAccuracy:location.horizontalAccuracy
        verticalAccuracy:location.verticalAccuracy
        course:location.course
        speed:0
        timestamp:location.timestamp
    ];
}

+(CLLocation *)getFabricatedLocation {
    double altitude = 420;
    if (locationDict[@"AltitudeOverride"] && [locationDict[@"AltitudeOverride"] boolValue] && locationDict[@"Altitude"]) {
        altitude = [locationDict[@"Altitude"] doubleValue];
    }

    return [[CLLocation alloc]
        initWithCoordinate:coordinate
        altitude:altitude
        horizontalAccuracy:10
        verticalAccuracy:10
        course:1
        speed:0
        timestamp:[NSDate date]
    ];
}

+(CLHeading *)getFabricatedHeading {
    CLHeadingInternalStruct internal;
    internal.x = 1;
    internal.y = 1;
    internal.z = 1;
    internal.magneticHeading = 1;
    internal.trueHeading = 1;
    internal.accuracy = 20;
    internal.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
    internal.temperature = 0;
    internal.magnitude = 0;
    internal.inclination = 0;
    internal.calibration = 5;
    return [[CLHeading alloc] initWithClientHeading:internal];
}

-(id)init {
    return [RLCManager sharedInstance];
}

-(void)update {
    if (!enabled || !noGPSMode) return;
    if (!_managers || [_managers count] == 0) return;

    for (id manager in [[_managers copy] reverseObjectEnumerator]) {
        [self updateManager:manager];
    }
}

-(void)updateManager:(CLLocationManager*)manager {
    if (!manager) return;
    if ([[manager delegate] respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [[manager delegate] locationManager:manager didUpdateLocations:@[
            [RLCManager getFabricatedLocation]
        ]];
    }

    if ([[manager delegate] respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
        [[manager delegate] locationManager:manager didUpdateToLocation:[RLCManager getFabricatedLocation] fromLocation:[RLCManager getFabricatedLocation]];
    }

    if ([[manager delegate] respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
        [[manager delegate] locationManager:manager didUpdateHeading:[RLCManager getFabricatedHeading]];
    }
}

-(void)addManager:(CLLocationManager*)manager {
    if (!manager) return;
    if (!_managers) _managers = [NSMutableArray new];
    if (![_managers containsObject:manager]) [_managers addObject:manager];

    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(update) userInfo:nil repeats:YES];
    }
}

-(void)removeManager:(CLLocationManager*)manager {
    if (!_managers || !manager) return;
    [_managers removeObject:manager];
}

@end

@implementation RLCLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (enabled && noGPSMode) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        if (enabled) {
            NSMutableArray *betterLocations = [NSMutableArray new];
            for (CLLocation *location in locations) {
                [betterLocations addObject:[RLCManager getOverridenLocation:location]];
            }
            [self.delegate locationManager:manager didUpdateLocations:[[NSArray alloc] initWithArray:betterLocations]];
        } else {
            [self.delegate locationManager:manager didUpdateLocations:locations];
        }
    }

    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)] && [locations count] > 0) {
        if (enabled) {
            [self.delegate locationManager:manager didUpdateToLocation:[RLCManager getOverridenLocation:locations[[locations count] - 1]] fromLocation:[RLCManager getOverridenLocation:locations[0]]];
        } else {
            [self.delegate locationManager:manager didUpdateToLocation:locations[[locations count] - 1] fromLocation:locations[0]];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) [self.delegate locationManager:manager didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(locationManager:didFinishDeferredUpdatesWithError:)]) [self.delegate locationManager:manager didFinishDeferredUpdatesWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (![self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) return;
    if (enabled && noGPSMode) return;
    if (enabled) {
        [self.delegate locationManager:manager didUpdateToLocation:[RLCManager getOverridenLocation:newLocation] fromLocation:[RLCManager getOverridenLocation:oldLocation]];
    } else {
        [self.delegate locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    if ([self.delegate respondsToSelector:@selector(locationManagerDidPauseLocationUpdates:)]) [self.delegate locationManagerDidPauseLocationUpdates:manager];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    if ([self.delegate respondsToSelector:@selector(locationManagerDidResumeLocationUpdates:)]) [self.delegate locationManagerDidResumeLocationUpdates:manager];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (enabled && noGPSMode) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) [self.delegate locationManager:manager didUpdateHeading:newHeading];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if ([self.delegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) return [self.delegate locationManagerShouldDisplayHeadingCalibration:manager];
    return NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
        if (enabled && noGPSMode) [self.delegate locationManager:manager didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
        else [self.delegate locationManager:manager didChangeAuthorizationStatus:status];
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didVisit:)]) {
        [self.delegate locationManager:manager didVisit:visit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didRangeBeacons:inRegion:)]) {
        [self.delegate locationManager:manager didRangeBeacons:beacons inRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didStartMonitoringForRegion:)]) {
        [self.delegate locationManager:manager didStartMonitoringForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didDetermineState:forRegion:)]) {
        [self.delegate locationManager:manager didDetermineState:state forRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didEnterRegion:)]) {
        [self.delegate locationManager:manager didEnterRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:didExitRegion:)]) {
        [self.delegate locationManager:manager didExitRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)]) {
        [self.delegate locationManager:manager monitoringDidFailForRegion:region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    if (!enabled && [self.delegate respondsToSelector:@selector(locationManager:rangingBeaconsDidFailForRegion:withError:)]) {
        [self.delegate locationManager:manager rangingBeaconsDidFailForRegion:region withError:error];
    }
}

- (void)dealloc {
    [[RLCManager sharedInstance] removeManager:self.manager];
}

@end

%group Relocate

%hook UIWindow

-(void)layoutSubviews {
    %orig;
    if (!joystick) {
        if (analogStickWindow) analogStickWindow.hidden = YES;
        return;
    }

    if ([[[UIApplication sharedApplication] windows] firstObject] != self) return;

    if (!analogStickWindow) {
        analogStickWindow = [[RLCAnalogStickWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(rlcUpdatePosition) userInfo:nil repeats:YES];
        analogStickWindow.circleFrame = CGRectMake(analogStickWindow.bounds.size.width - 170, analogStickWindow.bounds.size.height - 170, 150, 150);
    }

    analogStickWindow.hidden = NO;
}

%new
-(void)rlcUpdatePosition {
    if (analogStickWindow.inputY != 0 && analogStickWindow.inputX != 0) {
        coordinate.latitude += analogStickWindow.inputY * 0.00001;
        coordinate.longitude += analogStickWindow.inputX * 0.00001;
        [[RLCManager sharedInstance] update];
    }
}

%end

%hook CLLocationManager

%property (nonatomic, retain) RLCLocationManagerDelegate* rlcDelegate;

-(void)setDelegate:(id)delegate {
    if (!self.rlcDelegate) {
        self.rlcDelegate = [[RLCLocationManagerDelegate alloc] init];
    }

    self.rlcDelegate.manager = self;
    self.rlcDelegate.delegate = delegate;

    %orig(self.rlcDelegate);
}

-(id)delegate {
    return self.rlcDelegate.delegate;
}

-(CLLocation *)location {
    if (!enabled) return %orig;
    if (noGPSMode) return [RLCManager getFabricatedLocation];

    return [RLCManager getOverridenLocation:%orig];
}

-(CLHeading *)heading {
    if (enabled && noGPSMode) return [RLCManager getFabricatedHeading];
    return %orig;
}

-(void)requestWhenInUseAuthorization {
    if (enabled && noGPSMode) return;
    %orig;
}

-(void)requestAlwaysAuthorization {
    if (enabled && noGPSMode) return;
    %orig;
}

- (void)requestWhenInUseAuthorizationWithPrompt {
    if (enabled && noGPSMode) return;
    %orig;
}

-(void)requestLocation {
    if (enabled && noGPSMode) {
        [[RLCManager sharedInstance] updateManager:self];
        return;
    }
    %orig;
}

-(void)startUpdatingLocation {
    [[RLCManager sharedInstance] addManager:self];
    [[RLCManager sharedInstance] update];
    %orig;
}

- (void)startUpdatingLocationWithPrompt {
    [[RLCManager sharedInstance] addManager:self];
    %orig;
}

-(void)stopUpdatingLocation {
    [[RLCManager sharedInstance] removeManager:self];
    %orig;
}

+(CLAuthorizationStatus)authorizationStatus {
    if (enabled && noGPSMode) return kCLAuthorizationStatusAuthorizedAlways;
    return %orig;
}

+(BOOL)locationServicesEnabled {
    if (enabled && noGPSMode) return YES;
    return %orig;
}

+(BOOL)headingAvailable {
    if (enabled && noGPSMode) return YES;
    return %orig;
}

%end

%end

%group RelocateIntegrityFail

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    if (!dpkgInvalid) return;
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"😡😡😡"
        message:@"The build of Relocate you're using comes from an untrusted source. Pirate repositories can distribute malware and you will get subpar user experience using any tweaks from them.\nRemember: Relocate is free. Uninstall this build and install the proper version of Relocate from:\nhttps://repo.nepeta.me/\n(it's free, damnit, why would you pirate that!?)"
        preferredStyle:UIAlertControllerStyleAlert
    ];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Damn!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((UIApplication*)self).keyWindow.rootViewController dismissViewControllerAnimated:YES completion:NULL];
    }]];

    [((UIApplication*)self).keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
}

%end

%end

%ctor {
    dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:PLIST_PATH];

    // Someone smarter than me invented this.
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    bool shouldLoad = NO;

    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                     // || [executablePath rangeOfString:@".appex/"].location != NSNotFound -- commented out to fix weather widget
                        || ![[NSFileManager defaultManager] fileExistsAtPath:PLIST_PATH];
            if (!isFileProvider && isApplication && !skip && [[NSFileManager defaultManager] fileExistsAtPath:PLIST_PATH]) {
                shouldLoad = !dpkgInvalid;
            }
        }
    }

    if (dpkgInvalid) {
        %init(RelocateIntegrityFail);
        return;
    }

    NSString *processName = [NSProcessInfo processInfo].processName;
    if (!shouldLoad) {
        NSArray *whitelist = @[
            @"findmydeviced",
            @"fmfd",
            @"fmflocatord",
        ];

        for (NSString *process in whitelist) {
            if ([process isEqualToString:processName]) {
                shouldLoad = YES;
            }
        }

        if (!shouldLoad) return;
    }

    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
    [preferences registerBool:&globalEnabled default:NO forKey:@"GlobalEnabled"];
    [preferences registerBool:&globalNoGPS default:NO forKey:@"GlobalNoGPS"];
    [preferences registerBool:&appEnabled default:YES forKey:@"AppEnabled"];
    [preferences registerBool:&rlcEnabled default:YES forKey:@"Enabled"];

    enabled = NO;
    joystick = NO;
    noGPSMode = NO;
    currentAppEnabled = 0;
    coordinate = CLLocationCoordinate2DMake(0,0);
    locationDict = @{};
    managerInitialized = NO;

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([processName isEqualToString:@"findmydeviced"]) {
        bundleIdentifier = @"com.apple.mobileme.fmip1";
    } else if ([processName isEqualToString:@"fmfd"] || [processName isEqualToString:@"fmflocatord"]) {
        bundleIdentifier = @"com.apple.mobileme.fmf1";
    }

    [preferences registerPreferenceChangeBlock:^() {
        enabled = NO;
        if (!rlcEnabled) return;
        
        noGPSMode = globalNoGPS;
        currentAppEnabled = [[preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", bundleIdentifier]] intValue];

        if (globalEnabled) {
            enabled = YES;
            locationDict = [preferences objectForKey:@"GlobalLocation"];
        }

        if (appEnabled && currentAppEnabled > 0) {
            if (currentAppEnabled == 2) {
                enabled = NO;
                return;
            }

            enabled = YES;
            locationDict = [preferences objectForKey:[NSString stringWithFormat:@"App_%@_Location", bundleIdentifier]];
        }

        if (appEnabled && currentAppEnabled != 2) {
            joystick = [[preferences objectForKey:[NSString stringWithFormat:@"App_%@_Joystick", bundleIdentifier]] boolValue];
        }

        if (!enabled) return;

        NSDictionary *coordinateDict = locationDict[@"Coordinate"];
        if (coordinateDict && coordinateDict[@"Latitude"] && coordinateDict[@"Longitude"]) {
            coordinate = CLLocationCoordinate2DMake([coordinateDict[@"Latitude"] doubleValue], [coordinateDict[@"Longitude"] doubleValue]);
        }

        if (managerInitialized) [[RLCManager sharedInstance] update];
    }];

    %init(Relocate);
}
