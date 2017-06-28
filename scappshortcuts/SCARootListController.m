#include "SCARootListController.h"

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