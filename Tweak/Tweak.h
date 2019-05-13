#import "RLCLocationManagerDelegate.h"

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