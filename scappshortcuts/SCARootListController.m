#include "SCARootListController.h"

@interface ALApplicationList (SCAPrivate)
-(NSArray *)_hiddenDisplayIdentifiers;
@end

#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.scappshortcuts.plist"

@implementation SCARootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)email {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"SCAppShortcuts Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:kSettingsPath] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		system("/usr/bin/dpkg -l > /tmp/dpkgl.log");
		#pragma GCC diagnostic pop
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

- (void)mailComposeController:(id)controller didFinishWithResult:(MFMailComposeResult)result error:(id)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DGhost"]];
}

- (void)follow {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

@end


@implementation SCAAppsListController

- (id)init {
	self = [super init];

	if (self != nil) {
		_applicationList = [ALApplicationList sharedApplicationList];

		NSArray *allDisplayIdentifiers = nil;
		[_applicationList applicationsFilteredUsingPredicate:nil onlyVisible:YES titleSortedIdentifiers:&allDisplayIdentifiers];
		
		self.allApplications = [NSMutableArray array];
		[self.allApplications addObjectsFromArray:allDisplayIdentifiers];
		[self.allApplications removeObjectsInArray:[_applicationList _hiddenDisplayIdentifiers]];
	}

	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SCAppShortcutsCell"];
	[self.tableView setEditing:YES];
	[self.tableView setAllowsSelection:NO];

	self.prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kSettingsPath] ?: [NSMutableDictionary dictionary];
	[self updateArrays];

	_enableAll = [[UIBarButtonItem alloc] initWithTitle:@"Enable All" style:UIBarButtonItemStylePlain target:self action:@selector(enableAll:)];
	_disableAll = [[UIBarButtonItem alloc] initWithTitle:@"Disable All" style:UIBarButtonItemStylePlain target:self action:@selector(disableAll:)];

	if ([self.enabledApplications count] == 0)
		_disableAll.enabled = NO;

	if ([self.disabledApplications count] == 0)
		_enableAll.enabled = NO;

	self.navigationItem.rightBarButtonItems = @[_enableAll, _disableAll];

	self.view = self.tableView;
}

- (void)dealloc {
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	[self.tableView release];
	[_enableAll release];
	[_disableAll release];
	[super dealloc];
}

- (void)enableAll:(UIBarButtonItem *)button {
	self.enabledApplications = [NSMutableArray array];
	[self.enabledApplications addObjectsFromArray:self.allApplications];
	self.disabledApplications = [NSMutableArray array];

	_enableAll.enabled = NO;
	_disableAll.enabled = YES;

	[self writeToFile];
	[self.tableView reloadData];
}

- (void)disableAll:(UIBarButtonItem *)button {
	self.enabledApplications = [NSMutableArray array];
	self.disabledApplications = [NSMutableArray array];
	[self.disabledApplications addObjectsFromArray:self.allApplications];

	_enableAll.enabled = YES;
	_disableAll.enabled = NO;

	[self writeToFile];
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Enabled";
		case 1:
			return @"Disabled";
		default:
			return @"";
	}
}

- (NSMutableArray *)arrayForSection:(NSInteger)section {
	switch (section) {
		case 0:
			return self.enabledApplications;
		case 1:
			return self.disabledApplications;
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSMutableArray *array = [self arrayForSection:section];
	return array == nil ? 0 : [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SCAppShortcutsCell" forIndexPath:indexPath];
	NSMutableArray *array = [self arrayForSection:indexPath.section];

	if (array == nil || [array count] <= indexPath.row)
		return nil;

	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SCAppShortcutsCell"];

	NSString *currentIdentifier = [array objectAtIndex:indexPath.row];
	cell.textLabel.text = [_applicationList valueForKey:@"displayName" forDisplayIdentifier:currentIdentifier];
	cell.imageView.image = [_applicationList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:currentIdentifier];

	return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (self.tableView == nil)
		return;

	if (sourceIndexPath == nil || destinationIndexPath == nil) {
		[self.tableView reloadData];
		return;
	}

	NSMutableArray *fromArray = [self arrayForSection:sourceIndexPath.section];
	NSMutableArray *toArray = [self arrayForSection:destinationIndexPath.section];

	if (fromArray == nil || toArray == nil) {
		[self updateArrays];
		[self.tableView reloadData];
		return;
	}

	if (sourceIndexPath.row >= [fromArray count]) {
		[self.tableView reloadData];
		return;
	}

	NSString *objectToMove = [fromArray objectAtIndex:sourceIndexPath.row];
	[fromArray removeObjectAtIndex:sourceIndexPath.row];
	[toArray insertObject:objectToMove atIndex:destinationIndexPath.row];

	//[self writeToFile];
	[self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (void)removeDuplicates {
	NSMutableArray *array = [NSMutableArray array];

	if (self.enabledApplications != nil && [self.enabledApplications count] > 0) {
		NSMutableArray *newEnabledApplications = [NSMutableArray array];
		for (id object in self.enabledApplications) {
			if (![array containsObject:object]) {
				[array addObject:object];
				[newEnabledApplications addObject:object];
			}
		}
		self.enabledApplications = newEnabledApplications;
	}

	if (self.disabledApplications != nil && [self.disabledApplications count] > 0) {
		NSMutableArray *newDisabledApplications = [NSMutableArray array];
		for (id object in self.disabledApplications) {
			if (![array containsObject:object]) {
				[array addObject:object];
				[newDisabledApplications addObject:object];
			}
		}
		self.disabledApplications = newDisabledApplications;
	}

	for (id object in self.allApplications)
		if (![array containsObject:object])
			[self.disabledApplications addObject:object];
}

- (void)writeToFile {
	[self removeDuplicates];

	PSSpecifier *enabledApplicationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSLinkListCell edit:nil];
	[enabledApplicationsSpecifier setProperty:_isPortrait ? @"portraitEnabledApplications" : @"landscapeEnabledApplications" forKey:@"key"];
	[enabledApplicationsSpecifier setProperty:@"com.dgh0st.scappshortcuts" forKey:@"defaults"];
	[self setPreferenceValue:self.enabledApplications specifier:enabledApplicationsSpecifier];

	PSSpecifier *disabledApplicationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSLinkListCell edit:nil];
	[disabledApplicationsSpecifier setProperty:_isPortrait ? @"portraitDisabledApplications" : @"landscapeDisabledApplications" forKey:@"key"];
	[disabledApplicationsSpecifier setProperty:@"com.dgh0st.scappshortcuts" forKey:@"defaults"];
	[self setPreferenceValue:self.disabledApplications specifier:disabledApplicationsSpecifier];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.dgh0st.scappshortcuts/settingschanged"), NULL, NULL, YES);
}

- (void)updateArrays {
	if (self.prefs != nil) {
		self.enabledApplications = (NSMutableArray *)[self.prefs objectForKey:_isPortrait ? @"portraitEnabledApplications" : @"landscapeEnabledApplications"];
		self.disabledApplications = (NSMutableArray *)[self.prefs objectForKey:_isPortrait ? @"portraitDisabledApplications" : @"landscapeDisabledApplications"];
	}

	if (self.prefs == nil || (self.enabledApplications == nil && self.disabledApplications == nil)) {
		self.enabledApplications = [NSMutableArray array];
		[self.enabledApplications addObjectsFromArray:self.allApplications];
		self.disabledApplications = [NSMutableArray array];
	}

	if (self.enabledApplications == nil)
		self.enabledApplications = [NSMutableArray array];

	if (self.disabledApplications == nil)
		self.disabledApplications = [NSMutableArray array];

	[self removeDuplicates];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self writeToFile];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self updateArrays];
}

@end


@implementation SCAPortraitAppsListController

- (id)init {
	self = [super init];

	if (self != nil) {
		_isPortrait = YES;
	}

	return self;
}

@end


@implementation SCALandscapeAppsListController

- (id)init {
	self = [super init];

	if (self != nil) {
		_isPortrait = NO;
	}

	return self;
}

@end