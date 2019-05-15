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

@end

typedef struct CLHeadingInternalStruct {
    double x1;
    double x2;
    double x3;
    double x4;
    double x5;
    double x6;
    double x7;
    double x8;
    double x9;
    double x10;
    int x11;
} CLHeadingInternalStruct;

@interface CLHeading(Private)

- (id)initWithClientHeading:(CLHeadingInternalStruct)arg1;

@end