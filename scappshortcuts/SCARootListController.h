#import <Preferences/PSListController.h>
#import <Preferences/PSViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AppList/AppList.h>

@interface SCARootListController : PSListController <MFMailComposeViewControllerDelegate>

@end


@interface SCAAppsListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	ALApplicationList *_applicationList;
	BOOL _isPortrait;
	UIBarButtonItem *_enableAll;
	UIBarButtonItem *_disableAll;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *enabledApplications;
@property (nonatomic, strong) NSMutableArray *disabledApplications;
@property (nonatomic, strong) NSMutableArray *allApplications;
@property (nonatomic, strong) NSDictionary *prefs;
@end

@interface SCAPortraitAppsListController : SCAAppsListController

@end

@interface SCALandscapeAppsListController : SCAAppsListController

@end