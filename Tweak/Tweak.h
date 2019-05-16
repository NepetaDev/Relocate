#import "RLCLocationManagerDelegate.h"
#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CLHeading.h>

@interface CLLocationManager(Relocate)

@property (nonatomic, retain) RLCLocationManagerDelegate* rlcDelegate;

@end

@interface RLCManager : NSObject {
    NSMutableArray *_managers;
    NSTimer *_timer;
}

+(instancetype)sharedInstance;
-(id)init;
-(void)update;
-(void)updateManager:(CLLocationManager*)manager;
-(void)addManager:(CLLocationManager*)manager;
-(void)removeManager:(CLLocationManager*)manager;

+(CLLocation *)getOverridenLocation:(CLLocation *)location;
+(CLLocation *)getFabricatedLocation;
+(CLHeading *)getFabricatedHeading;

@end

typedef struct CLHeadingInternalStruct {
    double x;
    double y;
    double z;
    double magneticHeading;
    double trueHeading;
    double accuracy;
    double timestamp;
    double temperature;
    double magnitude;
    double inclination;
    int calibration;
} CLHeadingInternalStruct;

@interface CLHeading(Private)

- (id)initWithClientHeading:(CLHeadingInternalStruct)arg1;

@end