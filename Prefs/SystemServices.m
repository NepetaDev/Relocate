#import "SystemServices.h"

@implementation RLCSystemServicesListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"SystemServices" target:self];
    }
    return _specifiers;
}

- (void)restartFMF:(id)sender {
    NSTask *t = [[NSTask alloc] init];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:[NSArray arrayWithObjects:@"-9", @"fmfd", nil]];
    [t launch];

    NSTask *t2 = [[NSTask alloc] init];
    [t2 setLaunchPath:@"/usr/bin/killall"];
    [t2 setArguments:[NSArray arrayWithObjects:@"-9", @"fmflocatord", nil]];
    [t2 launch];
}

- (void)restartFMI:(id)sender {
    NSTask *t = [[NSTask alloc] init];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:[NSArray arrayWithObjects:@"-9", @"findmydeviced", nil]];
    [t launch];
}

@end