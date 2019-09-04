//
//  TPRAppDelegate.m
//  Tweepr
//

#import "TPRAppDelegate.h"
#import "RefreshManager.h"
#import "UserLoadingRoutine.h"
#import "SVProgressHUD.h"

#import "TPRUserProfileViewController.h"
#import "TPRTweetViewController.h"
#import "TPRUnfollowViewController.h"
#import "TPRSettingsViewController.h"
#import "TPRIAPManager.h"

#import <SimpleAuth/SimpleAuth.h>

#import <HockeySDK/HockeySDK.h>

#import <CocoaLumberjack/CocoaLumberjack.h>

//#import <Fabric/Fabric.h>
//#import <Crashlytics/Crashlytics.h>


@interface TPRAppDelegate()

@end

@implementation TPRAppDelegate


#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //[Fabric with:@[CrashlyticsKit]];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"2321d8642e3c16846b8d8a96c6d9775b"];
    [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus:BITCrashManagerStatusAutoSend];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    [SimpleAuth configuration][@"twitter-web"] = @{@"consumer_key": twitterConsumerKey,
                                                   @"consumer_secret" : twitterConsumerSecret
                                                   };
    
    if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)]) {
        [application setMinimumBackgroundFetchInterval:16 * 60]; // UIApplicationBackgroundFetchIntervalMinimum
    }
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];

//    [Flurry startSession:@"CNNH5YCVHZMGPZC72ZJC"];
    NSDate *appFirstInstallDate = [NSDate date];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"shouldShowOneAccountAlert"];
    [defaults setBool:YES forKey:@"shouldShowLimitAlert"];
    [defaults setBool:YES forKey:@"firstLoad"]; //for custon Loading Ind
	if (![defaults objectForKey:@"appFirstInstallDate"]) {
		[defaults setObject:appFirstInstallDate forKey:@"appFirstInstallDate"];
    }

    #warning Enable to force into Pro mode
    //[defaults setBool:YES forKey:@"tweepr_pro_enabled"];

    [defaults synchronize];

    [[DataManager sharedInstance] mainThreadContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startRefresh) name:userDetailsFinished object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRateExceededAlert) name:didExceedRateLimitNotification object:nil];
    
    [self setupUIAppearance];
    if (![Utils tweeprProEnabled]) {
        [[TPRIAPManager sharedManager] requestProductData];
	}
    
    
    self.storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    self.tabBarController = (UITabBarController *)self.window.rootViewController;
    
    application.statusBarStyle = UIStatusBarStyleDefault;
    self.window.backgroundColor = [UIColor TPRBackgroundColor];
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[Utils cancelAllRequests];
	[[UserLoadingRoutine sharedRoutine] stopRoutine];
	[[RefreshManager sharedInstance] stop];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{	//[[UserLoadingRoutine sharedRoutine] startRoutine];

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)application:(UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))masterTaskCompletionHandler
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

#warning Enable to see notification for each refresh
//    {{
//        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//        [localNotification setFireDate:nil];
//        [localNotification setAlertBody:@"Tweepr background update"];
//        [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
//
//        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//    }}

    NSDate *nextRefreshData = [[RefreshManager sharedInstance] nextRefreshDate];
    NSDate *rightNow = [NSDate date];

    if ([nextRefreshData laterDate:rightNow] == nextRefreshData)
    {
        masterTaskCompletionHandler(UIBackgroundFetchResultFailed);

        BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Frequency violation", self, __PRETTY_FUNCTION__);
        return;
    }

    void (^completionHandlerConversion)(TPBackgroundFetchResult) = ^(TPBackgroundFetchResult fetchResult) {

        // Sorry for the ugly typedef'ing.  Needed for easier support of mutiple OS versions
        masterTaskCompletionHandler((UIBackgroundFetchResult)fetchResult);

    };

    void (^updateUserTweets)(TPBackgroundFetchResult) = ^(TPBackgroundFetchResult fetchResults) {

        switch (fetchResults) {
            case TPBackgroundFetchResultFailed:
                completionHandlerConversion(fetchResults);
                break;
            case TPBackgroundFetchResultNoData:
            case TPBackgroundFetchResultNewData:
            {
                NSLog(@"Checking tweets");
                [[NetworkManager sharedInstance] updateUserTweetsWithCompletionHandler:completionHandlerConversion];
            }
            default:
                break;
        }

    };

    NSLog(@"Checking friendships");
    [[NetworkManager sharedInstance] updateUserFriendshipsWithCompletionHandler:updateUserTweets];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}
#endif

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"TPRUserProfileNavigationController"];
    TPRUserProfileViewController *profileViewController = (TPRUserProfileViewController *)[navigationController topViewController];
    [profileViewController showUnfollowersAnimated:NO];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - Misc Methods

- (void)startRefresh {
    [[RefreshManager sharedInstance] stop];
    [[RefreshManager sharedInstance] start];
}

- (void)setupUIAppearance {
    BOOL isOS7OrHigher = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7);

    //UITabBarItem *tabBarItemApperance = [UITabBarItem appearanceWhenContainedIn:[UIView class], nil];
    //[tabBarItemApperance setTitlePositionAdjustment:UIOffsetMake(0.0, 22.0)];

    UINavigationBar *navBarAppearance = [UINavigationBar appearanceWhenContainedIn:[UIView class], nil];

    
    NSString *navBarImage = @"navbar-bg-7";
    if (!isOS7OrHigher)
        navBarImage = @"navbar-bg";
    UIImage *navBarBackground = [[UIImage imageNamed:navBarImage] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 10, 5)];
    [navBarAppearance setTintColor:[UIColor whiteColor]];
    [navBarAppearance setBackgroundImage:navBarBackground forBarMetrics:UIBarMetricsDefault];
    [navBarAppearance setTitleTextAttributes:@{ UITextAttributeTextColor : [UIColor whiteColor] }];
    
    if (!isOS7OrHigher) {
        [navBarAppearance setShadowImage:[[UIImage alloc] init]];
        [navBarAppearance setTitleTextAttributes:@{
           UITextAttributeFont : [UIFont fontWithName:@"HelveticaNeue-Medium" size:17],
           UITextAttributeTextShadowColor : [UIColor clearColor]
        }];
        
        UIBarButtonItem *barButtonItemAppearance = [UIBarButtonItem appearance];
        [barButtonItemAppearance setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [barButtonItemAppearance setTitleTextAttributes:@{
          UITextAttributeFont : [UIFont fontWithName:@"HelveticaNeue-Light" size:17],
          UITextAttributeTextShadowColor : [UIColor clearColor]
        } forState:UIControlStateNormal];
        
        UIImage *backButtonImage = [[UIImage imageNamed:@"unf_back_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 9, 0, 0)];
        [barButtonItemAppearance setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
    }
    
    UISwitch *switchAppearance = [UISwitch appearanceWhenContainedIn:[UIView class], nil];
    [switchAppearance setOnTintColor:[UIColor colorWithRed:0.0 green:120.0 / 255.0 blue:180.0 / 255.0 alpha:1.0]];
}

- (void)showRateExceededAlert {
    NSString *message = NSLocalizedString(@"There is a request limit per 15 minutes and you reached it! Please retry after 15 minutes", nil);
    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString
{
    NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
    
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *s in components) {
        NSArray *pair = [s componentsSeparatedByString:@"="];
        if ([pair count] == 2) {
            NSString *key = [pair firstObject];
            NSString *value = [pair lastObject];
            
            md[key] = value;
        }
    }
    
    return md;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (![[url scheme] isEqualToString:@"tweepr"]) {
        return NO;
    }
    
    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];
    
    NSString *token = d[@"oauth_token"];
    NSString *verifier = d[@"oauth_verifier"];
    
    [[UserLoadingRoutine sharedRoutine] setOAuthToken:token verifier:verifier];
    
    return YES;
}

@end
