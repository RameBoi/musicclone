#import <UIKit/UIKit.h>
#import "MCCore.h"
#import "MCViews.h"

@interface MCAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation MCAppDelegate

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    AVAudioSession *s = [AVAudioSession sharedInstance];
    [s setCategory:AVAudioSessionCategoryPlayback error:nil];
    [s setActive:YES error:nil];
    [MCPlayer shared];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[MCRootVC alloc] init];
    [self.window makeKeyAndVisible];
    [[MCLibrary shared] reload];
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([MCAppDelegate class]));
    }
}
