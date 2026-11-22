#import <Preferences/PSListController.h>

@interface BlueSkyNotifyRootListController : PSListController
@end

@implementation BlueSkyNotifyRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
    return _specifiers;
}
- (void)saveSettings:(id)specifier {
    CFPreferencesAppSynchronize(CFSTR("com.tails1154.bluesky.notify"));
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Saved" message:@"BlueSkyNotifier settings saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}
@end
