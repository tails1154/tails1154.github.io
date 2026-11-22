#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

static NSTimer *BSNotifyTimer;
static NSInteger BSLastUnreadCount = -1;
static BOOL BSLoggingIn;
static BOOL BSConnectionReported;
static BOOL BSLoginStatusReported;
static void BSSendStatus(NSString *title, NSString *message);

%hook PSListController
- (void)saveSettings:(id)specifier {
    CFPreferencesAppSynchronize(CFSTR("com.tails1154.bluesky.notify"));
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Saved" message:@"BlueSkyNotifier settings saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}
- (void)sendTestNotification:(id)specifier {
    BSSendStatus(@"BlueSkyNotifier", @"Test notification succeeded.");
}
%end

static BOOL BSStatusEnabled(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist"];
    NSNumber *enabled = [prefs objectForKey:@"showStatus"];
    return !enabled || [enabled boolValue];
}

static void BSSendStatus(NSString *title, NSString *message) {
    if (!BSStatusEnabled()) return;
    Class serverClass = NSClassFromString(@"BBServer");
    Class bulletinClass = NSClassFromString(@"BBBulletin");
    if (!serverClass || !bulletinClass) return;
    id server = nil;
    NSArray *serverSelectors = [NSArray arrayWithObjects:@"sharedInstance", @"sharedServer", @"defaultServer", nil];
    for (NSString *name in serverSelectors) {
        SEL selector = NSSelectorFromString(name);
        if ([serverClass respondsToSelector:selector]) { id (*getServer)(id, SEL) = (id (*)(id, SEL))objc_msgSend; server = getServer(serverClass, selector); if (server) break; }
    }
    if (!server) server = [[[serverClass alloc] init] autorelease];
    id bulletin = [[[bulletinClass alloc] init] autorelease];
    [bulletin setValue:title forKey:@"title"];
    [bulletin setValue:message forKey:@"message"];
    [bulletin setValue:@"com.tails1154.bluesky" forKey:@"sectionID"];
    [bulletin setValue:[NSString stringWithFormat:@"bluesky-status-%ld", (long)[[NSDate date] timeIntervalSince1970]] forKey:@"bulletinID"];
    SEL publish = NSSelectorFromString(@"publishBulletin:destinations:");
    if ([server respondsToSelector:publish]) {
        void (*send)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))objc_msgSend;
        send(server, publish, bulletin, 15);
    }
}

static NSMutableDictionary *BSStoredSession(void) {
    NSDictionary *appSession = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.plist"];
    NSDictionary *tweakSession = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist"];
    NSMutableDictionary *session = [NSMutableDictionary dictionaryWithDictionary:appSession ?: [NSDictionary dictionary]];
    NSString *jwt = [tweakSession objectForKey:@"accessJwt"];
    if ([jwt length]) [session setObject:jwt forKey:@"accessJwt"];
    return session;
}

static void BSLoginFromPreferences(void (^completion)(NSString *)) {
    if (BSLoggingIn) return;
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist"];
    NSString *handle = [prefs objectForKey:@"handle"];
    NSString *password = [prefs objectForKey:@"appPassword"];
    if (![handle length] || ![password length]) { BSSendStatus(@"BlueSkyNotifier", @"Failed to login."); if (completion) completion(nil); return; }
    BSLoggingIn = YES;
    NSURL *url = [NSURL URLWithString:@"https://bsky.social/xrpc/com.atproto.server.createSession"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:handle, @"identifier", password, @"password", nil] options:0 error:nil]];
    [NSURLConnection sendAsynchronousRequest:request queue:[[[NSOperationQueue alloc] init] autorelease] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary *json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSString *jwt = [json objectForKey:@"accessJwt"];
        if ([jwt length]) {
            NSMutableDictionary *saved = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist"] ?: [NSDictionary dictionary]];
            [saved setObject:jwt forKey:@"accessJwt"];
            [saved writeToFile:@"/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist" atomically:YES];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ BSLoggingIn = NO; BSSendStatus(@"BlueSkyNotifier", [jwt length] ? @"Logged in." : @"Failed to login."); if (completion) completion(jwt); });
    }];
}

static void BSSendSpringBoardAlert(NSInteger unreadCount) {
    Class serverClass = NSClassFromString(@"BBServer");
    Class bulletinClass = NSClassFromString(@"BBBulletin");
    if (!serverClass || !bulletinClass) return;
    id server = nil;
    NSArray *serverSelectors = [NSArray arrayWithObjects:@"sharedInstance", @"sharedServer", @"defaultServer", nil];
    for (NSString *name in serverSelectors) {
        SEL selector = NSSelectorFromString(name);
        if ([serverClass respondsToSelector:selector]) { id (*getServer)(id, SEL) = (id (*)(id, SEL))objc_msgSend; server = getServer(serverClass, selector); if (server) break; }
    }
    if (!server) server = [[[serverClass alloc] init] autorelease];
    id bulletin = [[[bulletinClass alloc] init] autorelease];
    [bulletin setValue:@"Bluesky" forKey:@"title"];
    [bulletin setValue:(unreadCount == 1 ? @"You have 1 new notification." : [NSString stringWithFormat:@"You have %ld new notifications.", (long)unreadCount]) forKey:@"message"];
    [bulletin setValue:@"com.tails1154.bluesky" forKey:@"sectionID"];
    [bulletin setValue:[NSString stringWithFormat:@"bluesky-%ld", (long)[[NSDate date] timeIntervalSince1970]] forKey:@"bulletinID"];
    SEL publish = NSSelectorFromString(@"publishBulletin:destinations:");
    if ([server respondsToSelector:publish]) {
        void (*send)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))objc_msgSend;
        send(server, publish, bulletin, 15);
    }
}

static void BSPollUnreadNotifications(void) {
    NSDictionary *session = BSStoredSession();
    NSString *jwt = [session objectForKey:@"accessJwt"];
    if (![jwt length]) { BSLoginFromPreferences(^(NSString *newJWT) { if ([newJWT length]) BSPollUnreadNotifications(); }); return; }
    if (!BSLoginStatusReported) { BSSendStatus(@"BlueSkyNotifier", @"Logged in."); BSLoginStatusReported = YES; }
    NSURL *url = [NSURL URLWithString:@"https://bsky.social/xrpc/app.bsky.notification.getUnreadCount"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", jwt] forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:request queue:[[[NSOperationQueue alloc] init] autorelease] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error || !data) { BSSendStatus(@"BlueSkyNotifier", @"Failed to login."); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSNumber *count = [json objectForKey:@"count"];
        if (![count isKindOfClass:[NSNumber class]]) return;
        NSInteger current = [count integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!BSConnectionReported) { BSSendStatus(@"BlueSkyNotifier", @"Waiting for notifications."); BSConnectionReported = YES; }
            if (BSLastUnreadCount >= 0 && current > BSLastUnreadCount) BSSendSpringBoardAlert(current - BSLastUnreadCount);
            BSLastUnreadCount = current;
        });
    }];
}

%ctor {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.apple.springboard"]) return;
    BSSendStatus(@"BlueSkyNotifier", @"Loaded BlueSkyNotifier.");
    BSNotifyTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:[NSBlockOperation blockOperationWithBlock:^{ BSPollUnreadNotifications(); }] selector:@selector(main) userInfo:nil repeats:YES];
    BSPollUnreadNotifications();
}
