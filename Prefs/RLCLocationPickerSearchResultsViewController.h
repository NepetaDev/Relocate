#import <MapKit/MapKit.h>

@interface RLCLocationPickerSearchResultsViewController : UITableViewController <UISearchResultsUpdating>

@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) UIViewController *parentController;
@property (nonatomic, assign) BOOL allowDeletion;

@end