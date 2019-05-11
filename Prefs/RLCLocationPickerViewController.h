
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#import "RLCLocationPickerView.h"
#import "RLCLocationPickerSearchResultsViewController.h"

@interface RLCLocationPickerViewController : PSViewController <UISearchBarDelegate>

@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) RLCLocationPickerSearchResultsViewController *searchResultsController;
@property (nonatomic, retain) UIBarButtonItem *saveButton;
@property (nonatomic, retain) RLCLocationPickerView *lpView;
@property (nonatomic, retain) NSMutableArray *favorites;
@property (nonatomic, retain) NSMutableDictionary *dictionary;
-(void)save:(id)sender;
-(void)updateSavedFavorites;

@end