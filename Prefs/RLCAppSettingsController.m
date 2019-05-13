#include "RLCAppSettingsController.h"

@implementation RLCAppSettingsController

- (id)specifiers {
    return _specifiers;
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
    NSString *title = [specifier name];
    NSString *bundle = [specifier propertyForKey:@"key"];

    _specifiers = [self loadSpecifiersFromPlistName:@"AppSettings" target:self];

    for (PSSpecifier *specifier in _specifiers) {
        NSString *key = [specifier propertyForKey:@"key"];
        if (key) {
            [specifier setProperty:[NSString stringWithFormat:@"App_%@_%@", bundle, key] forKey:@"key"];
        }

        [self reloadSpecifier:specifier];
    }

    [self setTitle:title];
    [self.navigationItem setTitle:title];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    [self loadFromSpecifier:specifier];
    [super setSpecifier:specifier];
}

- (bool)shouldReloadSpecifiersOnResume {
    return false;
}

@end