//
//  RefreshManager.m
//  Tweepr
//

#import "RefreshManager.h"
#import "Constants.h"
#import "NetworkManager.h"
#import "DataManager.h"
#import "UserLoadingRoutine.h"

@interface RefreshManager ()

@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong, readonly) NSString *userIdentifier;

@end

@implementation RefreshManager

const NSTimeInterval refreshInterval = 15 * 60;

+ (RefreshManager *)sharedInstance {
	static RefreshManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[RefreshManager alloc] init];
        sharedInstance.active = NO;
	});
	return sharedInstance;
}

- (NSString *)userIdentifier {
    return [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
}

#pragma mark - public

- (void)start
{
    self.active = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdate:) name:didUpdateFrienshipStatusNotification object:nil];
    [self scheduleUpdate:nil];
}

- (NSDate *)nextRefreshDate
{
    NSDate *lastReload = [UserLoadingRoutine sharedRoutine].lastUpdateDateForCurrentUser;
    if (lastReload == nil)
    {
        return [NSDate date];
    }

    NSDate *nextReload = [lastReload dateByAddingTimeInterval:refreshInterval];
    return [nextReload laterDate:[NSDate date]];
}

- (void)scheduleUpdate:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshTimer = [[NSTimer alloc] initWithFireDate:[self nextRefreshDate] interval:0 target:self selector:@selector(updateFriendshipStatus:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
    });
}

- (void)updateFriendshipStatus:(NSTimer *)timer
{
    [[NetworkManager sharedInstance] updateUserFriendshipsWithCompletionHandler:nil];
}

- (void)stop
{
    self.active = NO;
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notifications


@end

