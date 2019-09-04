//
//  NetworkManager.h
//  Tweepr
//

#import "TwitterUser.h"
#import "UserTweet.h"

#import <STTwitter/STTwitter.h>

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedInstance;

- (void)getUserDetailsForUserId:(NSString *)userId;

//- (void)twitterAuthorization:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successblock;
- (void)startWithUserDict:(NSDictionary *)dict;
- (STTwitterAPI *)twitterAPI;
- (STTwitterAPI *)resetTwitterAPI;

- (void)updateUserFriendshipsWithCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;
//- (void)updateUserTweets;
- (void)updateUserTweetsWithCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;

- (void)getRetweetsOfTweet:(UserTweet *)tweet;

- (void)fetchDetailsForUserIds:(NSArray *)ids;
- (void)fetchDetailsForUserIds:(NSArray *)ids animated:(BOOL)animated;

- (void)getRateLimits;
- (void)unfollowUsersWithIds:(NSArray *)ids;
- (void)unblockUsersWithIds:(NSArray *)ids;

//- (void)addUnfollowTweetForUser:(TwitterUser *)user;
- (void)addUnfollowTweetForUsers:(NSArray *)users withCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;

//- (void)updateUser:(TwitterUser *)user;
- (void)updateUser:(TwitterUser *)user animated:(BOOL)animated;
- (void)blockUser:(TwitterUser *)user;
- (void)unblockUser:(TwitterUser *)user;
- (void)followUser:(TwitterUser *)user;
- (void)followTweepr;
- (void)unfollowUser:(TwitterUser *)user;
- (void)getUserTimeline:(TwitterUser *)user;

@end
