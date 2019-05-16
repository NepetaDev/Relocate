#import "RLCLocationPickerAdvancedSettingsListViewController.h"
#import "RLCLocationPickerViewController.h"

@implementation RLCLocationPickerAdvancedSettingsListViewController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"AdvancedSettings" target:self];
    }
    return _specifiers;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self setBackgroundColor:[UIColor clearColor]];
    self.view.layer.masksToBounds = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [_table setBackgroundColor:[UIColor clearColor]];
    _table.layer.backgroundColor = [UIColor clearColor].CGColor;
}

-(id)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(id)arg2 {
    [arg1 setBackgroundColor:[UIColor clearColor]];
    arg1.layer.backgroundColor = [UIColor clearColor].CGColor;
    return [super tableView:arg1 cellForRowAtIndexPath:arg2];
}

-(UITableView *)table {
    return _table;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    if ([specifier propertyForKey:@"defaults"]) return [super readPreferenceValue:specifier];
    if (![specifier propertyForKey:@"key"]) return [specifier propertyForKey:@"default"];

    RLCLocationPickerViewController *parent = (RLCLocationPickerViewController *)self.parentViewController;

    if (parent && parent.dictionary && parent.dictionary[[specifier propertyForKey:@"key"]]) {
        return parent.dictionary[[specifier propertyForKey:@"key"]];
    }

    return [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    if (![specifier propertyForKey:@"key"]) return;
    if ([specifier propertyForKey:@"defaults"]) [super setPreferenceValue:value specifier:specifier];

    RLCLocationPickerViewController *parent = (RLCLocationPickerViewController *)self.parentViewController;

    if ([[specifier propertyForKey:@"key"] isEqualToString:@"MapType"]) {
        switch ([value intValue]) {
            case 1:
                parent.lpView.mapView.mapType = MKMapTypeSatellite;
                break;
            case 2:
                parent.lpView.mapView.mapType = MKMapTypeHybrid;
                break;
            default:
                parent.lpView.mapView.mapType = MKMapTypeStandard;
        }
        return;
    }

    if (parent && parent.dictionary) {
        parent.dictionary[[specifier propertyForKey:@"key"]] = value;
    }
}

@end