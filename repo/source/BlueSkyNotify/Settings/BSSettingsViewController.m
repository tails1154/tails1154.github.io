#import <UIKit/UIKit.h>

@interface BSSettingsViewController : UIViewController
@property (nonatomic, retain) UITextField *handleField;
@property (nonatomic, retain) UITextField *passwordField;
@property (nonatomic, retain) UISwitch *statusSwitch;
@end

static NSString *const BSPreferencesID = @"com.tails1154.bluesky.notify";

@implementation BSSettingsViewController
@synthesize handleField = _handleField, passwordField = _passwordField, statusSwitch = _statusSwitch;
- (id)preferenceValue:(NSString *)key { return [(id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)BSPreferencesID) autorelease]; }
- (void)setPreferenceValue:(id)value forKey:(NSString *)key { CFPreferencesSetAppValue((CFStringRef)key, (CFPropertyListRef)value, (CFStringRef)BSPreferencesID); CFPreferencesAppSynchronize((CFStringRef)BSPreferencesID); }
- (id)init { if ((self = [super init])) self.title = @"BlueSkyNotifier Settings"; return self; }
- (void)loadView {
    UIView *view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]; view.backgroundColor = [UIColor colorWithRed:0.82 green:0.85 blue:0.89 alpha:1.0]; self.view = view;
    UILabel *info = [[[UILabel alloc] initWithFrame:CGRectMake(20, 18, 440, 46)] autorelease]; info.text = @"Configure the SpringBoard notification monitor. Use a Bluesky App Password."; info.numberOfLines = 2; info.font = [UIFont systemFontOfSize:14.0]; info.backgroundColor = [UIColor clearColor]; [view addSubview:info];
    self.handleField = [[[UITextField alloc] initWithFrame:CGRectMake(20, 80, 440, 42)] autorelease]; self.handleField.borderStyle = UITextBorderStyleRoundedRect; self.handleField.placeholder = @"Handle (you.bsky.social)"; self.handleField.autocapitalizationType = UITextAutocapitalizationTypeNone; self.handleField.autocorrectionType = UITextAutocorrectionTypeNo; [view addSubview:self.handleField];
    self.passwordField = [[[UITextField alloc] initWithFrame:CGRectMake(20, 132, 440, 42)] autorelease]; self.passwordField.borderStyle = UITextBorderStyleRoundedRect; self.passwordField.placeholder = @"App Password"; self.passwordField.secureTextEntry = YES; self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone; [view addSubview:self.passwordField];
    UILabel *statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 190, 250, 32)] autorelease]; statusLabel.text = @"Show launch status"; statusLabel.backgroundColor = [UIColor clearColor]; [view addSubview:statusLabel];
    id value = [self preferenceValue:@"showStatus"]; self.statusSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(360, 184, 80, 40)] autorelease]; self.statusSwitch.on = !value || [value boolValue]; [view addSubview:self.statusSwitch];
    UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect]; save.frame = CGRectMake(20, 245, 210, 44); [save setTitle:@"Save Settings" forState:UIControlStateNormal]; [save addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside]; [view addSubview:save];
    UIButton *test = [UIButton buttonWithType:UIButtonTypeRoundedRect]; test.frame = CGRectMake(250, 245, 210, 44); [test setTitle:@"Test Connection" forState:UIControlStateNormal]; [test addTarget:self action:@selector(testConnection) forControlEvents:UIControlEventTouchUpInside]; [view addSubview:test];
    NSString *handle = [self preferenceValue:@"handle"]; if ([handle length]) self.handleField.text = handle;
}
- (void)save {
    NSString *handle = [self.handleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self setPreferenceValue:handle forKey:@"handle"]; [self setPreferenceValue:self.passwordField.text ?: @"" forKey:@"appPassword"]; [self setPreferenceValue:[NSNumber numberWithBool:self.statusSwitch.on] forKey:@"showStatus"];
    UIAlertView *a = [[[UIAlertView alloc] initWithTitle:@"Saved" message:@"Settings saved. Restart SpringBoard to reload the tweak." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease]; [a show];
}
- (void)testConnection {
    [self save];
    NSString *handle = [self.handleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; NSString *password = self.passwordField.text;
    if (![handle length] || ![password length]) { UIAlertView *a = [[[UIAlertView alloc] initWithTitle:@"Missing credentials" message:@"Enter your handle and App Password first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease]; [a show]; return; }
    NSURL *url = [NSURL URLWithString:@"https://bsky.social/xrpc/com.atproto.server.createSession"]; NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0]; [request setHTTPMethod:@"POST"]; [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:handle, @"identifier", password, @"password", nil] options:0 error:nil]];
    [NSURLConnection sendAsynchronousRequest:request queue:[[[NSOperationQueue alloc] init] autorelease] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary *json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil; NSString *jwt = [json objectForKey:@"accessJwt"];
        dispatch_async(dispatch_get_main_queue(), ^{ if ([jwt length]) { [self setPreferenceValue:jwt forKey:@"accessJwt"]; if ([json objectForKey:@"refreshJwt"]) [self setPreferenceValue:[json objectForKey:@"refreshJwt"] forKey:@"refreshJwt"]; UIAlertView *a = [[[UIAlertView alloc] initWithTitle:@"Logged in" message:@"Connection test succeeded." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease]; [a show]; } else { UIAlertView *a = [[[UIAlertView alloc] initWithTitle:@"Failed to login" message:[json objectForKey:@"message"] ?: [error localizedDescription] ?: @"Check your credentials and connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease]; [a show]; } });
    }];
}
- (void)dealloc { [_handleField release]; [_passwordField release]; [_statusSwitch release]; [super dealloc]; }
@end
