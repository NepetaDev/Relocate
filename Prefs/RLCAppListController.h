
#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#import <AppList/AppList.h>

@interface RLCAppListController : PSViewController <UITableViewDelegate> {
    UITableView *_tableView;
    ALApplicationTableDataSource *_dataSource;
    HBPreferences *_preferences;
}


@end