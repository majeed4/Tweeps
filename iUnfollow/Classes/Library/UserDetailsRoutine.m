//
//  UserDetailsRoutine.m
//  Tweepr
//

#import "UserDetailsRoutine.h"
#import "NetworkManager.h"
#import "UserLoadingRoutine.h"
#import "Constants.h"
#import "SVProgressHUD.h"
#import "Utils.h"
#import "DataManager.h"

@interface UserDetailsRoutine () {
	BOOL inProgress;
}
- (void)addNotifications;
- (void)getUserDetails;
@end

@implementation UserDetailsRoutine
//@synthesize selectedTab;

+ (UserDetailsRoutine *)sharedRoutine {
	static UserDetailsRoutine *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[UserDetailsRoutine alloc] init];
	});
	return sharedInstance;
}

- (void)start
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	if (inProgress)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
		return;
	}

    [self addNotifications];
	[self getUserDetails];

    [[NSNotificationCenter defaultCenter] postNotificationName:didSwitchAccountNotification
														object:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)stop
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	inProgress = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - private

- (void)getUserDetails
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	if (![[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier])
    {
		[Utils showPrevUserChangedAlert];
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
		return;
	}
    
//	if (self.selectedTab == 0)
//    {
//		[SVProgressHUD showWithStatus:NSLocalizedString(@"Getting your info", nil) maskType:SVProgressHUDMaskTypeGradient];
        [[NetworkManager sharedInstance] getRateLimits];
//	}

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)addNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userDetailsFinish)
												 name:userDetailsFinished object:nil];
}



#pragma mark - notifications

- (void)userDetailsFinish
{
//	[SVProgressHUD dismiss];
//	[[NetworkManager sharedInstance] callStatsForId:user.identifier];
}


@end
