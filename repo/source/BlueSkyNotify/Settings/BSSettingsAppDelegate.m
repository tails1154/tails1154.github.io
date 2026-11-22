#import <UIKit/UIKit.h>

@interface BSSettingsViewController : UIViewController
@end

@interface BSSettingsAppDelegate : NSObject <UIApplicationDelegate>
@property (nonatomic, retain) UIWindow *window;
@end

@implementation BSSettingsAppDelegate
@synthesize window = _window;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:[[[BSSettingsViewController alloc] init] autorelease]] autorelease];
    nav.navigationBar.tintColor = [UIColor colorWithRed:0.10 green:0.32 blue:0.55 alpha:1.0];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}
- (void)dealloc { [_window release]; [super dealloc]; }
@end
