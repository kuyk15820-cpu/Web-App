#import "MainApplicationDelegate.h"
#import "RootViewController.h"

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    // 1. สร้างและตั้งค่า RootViewController ทันที
    _rootViewController = [[RootViewController alloc] init];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
    navController.navigationBar.prefersLargeTitles = NO;
    navController.navigationBar.translucent = YES;
    
    // 2. กำหนดให้เป็น rootViewController ของ window และแสดงผล
    [self.window setRootViewController:navController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
