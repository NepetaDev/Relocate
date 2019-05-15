#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#import "NSTask.h"

@interface RLCSystemServicesListController : HBRootListController
    - (void)restartFMF:(id)sender;
    - (void)restartFMI:(id)sender;
@end