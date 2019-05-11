#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface RLCLocationPickerAdvancedSettingsListViewController : PSListController {
    UITableView * _table;
}

-(UITableView *)table;

@end