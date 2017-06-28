#import <AppList/AppList.h>
#import <Preferences/Preferences.h>

#define identifier @"com.dgh0st.scappshortcuts"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.scappshortcuts.plist"
#define kSectionName @"App Shortcuts"

// make sure to place SwitcherControls.dylib in theos's lib folder and rename it to libSwitcherControls.dylib
@interface ControlCenterSectionView : UIView
@end

@interface ControlCenterSCAppShortcutsView : ControlCenterSectionView <UIScrollViewDelegate>
-(void)setupScrollView;
@end

@interface SCCSectionsListController : PSViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *allSections;
@property (nonatomic, strong) NSMutableArray *hiddenSections;
-(void)updateArrays;
@end

@interface SCPreferences : NSObject
@property (nonatomic, assign) BOOL requiresRelayout;
+(SCPreferences *)sharedInstance;
@end

@interface SpringBoard : UIApplication
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
-(UIInterfaceOrientation)activeInterfaceOrientation;
@end

@interface IconImageView : UIImageView {
	NSString *_identifier;
}
-(id)initWithFrame:(CGRect)frame image:(UIImage *)image displayIdentifier:(NSString *)displayIdentifier;
@end

@implementation IconImageView
-(id)initWithFrame:(CGRect)frame image:(UIImage *)image displayIdentifier:(NSString *)displayIdentifier {
	self = [super initWithFrame:frame];
	if (self != nil) {
		_identifier = displayIdentifier;
		self.image = image;

		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iconPressed:)];
		[tap setNumberOfTouchesRequired:1];
		[self addGestureRecognizer:tap];

		self.userInteractionEnabled = YES;

		[tap release];
	}
	return self;
}

-(void)iconPressed:(id)sender {
	[(SpringBoard *)[%c(SpringBoard) sharedApplication] launchApplicationWithIdentifier:_identifier suspended:NO];
}
@end

// have to do this because SwitcherControls keeps two copies (portrait and landscape, yes I know it can be improved)
NSMutableArray *shortcutsViews = [NSMutableArray array];

NSInteger portraitPerPage = 5;
NSInteger landscapePerPage = -1;

static void preferencesChanged() {
	CFPreferencesAppSynchronize(CFSTR("com.dgh0st.scappshortcuts"));

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)identifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)identifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}

	portraitPerPage = [prefs objectForKey:@"portraitPerPage"] ? [[prefs objectForKey:@"portraitPerPage"] intValue] : 5;
	landscapePerPage = [prefs objectForKey:@"landscapePerPage"] ? [[prefs objectForKey:@"landscapePerPage"] intValue] : -1;

	for (ControlCenterSCAppShortcutsView *shortcutsView in shortcutsViews)
		[shortcutsView setupScrollView];
}

// implement custom section view
// height will always be 64
// width will be either same as width of screen (orientation dependent) or width of screen - 40
@implementation ControlCenterSCAppShortcutsView
-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self != nil) {
		[self setupScrollView];
		[shortcutsViews addObject:self];
	}
	return self;
}

-(void)setupScrollView {
	[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

	// width will be either same as width of screen (orientation dependent) or width of screen - 40
	// so we can take advantage of that to figure out if it is portrait or landscape
	BOOL isLandscape = self.frame.size.width >= [[UIScreen mainScreen] bounds].size.height - 40;

	UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 0, self.frame.size.width - 40, self.frame.size.height)];
	scrollView.delegate = self;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.showsHorizontalScrollIndicator = NO;

	NSArray *sortedDisplayIdentifiers = nil;
	ALApplicationList *applicationList = [ALApplicationList sharedApplicationList];
	[applicationList applicationsFilteredUsingPredicate:nil onlyVisible:YES titleSortedIdentifiers:&sortedDisplayIdentifiers];

	CGFloat padding = 6.55555556;

	NSInteger appNumber = 0;
	NSInteger appsPerPage = isLandscape ? landscapePerPage : portraitPerPage;
	if (appsPerPage != -1) {
		scrollView.pagingEnabled = YES;
		padding = (scrollView.frame.size.width - (appsPerPage * ALApplicationIconSizeLarge)) / (appsPerPage + 1);
	}
	CGFloat widthSoFar = appsPerPage == -1 ? padding : scrollView.frame.size.width;
	CGRect appIconFrame = CGRectMake(padding, (self.frame.size.height - ALApplicationIconSizeLarge) / 2, ALApplicationIconSizeLarge, ALApplicationIconSizeLarge);

	for (NSString *currentIdentifier in sortedDisplayIdentifiers) {
		IconImageView *iconView = [[IconImageView alloc] initWithFrame:appIconFrame image:[applicationList iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:currentIdentifier] displayIdentifier:currentIdentifier];
		[scrollView addSubview:iconView];
		[iconView release];

		appIconFrame.origin.x += appIconFrame.size.width + padding;
		appNumber++;
		if (appsPerPage == -1) {
			widthSoFar += appIconFrame.size.width + padding;
		} else if (appNumber % appsPerPage == 0) {
			appIconFrame.origin.x += padding;
			widthSoFar += scrollView.frame.size.width;
		}
	}

	if (appNumber != -1 && appNumber % appsPerPage == 0)
		widthSoFar -= scrollView.frame.size.width;

	[scrollView setContentSize:CGSizeMake(widthSoFar, self.frame.size.height)];
	[self addSubview:scrollView];

	[scrollView release];
}

-(void)dealloc {
	[shortcutsViews removeObject:self];
	[super 	dealloc];
}
@end

%group all
%hook SCPreferences
-(Class)classForSection:(NSString *)arg1 {
	// return our custom class for our section
	if ([arg1 isEqualToString:kSectionName])
		return [ControlCenterSCAppShortcutsView class];
	return %orig(arg1);
}
%end
%end

%group preferences
%hook PSViewController
-(id)init {
	id result = %orig();
	// yes this is a weird way of doing it...
	if (result != nil && [[result class] isEqual:[%c(SCCSectionsListController) class]]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250), dispatch_get_main_queue(), ^{
			[((SCCSectionsListController *)result).allSections addObject:kSectionName];
			[((SCCSectionsListController *)result).hiddenSections addObject:kSectionName];
			[(SCCSectionsListController *)result updateArrays];
		});
	}
	return result;
}
%end
%end

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("com.dgh0st.scappshortcuts/settingschanged"), NULL);

	[shortcutsViews removeAllObjects];
}

%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, CFSTR("com.dgh0st.scappshortcuts/settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	dlopen("/Library/MobileSubstrate/DynamicLibraries/SwitcherControls.dylib", RTLD_LAZY);
	if (%c(SCPreferences))
		%init(all);

	NSString *currentIdentifier = [NSBundle mainBundle].bundleIdentifier;
	if ([currentIdentifier isEqualToString:@"com.apple.Preferences"])
		%init(preferences);
}