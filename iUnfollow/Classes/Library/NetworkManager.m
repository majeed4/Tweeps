//
//  NetworkManager.m
//  Tweepr
//

#import "NetworkManager.h"
#import "SVProgressHUD.h"
#import "TPRPermissions.h"
#import "UserLoadingRoutine.h"
#import "TPRUnfollowOperation.h"
#import "TPRFollowingOperation.h"
#import "TPRFollowersOperation.h"
#import "TPRBlockedOperation.h"
#import "TPRDoneOperation.h"
#import "TPRUnblockOperation.h"
#import "TPRRetweetIdsOperation.h"
#import "TPRRetweetsOperation.h"
#import "TPRTimelineOperation.h"
#import "TPRShowUserOperation.h"
#import "TPRTweetOperation.h"
#import "TPRMentionsOperation.h"

#import "TPRUpdateTweetsOperation.h"

static NSString *twitterAPIURL = @"https://api.twitter.com/1.1/";

@interface NetworkManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong, readonly) ACAccount *account;

@property (nonatomic, strong) STTwitterAPI *twitter;

@end

@implementation NetworkManager

+ (NetworkManager *)sharedInstance {
	static NetworkManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[NetworkManager alloc] init];
	});
	return sharedInstance;
}

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 4;
    }
    return _operationQueue;
}

- (ACAccountStore *)accountStore {
    return [UserLoadingRoutine sharedRoutine].accountStore;
}

- (ACAccount *)account {
    return [UserLoadingRoutine sharedRoutine].account;
}

- (SLRequest *)getRequestWithPath:(NSString *)path params:(NSDictionary *)params {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", twitterAPIURL, path]];
    SLRequest *req = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:URL parameters:params];
    req.account = self.account;
    return req;
}

- (SLRequest *)postRequestWithPath:(NSString *)path params:(NSDictionary *)params {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", twitterAPIURL, path]];
    SLRequest *req = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:URL parameters:params];
    req.account = self.account;
    return req;
}

- (void)startWithUserDict:(NSDictionary *)dict
{
    if (dict[@"token"] && dict[@"secret"]) {
        _twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:twitterConsumerKey consumerSecret:twitterConsumerSecret oauthToken:dict[@"token"] oauthTokenSecret:dict[@"secret"]];
    }
}

- (STTwitterAPI *)resetTwitterAPI
{
    _twitter = nil;
    return _twitter;
    
}

- (STTwitterAPI *)twitterAPI
{
    if (!_twitter) {
        _twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:twitterConsumerKey consumerSecret:twitterConsumerSecret];
    }
    return _twitter;
}

#pragma mark - get users ids

- (void)updateUserFriendshipsWithCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    DataManager *dataManager = [DataManager sharedInstance];
    UserLoadingRoutine *userRoutine = [UserLoadingRoutine sharedRoutine];

    NSInteger followingRequests = 1;
    NSInteger followersRequests = 1;

    if ([userRoutine initialLoadDateForCurrentUser] == nil)
    {
        User *user = [dataManager getUserInfoInContext:[dataManager mainThreadContext]];

        followingRequests += [[user followingNo] intValue] / 5000;
        followersRequests += [[user followersNo] intValue] / 5000;
    }

    __block TPRPermissions *permissions = [TPRPermissions sharedInstance];

    NSLog(@"Permissions:\n followingRequests: %ld\n followingIDsRemaining: %ld\n followerRequests: %ld\n followerIDsRemaining: %ld", (long)followingRequests, (long)permissions.followingIdsRemaining, (long)followersRequests, (long)permissions.followersIdsRemaining);
//    NSLog(@"%d, %d (%d, %d)", followingReqs, followersReq, permissions.followingIdsRemaining, permissions.followersIdsRemaining);

    BOOL isOverFollowerLimit = ([permissions followersIdsRemaining] - followersRequests <= 0);
    BOOL isOverFollowingLimit = ([permissions followingIdsRemaining] - followingRequests <= 0);

    if (isOverFollowerLimit || isOverFollowingLimit)
    {
        if (completionHandler)
        {
            completionHandler(TPBackgroundFetchResultNewData);
        }

//        [[NSNotificationCenter defaultCenter] postNotificationName:didExceedRateLimitNotification object:self];
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Rate limit", self, __PRETTY_FUNCTION__);
        return;
    }

    NSDate *date = [NSDate date];

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating list of following and calculating stats. Please wait...", nil) maskType:SVProgressHUDMaskTypeGradient];

    NSOperation *followingOperation = [[TPRFollowingOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
    NSOperation *followersOperation = [[TPRFollowersOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
    NSOperation *blockedOperation = [[TPRBlockedOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];

    [followersOperation addDependency:followingOperation];

    NSOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            permissions.followersIdsRemaining -= followersRequests;
            permissions.followingIdsRemaining -= followingRequests;

            BOOL shouldPerformCompletionHandler = NO;

            if (!userRoutine.lastUpdateDateForCurrentUser)
            {
                [userRoutine setInitialLoadDateForCurrentUser:[NSDate date]];
                shouldPerformCompletionHandler = YES;
            }
            else
            {
//                [[DataManager sharedInstance] updateUsersOlderThan:date];
//                [[DataManager sharedInstance] updateUsersOlderThan:date withCompletionHandler:completionHandler];
                [dataManager updateUsersOlderThan:date
                                        inContext:[dataManager mainThreadContext]
                            withCompletionHandler:completionHandler];
            }

            [userRoutine setLastUpdateDateForCurrentUser:[NSDate date]];
            [[NSNotificationCenter defaultCenter] postNotificationName:didUpdateFrienshipStatusNotification object:self];
            [SVProgressHUD dismiss];

            if (shouldPerformCompletionHandler)
            {
                if (completionHandler)
                {
                    NSLog(@"Doing Completion Handler");
                    completionHandler(TPBackgroundFetchResultNewData);
                }
            }

        });
    }];
    
    [doneOperation addDependency:followersOperation];
    [doneOperation addDependency:blockedOperation];

    [self.operationQueue addOperation:followingOperation];
    [self.operationQueue addOperation:followersOperation];
    [self.operationQueue addOperation:blockedOperation];
    [self.operationQueue addOperation:doneOperation];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)getRetweetsOfTweet:(UserTweet *)tweet {
    NSDate *lastUpdate = tweet.lastUpdated;
    BOOL shouldUpdate = YES;
    if (lastUpdate && [[NSDate date] timeIntervalSinceDate:lastUpdate] < 15 * 60)
        shouldUpdate = NO;
    if (shouldUpdate) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
        NSOperation *retweetsOperation = [[TPRRetweetIdsOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier tweet:tweet];
        NSOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserTweetsNotification object:self];
                [SVProgressHUD dismiss];
            });
        }];
        [doneOperation addDependency:retweetsOperation];
        [self.operationQueue addOperation:retweetsOperation];
        [self.operationQueue addOperation:doneOperation];
    }
}

- (void)updateUserTweetsWithCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;
//- (void)updateUserTweets
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSOperationQueue *mainQueue = [self operationQueue];

    if ([mainQueue operationCount] > 0)
    {
        // TODO: Not sure if this needs to happen
//        if (completionHandler)
//        {
//            completionHandler(TPBackgroundFetchResultNewData);
//        }
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Download in progress", self, __PRETTY_FUNCTION__);
        return;
    }

    NSDate *lastUpdate = [UserLoadingRoutine sharedRoutine].lastTimelineUpdateForCurrentUser;
    BOOL shouldUpdate = YES;
    if (lastUpdate && [[NSDate date] timeIntervalSinceDate:lastUpdate] < 60 * 60)
    {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate)
    {
        // TODO: This is where the loading HUD was shown
//        [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating your timeline. Please wait...", nil) maskType:SVProgressHUDMaskTypeGradient];
        
        TPRTimelineOperation *timelineOperation = [[TPRTimelineOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
        TPRMentionsOperation *mentionsOperation = [[TPRMentionsOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
        TPRDoneOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{

            dispatch_async(dispatch_get_main_queue(), ^{

                [[UserLoadingRoutine sharedRoutine] setLastTimelineUpdateForCurrentUser:[NSDate date]];
                NSLog(@"Notification didFetchUserTweetsNotification");
                [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserTweetsNotification object:self];
                
// TODO: This is where the loading HUD was removed
//                [SVProgressHUD dismiss];

                if (completionHandler)
                {
                    completionHandler(TPBackgroundFetchResultNewData);
                }

            });

        }];
        
        NSOperation *timelineDoneOperation = [[TPRDoneOperation alloc] initWithBlock:^{

            dispatch_async(dispatch_get_main_queue(), ^{

                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND retweetCount > 0 AND retweetedFrom = nil", [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];
                fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"retweetCount" ascending:NO]];
                fetchRequest.fetchLimit = 10;
                NSError *error;

                NSArray *topRetweetedTweets = [[DataManager sharedInstance].mainThreadContext executeFetchRequest:fetchRequest error:&error];

                for (UserTweet *userTweet in topRetweetedTweets)
                {
                    TPRRetweetsOperation *retweetsOperation = [[TPRRetweetsOperation alloc] initWithUserID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier tweet:userTweet];
                    [doneOperation addDependency:retweetsOperation];

                    [mainQueue addOperation:retweetsOperation];
                }
                
                [mainQueue addOperation:doneOperation];

            });

        }];
        
        [mentionsOperation addDependency:timelineOperation];
        [timelineDoneOperation addDependency:mentionsOperation];
        [doneOperation addDependency:timelineDoneOperation];
        
        [mainQueue addOperation:timelineOperation];
        [mainQueue addOperation:mentionsOperation];
        [mainQueue addOperation:timelineDoneOperation];
    }
    else
    {
        if (completionHandler)
        {
            completionHandler(TPBackgroundFetchResultNoData);
        }
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - unfollowing

- (void)unfollowUsersWithIds:(NSArray *)ids {
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
    TPRDoneOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DataManager sharedInstance] unfollowUsers:ids];
            [SVProgressHUD dismiss];
        });
        NSLog(@"Unfollowed all users");
    }];
    for (TwitterUser *user in ids) {
        TPRUnfollowOperation *operation = [[TPRUnfollowOperation alloc] initWithTwitterUser:user];
        [doneOperation addDependency:operation];
        [self.operationQueue addOperation:operation];
    }
    [self.operationQueue addOperation:doneOperation];
}

- (void)unblockUsersWithIds:(NSArray *)ids {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
    TPRDoneOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DataManager sharedInstance] unblockUsers:ids];
            [SVProgressHUD dismiss];
        });
        NSLog(@"Unblocked all users");
    }];
    for (TwitterUser *user in ids) {
        TPRUnblockOperation *operation = [[TPRUnblockOperation alloc] initWithTwitterUser:user userID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
        [doneOperation addDependency:operation];
        [self.operationQueue addOperation:operation];
    }
    [self.operationQueue addOperation:doneOperation];
}

#pragma mark - twitter user look up

- (void)fetchDetailsForUserIds:(NSArray *)ids
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self fetchDetailsForUserIds:ids animated:NO];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)fetchDetailsForUserIds:(NSArray *)ids animated:(BOOL)animated
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    __block TPRPermissions *permissions = [TPRPermissions sharedInstance];
    if (permissions.usersLookupRemaining - 1 <= 0)
    {
        // Don't notfiy to avoid inifite alert loop
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Skipping due to limits", self, __PRETTY_FUNCTION__);
        return;
    }
    
    DataManager *dataManager = [DataManager sharedInstance];
    NSString *userIds = [ids componentsJoinedByString:@","];
    
    if ([permissions canMakeUserLookupReq])
    {
        if (animated)
        {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
        }
        [self.twitter getUsersLookupForScreenName:nil orUserID:userIds includeEntities:@NO successBlock:^(NSArray *users) {
            if (users) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [dataManager updateFollowingTwitterUsersWithArraysOfDictionary:users
                                                                         inContext:[dataManager mainThreadContext]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
                    
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [dataManager verifyUsersHaveDetailsWithIds:ids
                                                 inContext:[dataManager mainThreadContext]];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
                
                if (animated)
                {
                    [SVProgressHUD dismiss];
                }
            });
            permissions.usersLookupRemaining -= 1;
        } errorBlock:^(NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
        }];
    }

}

//- (void)fetchDetailsForUserIds:(NSArray *)ids
//                      animated:(BOOL)animated
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//    __block TPRPermissions *permissions = [TPRPermissions sharedInstance];
//    if (permissions.usersLookupRemaining - 1 <= 0)
//    {
//        // Don't notfiy to avoid inifite alert loop
//        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Skipping due to limits", self, __PRETTY_FUNCTION__);
//        return;
//    }
//
//    DataManager *dataManager = [DataManager sharedInstance];
//    NSString *userIds = [ids componentsJoinedByString:@","];
//    
//    if ([permissions canMakeUserLookupReq])
//    {
//        NSDictionary *dict = @{ @"entities" : @"false", @"user_id" : userIds };
//        SLRequest *req = [self getRequestWithPath:@"users/lookup.json" params:dict];
//        
//        if (animated)
//        {
//            [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
//        }
//        
//        [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//            if (error)
//            {
//                [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//            }
//            else
//            {
//                NSError *jsonParsingError = nil;
//                NSArray *userDict = [NSJSONSerialization JSONObjectWithData:responseData
//                                                                    options:0
//                                                                      error:&jsonParsingError];
//                if ([userDict isKindOfClass:[NSArray class]])
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//
//                        [dataManager updateFollowingTwitterUsersWithArraysOfDictionary:userDict
//                                                                             inContext:[dataManager mainThreadContext]];
//
//                        [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//                        
//                    });
//                }
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [dataManager verifyUsersHaveDetailsWithIds:ids
//                                                 inContext:[dataManager mainThreadContext]];
//
//                [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//                
//                if (animated)
//                {
//                    [SVProgressHUD dismiss];
//                }
//            });
//            permissions.usersLookupRemaining -= 1;
//        }];
//    }
//}

- (void)updateUser:(TwitterUser *)user animated:(BOOL)animated
{
    if (animated) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
    }
    
    [self.twitter getUsersShowForUserID:user.identifier orScreenName:nil includeEntities:@NO successBlock:^(NSDictionary *user) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[DataManager sharedInstance] updateUserWithDictionary:user];
            
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
            if (animated)
            {
                [SVProgressHUD dismiss];
            }
            
        });
    } errorBlock:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
    }];

}

//- (void)updateUser:(TwitterUser *)user animated:(BOOL)animated {
//    NSDictionary *dict = @{ @"include_entities" : @"false", @"user_id" : user.identifier };
//    
//    SLRequest *req = [self getRequestWithPath:@"users/show.json" params:dict];
//    if (animated) {
//        [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
//    }
//
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (error)
//        {
//            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//        }
//        else
//        {
//            NSError *jsonParsingError = nil;
//            NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseData
//                                                                     options:0
//                                                                       error:&jsonParsingError];
//            if (userDict != nil)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    [[DataManager sharedInstance] updateUserWithDictionary:userDict];
//
//                });
//            }
//        }
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//            if (animated)
//            {
//                [SVProgressHUD dismiss];
//            }
//
//        });
//        
//    }];
//}

- (void)getUserTimeline:(TwitterUser *)user
{
    [self.twitter getStatusesUserTimelineForUserID:user.identifier screenName:user.screenName sinceID:nil count:@"5" maxID:nil trimUser:@YES excludeReplies:nil contributorDetails:nil includeRetweets:nil successBlock:^(NSArray *statuses) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            
            TPRUpdateTweetsOperation *operation = [[TPRUpdateTweetsOperation alloc] initWithUser:user
                                                                                          tweets:statuses];
            [[dataManager operationQueue] addOperation:operation];
            
            //                    [[DataManager sharedInstance] updateUserTweets:user values:array];
            
        });
    } errorBlock:^(NSError *error) {
        
    }];
    
    BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

//- (void)getUserTimeline:(TwitterUser *)user {
//    NSDictionary *dict = @{ @"count" : @"5", @"user_id" : user.identifier, @"trim_user" : @"true"};
//    SLRequest *req = [self getRequestWithPath:@"statuses/user_timeline.json" params:dict];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        if (error)
//        {
//            [[NSNotificationCenter defaultCenter] postNotificationName:didUpdateUserTweets object:nil];
//        }
//        else
//        {
//            NSError *jsonParsingError = nil;
//            NSArray *array = [NSJSONSerialization JSONObjectWithData:responseData
//                                                             options:0
//                                                               error:&jsonParsingError];
//            if (array && [array isKindOfClass:[NSArray class]])
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    DataManager *dataManager = [DataManager sharedInstance];
//
//                    TPRUpdateTweetsOperation *operation = [[TPRUpdateTweetsOperation alloc] initWithUser:user
//                                                                                                  tweets:array];
//                    [[dataManager operationQueue] addOperation:operation];
//
////                    [[DataManager sharedInstance] updateUserTweets:user values:array];
//
//                });
//            }
//        }
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:didUpdateUserTweets object:nil];
//            
//        });
//
//    }];
//
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

- (void)addUnfollowTweetForUsers:(NSArray *)users withCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler {

    NSLog(@"users: %@", users);

    NSArray *ignoreAccounts = @[ @"BrianSlick", @"BriTerIdeas" ];     //@"BTIDevTest"

    TPRDoneOperation *doneOperation = [[TPRDoneOperation alloc] initWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            if (completionHandler)
            {
                completionHandler(TPBackgroundFetchResultNewData);
            }

        });
    }];
    [doneOperation setQueuePriority:NSOperationQueuePriorityVeryLow];

    if (![ignoreAccounts containsObject:[[self account] username]])
    {
        // Look for missing data first

        DataManager *dataManager = [DataManager sharedInstance];

        for (TwitterUser *user in users)
        {
            void(^postTweet)(void) = ^{

                NSLog(@"Should be posting tweet ****************************************");

//                NSManagedObjectContext *tempContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
//                [tempContext setPersistentStoreCoordinator:[dataManager persistentStoreCoordinator]];

                TwitterUser *tempUser = (TwitterUser *)[[dataManager mainThreadContext] existingObjectWithID:[user objectID] error:nil];

                NSString *screenName = [tempUser screenName];
                if (screenName == nil)
                {
                    NSLog(@"No screen name was available !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                    NSLog(@"tempUser is: %@", tempUser);
                    return;
                }

                NSString *status = [NSString stringWithFormat:@"@%@ %@", screenName, NSLocalizedString(@"Unfollow Tweet text", nil)];
                TPRTweetOperation *tweetOperation = [[TPRTweetOperation alloc] initWithStatus:status userID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
                [tweetOperation setQueuePriority:NSOperationQueuePriorityNormal];

                [doneOperation addDependency:tweetOperation];
                [[self operationQueue] addOperation:tweetOperation];

            };

            if ([user screenName] == nil)
            {
                TPRShowUserOperation *userDetailsOperation = [[TPRShowUserOperation alloc] initWithTwitterUser:user userID:[UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier];
                [userDetailsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
                [userDetailsOperation setCompletionBlock:postTweet];

                [doneOperation addDependency:userDetailsOperation];
                [[self operationQueue] addOperation:userDetailsOperation];
            }
            else
            {
                postTweet();
            }
        }
    }

    [[self operationQueue] addOperation:doneOperation];
}

- (void)blockUser:(TwitterUser *)twitterUser
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
    
    [self.twitter postBlocksCreateWithScreenName:twitterUser.screenName orUserID:twitterUser.identifier includeEntities:@NO skipStatus:@YES successBlock:^(NSDictionary *user) {
        dispatch_async(dispatch_get_main_queue(), ^{
            twitterUser.blocked = @YES;
            [twitterUser.managedObjectContext save:NULL];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
            [SVProgressHUD dismiss];
        });

    } errorBlock:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
    }];
}

//- (void)blockUser:(TwitterUser *)user {
//    NSDictionary *dict = @{ @"skip_status" : @"true", @"include_entities" : @"false", @"user_id" : user.identifier };
//    SLRequest *req = [self postRequestWithPath:@"blocks/create.json" params:dict];
//    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (error)
//            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//        else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                user.blocked = @YES;
//                [user.managedObjectContext save:NULL];
//            });
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//            [SVProgressHUD dismiss];
//        });
//    }];
//}

- (void)unblockUser:(TwitterUser *)twitterUser
{
    [self.twitter postBlocksDestroyWithScreenName:twitterUser.screenName orUserID:twitterUser.identifier includeEntities:@NO skipStatus:@YES successBlock:^(NSDictionary *user) {
        dispatch_async(dispatch_get_main_queue(), ^{
            twitterUser.blocked = @NO;
            [twitterUser.managedObjectContext save:NULL];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
            [SVProgressHUD dismiss];
        });
    } errorBlock:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
    }];
}

//- (void)unblockUser:(TwitterUser *)user {
//    NSDictionary *dict = @{ @"skip_status" : @"true", @"include_entities" : @"false", @"user_id" : user.identifier };
//    SLRequest *req = [self postRequestWithPath:@"blocks/destroy.json" params:dict];
//    
//    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (error)
//            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//        else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                user.blocked = @NO;
//                [user.managedObjectContext save:NULL];
//            });
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//            [SVProgressHUD dismiss];
//        });
//    }];
//}

- (void)followUser:(TwitterUser *)twitterUser
{
    [self.twitter postFriendshipsCreateForScreenName:twitterUser.screenName orUserID:twitterUser.identifier successBlock:^(NSDictionary *befriendedUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            twitterUser.following = @YES;
            [twitterUser.managedObjectContext save:NULL];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
            [SVProgressHUD dismiss];
        });
    } errorBlock:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
    }];
}

//- (void)followUser:(TwitterUser *)user {
//    NSDictionary *dict = @{ @"user_id" : user.identifier };
//    SLRequest *req = [self postRequestWithPath:@"friendships/create.json" params:dict];
//    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", nil) maskType:SVProgressHUDMaskTypeGradient];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (error)
//            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//        else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                user.following = @YES;
//                [user.managedObjectContext save:NULL];
//            });
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//            [SVProgressHUD dismiss];
//        });
//    }];
//}

- (void)followTweepr
{
    NSArray *ignoreAccounts = @[ @"kkodev" ];
    if ([ignoreAccounts containsObject:[[self account] username]]) {
        return;
    }

    [self.twitter postFriendshipsCreateForScreenName:@"tweepr1" orUserID:TWEEPR_ACCOUNT_ID successBlock:^(NSDictionary *befriendedUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UserLoadingRoutine sharedRoutine] setDidFollowTweeprForCurrentUser:YES];
        });
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
    
    BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

//- (void)followTweepr {
//    NSArray *ignoreAccounts = @[ @"kkodev" ];
//    if ([ignoreAccounts containsObject:[[self account] username]]) {
//        return;
//    }
//
//    NSDictionary *dict = @{ @"user_id" : TWEEPR_ACCOUNT_ID };
//    SLRequest *req = [self postRequestWithPath:@"friendships/create.json" params:dict];
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (!error && urlResponse.statusCode == 200) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[UserLoadingRoutine sharedRoutine] setDidFollowTweeprForCurrentUser:YES];
//            });
//        }
//    }];
//
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

- (void)unfollowUser:(TwitterUser *)twitterUser
{
    [self.twitter postFriendshipsDestroyScreenName:twitterUser.screenName orUserID:twitterUser.identifier successBlock:^(NSDictionary *unfollowedUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            twitterUser.following = @NO;
            [twitterUser.managedObjectContext save:NULL];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
            [SVProgressHUD dismiss];
        });
    } errorBlock:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
    }];
}

//- (void)unfollowUser:(TwitterUser *)user {
//    NSDictionary *dict = @{ @"user_id" : user.identifier };
//    SLRequest *req = [self postRequestWithPath:@"friendships/destroy.json" params:dict];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        if (error)
//            [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:didFetchUserDetailsNotifcation];
//        else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                user.following = @NO;
//                [user.managedObjectContext save:NULL];
//            });
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserDetailsNotifcation object:nil];
//            [SVProgressHUD dismiss];
//        });
//    }];
//}

#pragma mark - get user details

- (void)getUserDetailsForUserId:(NSString *)userId
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
	if (![[TPRPermissions sharedInstance] canMakeUserDetailsReq])
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Cannot make user details request", self, __PRETTY_FUNCTION__);
		return;
	}
    
    __block NSInteger firstPass;
    if ([Utils internetConnectionIsAvailableWithoutAlertView])
    {
        firstPass = 0;
    }
    
    [self.twitter getUserInformationFor:userId successBlock:^(NSDictionary *user) {
        DataManager *dataManager = [DataManager sharedInstance];
        
        [dataManager insertUserWithDictionary:user inContext:[dataManager mainThreadContext]];
        
        if (![UserLoadingRoutine sharedRoutine].didFollowTweeprForCurrentUser)
        {
            [self followTweepr];
        }
        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:userDetailsFinished];
    } errorBlock:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"The page requested does not exist", nil)]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }];
    
}

//- (void)getUserDetailsForUserId:(NSString *)userId
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//	if (![[TPRPermissions sharedInstance] canMakeUserDetailsReq])
//    {
//		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Cannot make user details request", self, __PRETTY_FUNCTION__);
//		return;
//	}
//
//    __block NSInteger firstPass;
//    if ([Utils internetConnectionIsAvailableWithoutAlertView])
//    {
//        firstPass = 0;
//    }
//
//	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//	NSString *userID = [[self.account valueForKey:@"properties"] valueForKey:@"user_id"];
//	[dict setObject:userID forKey:@"user_id"];
//    
//    SLRequest *req = [self getRequestWithPath:@"users/show.json" params:dict];
//	[req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//		if (!error)
//        {
//			if (urlResponse.statusCode == 200)
//            {
//				NSError *jsonParsingError = nil;
//				NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonParsingError];
//                NSLog(@"userDict: %@", userDict);
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    DataManager *dataManager = [DataManager sharedInstance];
//
//                    [dataManager insertUserWithDictionary:userDict inContext:[dataManager mainThreadContext]];
//
//                    if (![UserLoadingRoutine sharedRoutine].didFollowTweeprForCurrentUser)
//                    {
//                        [self followTweepr];
//                    }
//
//                });
//			}
//            else
//            {
//				//				[[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier] = nil;
//				dispatch_async(dispatch_get_main_queue(), ^{
//
//					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
//                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"The page requested does not exist", nil)]
//                                                                   delegate:nil
//                                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                                                          otherButtonTitles:nil];
//					[alert show];
//
//				});
//			}
//		}
//        else
//        {
//			dispatch_async(dispatch_get_main_queue(), ^{
//
//                firstPass++;
//                if (![Utils internetConnectionIsAvailableWithoutAlertView])
//                {
//                    if (firstPass <= 1)
//                    {
//                        if (![Utils internetConnectionIsAvailable])
//                        {
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"noInternet"
//                                                                                object:nil];
//                        }
//                    }
//                }
//                else
//                {
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
//                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Could not connect to Twitter", nil)]
//                                                                   delegate:nil
//                                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                                                          otherButtonTitles:nil];
//                    [alert show];
//                }
//                
//			});
//		}
//
//        [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:userDetailsFinished];
//
//	}];
//	
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

#pragma mark - limits

- (void)getRateLimits
{
    if (![[TPRPermissions sharedInstance] canMakeUserLookupReq]) {
		return;
	}
    
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	dict[@"resources"] = @[@"application",@"followers",@"friends",@"friendships",@"users"];
    
    [self.twitter getRateLimitsForResources:dict[@"resources"] successBlock:^(NSDictionary *rateLimits)
    {
        NSDictionary *resources = rateLimits[@"resources"];
        TPRPermissions *permissions = [TPRPermissions sharedInstance];
        
        NSDictionary *applicationResource = resources[@"application"];
        if ([applicationResource isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *d = applicationResource[@"/application/rate_limit_status"];
            if ([d isKindOfClass:[NSDictionary class]])
            {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.applicationLimit = [limit integerValue];
                permissions.applicationRemaining = [remaining integerValue];
            }
        }
        
        NSDictionary *followersResource = resources[@"followers"];
        if ([followersResource isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *d = followersResource[@"/followers/ids"];
            if ([d isKindOfClass:[NSDictionary class]])
            {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.followersIdsLimit = [limit integerValue];
                permissions.followersIdsRemaining = [remaining integerValue];
            }
        }
        
        NSDictionary *friendsResource = resources[@"friends"];
        if ([friendsResource isKindOfClass:[NSDictionary class]]) {
            NSDictionary *d = friendsResource[@"/friends/ids"];
            if ([d isKindOfClass:[NSDictionary class]]) {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.followingIdsLimit = [limit integerValue];
                permissions.followingIdsRemaining = [remaining integerValue];
            }
        }
        
        NSDictionary *friendshipsResource = resources[@"friendships"];
        if ([friendshipsResource isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *d = friendshipsResource[@"/friendships/outgoing"];
            if ([d isKindOfClass:[NSDictionary class]]) {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.friendshipsOutgoingLimit = [limit integerValue];
                permissions.friendshipsOutgoingRemaining = [remaining integerValue];
            }
        }
        
        NSDictionary *usersResource = resources[@"users"];
        if ([usersResource isKindOfClass:[NSDictionary class]]) {
            NSDictionary *d = usersResource[@"/users/lookup"];
            if ([d isKindOfClass:[NSDictionary class]])
            {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.usersLookupLimit = [limit integerValue];
                permissions.usersLookupRemaining = [remaining integerValue];
            }
        }
        if ([usersResource isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *d = usersResource[@"/users/show/:id"];
            if ([d isKindOfClass:[NSDictionary class]])
            {
                NSString *limit = d[@"limit"];
                NSString *remaining = d[@"remaining"];
                permissions.userDetailsLimit = [limit integerValue];
                permissions.userDetailsRemaining = [remaining integerValue];
            }
        }
        [self getUserDetailsForUserId:[[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];

    } errorBlock:^(NSError *error) {
        NSLog(@"");
    }];
}

//- (void)getRateLimits {
//	if (![[TPRPermissions sharedInstance] canMakeUserLookupReq]) {
//		return;
//	}
//
//	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//	[dict setObject:@"application,followers,friends,friendships,users" forKey:@"resources"];
//
//    SLRequest *req = [self getRequestWithPath:@"application/rate_limit_status.json" params:dict];
//	[req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//		if (!error)
//        {
//			if (urlResponse.statusCode == 200)
//            {
//				NSError *jsonParsingError = nil;
//				id userDict = [NSJSONSerialization JSONObjectWithData:responseData
//                                                              options:0
//                                                                error:&jsonParsingError];
////                NSLog(@"API rate limit info: \n%@\n", userDict);
//				dispatch_async(dispatch_get_main_queue(), ^{
//
//					if ([userDict isKindOfClass:[NSDictionary class]])
//                    {
//						NSDictionary *resources = [userDict objectForKey:@"resources"];
//						if ([resources isKindOfClass:[NSDictionary class]])
//                        {
//                            TPRPermissions *permissions = [TPRPermissions sharedInstance];
//
//							NSDictionary *applicationResource = [resources objectForKey:@"application"];
//							if ([applicationResource isKindOfClass:[NSDictionary class]])
//                            {
//								NSDictionary *d = [applicationResource objectForKey:@"/application/rate_limit_status"];
//								if ([d isKindOfClass:[NSDictionary class]])
//                                {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.applicationLimit = [limit integerValue];
//									permissions.applicationRemaining = [remaining integerValue];
//								}
//							}
//
//							NSDictionary *followersResource = [resources objectForKey:@"followers"];
//							if ([followersResource isKindOfClass:[NSDictionary class]])
//                            {
//								NSDictionary *d = [followersResource objectForKey:@"/followers/ids"];
//								if ([d isKindOfClass:[NSDictionary class]])
//                                {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.followersIdsLimit = [limit integerValue];
//									permissions.followersIdsRemaining = [remaining integerValue];
//								}
//							}
//
//							NSDictionary *friendsResource = [resources objectForKey:@"friends"];
//							if ([friendsResource isKindOfClass:[NSDictionary class]]) {
//								NSDictionary *d = [friendsResource objectForKey:@"/friends/ids"];
//								if ([d isKindOfClass:[NSDictionary class]]) {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.followingIdsLimit = [limit integerValue];
//									permissions.followingIdsRemaining = [remaining integerValue];
//								}
//							}
//
//							NSDictionary *friendshipsResource = [resources objectForKey:@"friendships"];
//							if ([friendshipsResource isKindOfClass:[NSDictionary class]])
//                            {
//								NSDictionary *d = [friendshipsResource objectForKey:@"/friendships/outgoing"];
//								if ([d isKindOfClass:[NSDictionary class]]) {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.friendshipsOutgoingLimit = [limit integerValue];
//									permissions.friendshipsOutgoingRemaining = [remaining integerValue];
//								}
//							}
//
//							NSDictionary *usersResource = [resources objectForKey:@"users"];
//							if ([usersResource isKindOfClass:[NSDictionary class]]) {
//								NSDictionary *d = [usersResource objectForKey:@"/users/lookup"];
//								if ([d isKindOfClass:[NSDictionary class]])
//                                {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.usersLookupLimit = [limit integerValue];
//									permissions.usersLookupRemaining = [remaining integerValue];
//								}
//							}
//							if ([usersResource isKindOfClass:[NSDictionary class]])
//                            {
//								NSDictionary *d = [usersResource objectForKey:@"/users/show/:id"];
//								if ([d isKindOfClass:[NSDictionary class]])
//                                {
//									NSString *limit = [d objectForKey:@"limit"];
//									NSString *remaining = [d objectForKey:@"remaining"];
//									permissions.userDetailsLimit = [limit integerValue];
//									permissions.userDetailsRemaining = [remaining integerValue];
//								}
//							}
//						}
//					}
//
//				});
//			}
//            else
//            {
//			}
//            [self getUserDetailsForUserId:[[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];
//		}
//        else
//        {
//            [self getUserDetailsForUserId:[[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];
//		}
//	}];
//
//}

@end
