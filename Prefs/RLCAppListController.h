
#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#import <AppList/AppList.h>

@interface RLCAppListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    HBPreferences *_preferences;
    NSDictionary *_appList;
    NSArray *_allSections;
    NSMutableArray *_sections;
    NSMutableArray *_apps;
    int _lastSectionCount;
}

-(void)loadIcons;
-(void)reloadApps;

@end