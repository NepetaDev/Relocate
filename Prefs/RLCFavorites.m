#import "RLCFavorites.h"
#define BUNDLE_ID @"me.nepeta.relocate"

@implementation RLCFavorites

- (id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        self.favorites = [NSMutableArray new];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];

        self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" 
                            style:UIBarButtonItemStylePlain
                            target:self 
                            action:@selector(toggleEditing:)];
        self.editButton.tintColor = [UIColor blackColor];
        self.navigationItem.rightBarButtonItem = self.editButton;
        
        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];
    }

    return self;
}

- (void)toggleEditing:(id)sender {
    if ([_tableView isEditing]) {
        [self.editButton setTitle:@"Edit"];
    } else {
        [self.editButton setTitle:@"Confirm"];
    }
    [_tableView setEditing:![_tableView isEditing]];
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
    NSString *title = [specifier name];
    [self setTitle:title];
    [self.navigationItem setTitle:title];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    [self loadFromSpecifier:specifier];
    [super setSpecifier:specifier];
}

- (void)refreshList {
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    self.favorites = [file objectForKey:@"Favorites"];
    [_tableView reloadData];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"me.nepeta.relocate/ReloadPrefs", nil, nil, true);
}

- (id)view {
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self refreshList];
}

- (NSString*)navigationTitle {
    return @"Favorites";
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favorites.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingsCell"];
    }
    
    NSDictionary *favorite = [self.favorites objectAtIndex:indexPath.row];
    cell.textLabel.text = favorite[@"Name"];    
    cell.selected = NO;

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //NSDictionary *favorite = (NSDictionary*)[self.favorites objectAtIndex:indexPath.row];

    //location preview?
    //[self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    NSMutableArray *favorites = nil;

    if ([prefs objectForKey:@"Favorites"]) {
        favorites = [[prefs objectForKey:@"Favorites"] mutableCopy];
        NSMutableDictionary *dictionary = favorites[sourceIndexPath.row];
        [favorites removeObjectAtIndex:sourceIndexPath.row];
        [favorites insertObject:dictionary atIndex:destinationIndexPath.row];
    } else {
        favorites = [@[] mutableCopy];
    }

    [prefs setObject:favorites forKey:@"Favorites"];
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *renameAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Rename" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSDictionary *favorite = (NSDictionary*)[self.favorites objectAtIndex:indexPath.row];
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Favorites"
            message:@"Enter name"
            preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action){
                HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    
                NSMutableArray *favorites = nil;

                if ([prefs objectForKey:@"Favorites"]) {
                    favorites = [[prefs objectForKey:@"Favorites"] mutableCopy];
                    NSMutableDictionary *dictionary = [favorites[indexPath.row] mutableCopy];
                    dictionary[@"Name"] = [alert.textFields[0] text];
                    favorites[indexPath.row] = dictionary;
                } else {
                    favorites = [@[] mutableCopy];
                }

                [prefs setObject:favorites forKey:@"Favorites"];
                [self refreshList];
            }
        ];
        
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }
        ];

        [alert addAction:ok];
        [alert addAction:cancel];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Name";
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.text = favorite[@"Name"];
        }];

        [self presentViewController:alert animated:YES completion:nil];
    }];
    renameAction.backgroundColor = [UIColor colorWithRed:0.27 green:0.47 blue:0.56 alpha:1.0];

    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
        
        NSMutableArray *favorites = nil;

        if ([prefs objectForKey:@"Favorites"]) {
            favorites = [[prefs objectForKey:@"Favorites"] mutableCopy];
            [favorites removeObjectAtIndex:indexPath.row];
        } else {
            favorites = [@[] mutableCopy];
        }

        [prefs setObject:favorites forKey:@"Favorites"];
        [self refreshList];
    }];
    deleteAction.backgroundColor = [UIColor redColor];

    return @[deleteAction, renameAction];
}

@end