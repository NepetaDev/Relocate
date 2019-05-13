#import "RLCAppListController.h"
#import "RLCAppSettingsController.h"
#import "os/lock.h"
#import "CoreLocation/CLLocationManager.h"

@interface CLLocationManager(Private)

+ (int)_authorizationStatusForBundleIdentifier:(id)arg1 bundle:(id)arg2;

@end

static NSMutableArray *iconsToLoad;
static os_unfair_lock spinLock;
static UIImage *defaultImage;

@implementation RLCAppListController

-(id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        defaultImage = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"];
        _preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        _appList = [NSDictionary new];
        _allSections = @[@"Enabled apps", @"Apps that have requested access to your location", @"Other apps"];
        _apps = [NSMutableArray new];
        _sections = [NSMutableArray new];

        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];

        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];

        [self setTitle:@"Applications"];
        [self.navigationItem setTitle:@"Applications"];
    }

    return self;
}

-(void)reloadApps {
    ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    NSDictionary *allApps = [appList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"(isSystemApplication = NO) OR (isSystemApplication = YES)"] onlyVisible:YES titleSortedIdentifiers:nil];
    NSArray *sortedKeys = [[allApps allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [allApps objectForKey:a];
        NSString *second = [allApps objectForKey:b];
        return [first compare:second];
    }];

    _appList = [allApps copy];
    [_sections removeAllObjects];
    [_apps removeAllObjects];
    NSMutableArray *_activatedApps = [NSMutableArray new];
    NSMutableArray *_clientApps = [NSMutableArray new];
    NSMutableArray *_otherApps = [NSMutableArray new];
    
    for (NSString *key in sortedKeys) {
        if ([_preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", key]]) {
            if ([[_preferences objectForKey:[NSString stringWithFormat:@"App_%@_Enabled", key]] intValue] > 0) {
                [_activatedApps addObject: key];
                continue;
            }
        }

        if ([CLLocationManager _authorizationStatusForBundleIdentifier:key bundle:nil] > 0) {
            [_clientApps addObject: key];
            continue;
        }

        [_otherApps addObject: key];
    }

    if ([_activatedApps count] > 0) {
        [_sections addObject:_allSections[0]];
        [_apps addObject:_activatedApps];
    }

    if ([_clientApps count] > 0) {
        [_sections addObject:_allSections[1]];
        [_apps addObject:_clientApps];
    }

    if ([_otherApps count] > 0) {
        [_sections addObject:_allSections[2]];
        [_apps addObject:_otherApps];
    }

    [self performSelectorOnMainThread:@selector(reloadTable) withObject:nil waitUntilDone:NO];
}

-(void)reloadTable {
    [_tableView reloadData];
}

-(id)view {
    return _tableView;
}

-(void)viewWillAppear:(BOOL)animated {
    [self performSelectorInBackground:@selector(reloadApps) withObject:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *bundleIdentifier = _apps[indexPath.section][indexPath.row];
    if (!bundleIdentifier) return;

    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:_appList[bundleIdentifier]
                                target:nil
                                set:nil
                                get:nil
                                detail:[RLCAppSettingsController class]
                                cell:2
                                edit:nil];
    [specifier setProperty:bundleIdentifier forKey:@"key"];
    RLCAppSettingsController *controller = [[RLCAppSettingsController alloc] init];
    controller.specifier = specifier;
    [self.navigationController pushViewController:controller animated:YES];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_sections count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

-(NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [_apps[section] count];
}

-(void)loadIcons {
    os_unfair_lock_lock(&spinLock);
    ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    while ([iconsToLoad count]) {
        NSString *userInfo = [iconsToLoad objectAtIndex:0];
        [iconsToLoad removeObjectAtIndex:0];
        os_unfair_lock_unlock(&spinLock);
        CGImageRelease([appList copyIconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:userInfo]);
        os_unfair_lock_lock(&spinLock);
    }
    [self performSelectorOnMainThread:@selector(reloadTable) withObject:nil waitUntilDone:NO];
    iconsToLoad = nil;
    os_unfair_lock_unlock(&spinLock);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    
    NSString *bundleIdentifier = _apps[indexPath.section][indexPath.row];
    if (!bundleIdentifier) return nil;

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = _appList[bundleIdentifier];
    cell.indentationWidth = 10.0f;
    cell.indentationLevel = 0;
    if (indexPath.section == 0 && [_sections[0] isEqualToString:_allSections[0]]) cell.accessoryType = UITableViewCellAccessoryCheckmark;

    ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    if ([appList hasCachedIconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:bundleIdentifier]) {
        cell.imageView.image = [appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:bundleIdentifier];
    } else {
        cell.imageView.image = defaultImage;
        os_unfair_lock_lock(&spinLock);
        if (iconsToLoad)
            [iconsToLoad insertObject:bundleIdentifier atIndex:0];
        else {
            iconsToLoad = [[NSMutableArray alloc] initWithObjects:bundleIdentifier, nil];
            [self performSelectorInBackground:@selector(loadIcons) withObject:nil];
        }
        os_unfair_lock_unlock(&spinLock);
    }
    return cell;
}

@end