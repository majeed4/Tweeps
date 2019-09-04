//
//  UserLoadingRoutine.h
//  Tweepr
//

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@interface UserLoadingRoutine : NSObject <UIAlertViewDelegate>

+ (UserLoadingRoutine *)sharedRoutine;

@property (nonatomic, assign) BOOL notificationsEnabled;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) ACAccount *account;
@property (nonatomic, strong) NSDictionary *userDict;

- (void)startRoutineWithRequest:(void (^)(NSURL *url, NSString *oathToken))requestToken;
- (void)stopRoutine;

- (BOOL)hasCredentials;

- (void)newUserWithRequest:(void (^)(NSURL *url, NSString *oauthToken))requestBlock;
- (void)addUser:(NSDictionary *)userInfo;
- (void)setOAuthToken:(NSString *)token verifier:(NSString *)verifier;

- (NSString *)lastSelectedUserIdentifier;

- (void)selectUserWithIdentifier:(NSString *)userIdentifier;
- (void)forceTwitterSettingsAlert;

- (NSDate *)initialLoadDateForCurrentUser;
- (void)setInitialLoadDateForCurrentUser:(NSDate *)date;
- (NSDate *)lastUpdateDateForCurrentUser;
- (void)setLastUpdateDateForCurrentUser:(NSDate *)date;

- (BOOL)didFollowTweeprForCurrentUser;
- (void)setDidFollowTweeprForCurrentUser:(BOOL)value;

- (NSDate *)lastUnfollowTweetDateForCurrentUser;
- (void)setLastUnfollowTweetDateForCurrentUser:(NSDate *)date;

- (NSDate *)lastTimelineUpdateForCurrentUser;
- (void)setLastTimelineUpdateForCurrentUser:(NSDate *)date;

@end
