#import <Cephei/HBPreferences.h>
#import <CoreLocation/CLLocation.h>
#import "Tweak.h"
#import "RLCLocationManagerDelegate.h"

HBPreferences *preferences;

bool globalEnabled;
bool appEnabled;
bool currentAppEnabled;

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

%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
    [preferences registerBool:&globalEnabled default:NO forKey:@"GlobalEnabled"];
    [preferences registerBool:&appEnabled default:NO forKey:@"AppEnabled"];

    enabled = NO;
    currentAppEnabled = NO;
    coordinate = CLLocationCoordinate2DMake(0,0);
    locationDict = @{};

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    [preferences registerPreferenceChangeBlock:^() {

        if ([preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", bundleIdentifier]]) {
            currentAppEnabled = [[preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", bundleIdentifier]] boolValue];
        }

        enabled = NO;
        if (globalEnabled) {
            enabled = YES;
            locationDict = [preferences objectForKey:@"GlobalLocation"];
        }

        if (appEnabled && currentAppEnabled) {
            enabled = YES;
            locationDict = [preferences objectForKey:[NSString stringWithFormat:@"App_%@_Location", bundleIdentifier]];
        }

        if (!enabled) return;

        NSDictionary *coordinateDict = locationDict[@"Coordinate"];
        if (coordinateDict && coordinateDict[@"Latitude"] && coordinateDict[@"Longitude"]) {
            coordinate = CLLocationCoordinate2DMake([coordinateDict[@"Latitude"] doubleValue], [coordinateDict[@"Longitude"] doubleValue]);
        }
    }];

    %init;
}
