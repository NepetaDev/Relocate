#import <Cephei/HBPreferences.h>
#import <CoreLocation/CLLocation.h>
#import "Tweak.h"
#import "RLCLocationManagerDelegate.h"

#define PLIST_PATH @"/var/lib/dpkg/info/me.nepeta.relocate.list"

HBPreferences *preferences;

bool globalEnabled;
bool appEnabled;
int currentAppEnabled;
bool dpkgInvalid;

bool enabled;
CLLocationCoordinate2D coordinate;
NSDictionary *locationDict;

CLLocation *getOverridenLocation(CLLocation *location) {
    double altitude = location.altitude;
    if (locationDict[@"AltitudeOverride"] && [locationDict[@"AltitudeOverride"] boolValue] && locationDict[@"Altitude"]) {
        altitude = [locationDict[@"Altitude"] doubleValue];
    }
    return [[CLLocation alloc] initWithCoordinate:coordinate
        altitude:altitude
        horizontalAccuracy:location.horizontalAccuracy
        verticalAccuracy:location.verticalAccuracy
        course:location.course
        speed:location.speed
        timestamp:location.timestamp
    ];
}

@implementation RLCLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (![self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) return;
    if (enabled) {
        NSMutableArray *betterLocations = [NSMutableArray new];
        for (CLLocation *location in locations) {
            [betterLocations addObject:getOverridenLocation(location)];
        }
        [self.delegate locationManager:manager didUpdateLocations:betterLocations];
    } else {
        [self.delegate locationManager:manager didUpdateLocations:locations];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) [self.delegate locationManager:manager didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(locationManager:didFinishDeferredUpdatesWithError:)]) [self.delegate locationManager:manager didFinishDeferredUpdatesWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (![self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:)]) return;
    if (enabled) {
        [self.delegate locationManager:manager didUpdateToLocation:getOverridenLocation(newLocation) fromLocation:getOverridenLocation(oldLocation)];
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
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) [self.delegate locationManager:manager didUpdateHeading:newHeading];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if ([self.delegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)])return [self.delegate locationManagerShouldDisplayHeadingCalibration:manager];
    return NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) [self.delegate locationManager:manager didChangeAuthorizationStatus:status];
}

@end

%group Relocate

%hook CLLocationManager

%property (nonatomic, retain) RLCLocationManagerDelegate* rlcDelegate;

-(void)setDelegate:(id)delegate {
    if (!self.rlcDelegate) {
        self.rlcDelegate = [[RLCLocationManagerDelegate alloc] init];
    }

    self.rlcDelegate.delegate = delegate;

    %orig(self.rlcDelegate);
}

-(CLLocation *)location {
    if (!enabled) return %orig;
    
    CLLocation *location = %orig;
    return getOverridenLocation(location);
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
    NSArray *blacklist = @[
        @"backboardd",
        @"duetexpertd",
        @"lsd",
        @"nsurlsessiond",
        @"assertiond",
        @"ScreenshotServicesService",
        @"com.apple.datamigrator",
        @"CircleJoinRequested",
        @"nanotimekitcompaniond",
        @"ReportCrash",
        @"ptpd"
    ];

    NSString *processName = [NSProcessInfo processInfo].processName;
    for (NSString *process in blacklist) {
        if ([process isEqualToString:processName]) {
            return;
        }
    }

    BOOL isSpringboard = [@"SpringBoard" isEqualToString:processName];
    BOOL isLocationd = [@"locationd" isEqualToString:processName];

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
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound
                        || ![[NSFileManager defaultManager] fileExistsAtPath:PLIST_PATH];
            if (!isFileProvider && (isApplication || isLocationd || isSpringboard) && !skip && [[NSFileManager defaultManager] fileExistsAtPath:PLIST_PATH]) {
                shouldLoad = !dpkgInvalid;
            }
        }
    }

    if (dpkgInvalid) {
        if (isSpringboard) %init(RelocateIntegrityFail);
        return;
    }

    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
    [preferences registerBool:&globalEnabled default:NO forKey:@"GlobalEnabled"];
    [preferences registerBool:&appEnabled default:YES forKey:@"AppEnabled"];

    enabled = NO;
    currentAppEnabled = 0;
    coordinate = CLLocationCoordinate2DMake(0,0);
    locationDict = @{};

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    [preferences registerPreferenceChangeBlock:^() {

        if ([preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", bundleIdentifier]]) {
            currentAppEnabled = [[preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", bundleIdentifier]] intValue];
        }

        enabled = NO;
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

        if (!enabled) return;

        NSDictionary *coordinateDict = locationDict[@"Coordinate"];
        if (coordinateDict && coordinateDict[@"Latitude"] && coordinateDict[@"Longitude"]) {
            coordinate = CLLocationCoordinate2DMake([coordinateDict[@"Latitude"] doubleValue], [coordinateDict[@"Longitude"] doubleValue]);
        }
    }];

    %init(Relocate);
}
