#import "RLCAppListController.h"
#import "RLCAppSettingsController.h"

@implementation RLCAppListController

-(id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        _preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];

        _dataSource = [[ALApplicationTableDataSource alloc] init];
        _dataSource.sectionDescriptors = [ALApplicationTableDataSource standardSectionDescriptors];

        [_tableView setDataSource:_dataSource];
        _dataSource.tableView = _tableView;

        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];

        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];        
    }

    return self;
}

-(id)view {
    return _tableView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.accessoryType = UITableViewCellAccessoryNone;

    NSString *displayIdentifier = [_dataSource displayIdentifierForIndexPath:indexPath];
    if ([_preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", displayIdentifier]]) {
        if ([[_preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", displayIdentifier]] intValue] > 0) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [_tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *displayIdentifier = [_dataSource displayIdentifierForIndexPath:indexPath];
    ALApplicationList *al = [ALApplicationList sharedApplicationList];

    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:[al.applications objectForKey:displayIdentifier]
                                target:nil
                                set:nil
                                get:nil
                                detail:[RLCAppSettingsController class]
                                cell:2
                                edit:nil];
    [specifier setProperty:displayIdentifier forKey:@"key"];
    RLCAppSettingsController *controller = [[RLCAppSettingsController alloc] init];
    controller.specifier = specifier;
    [self.navigationController pushViewController:controller animated:YES];
}

@end