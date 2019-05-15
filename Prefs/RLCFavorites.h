#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>

@interface RLCFavorites : PSViewController <UITableViewDelegate,UITableViewDataSource> {
    UITableView *_tableView;
}

@property (nonatomic, retain) NSMutableArray *favorites;
@property (nonatomic, retain) UIBarButtonItem *editButton;
- (void)refreshList;

@end