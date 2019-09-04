//
//  DataManager.h
//  ZipongoUploadData
//
//  Created by Andrei Salanta on 11/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "TwitterUser.h"
@class UserTweet;
@class TwitterUser;
@class Tweet;

@interface DataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *mainThreadContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

+ (DataManager *)sharedInstance;

- (void)saveMainThreadContext;

- (void)updateFriendshipStatusWithIds:(NSArray *)ids
                            followers:(BOOL)isForMyFollowers
                            inContext:(NSManagedObjectContext *)context;
//- (void)insertUserWithDictionary:(NSDictionary *)dict;
- (void)insertUserWithDictionary:(NSDictionary *)dictionary
                       inContext:(NSManagedObjectContext *)context;
//- (void)updateUserTweets:(NSArray *)values;

- (void)updateUserWithDictionary:(NSDictionary *)data;
- (void)updateFollowingTwitterUsersWithArraysOfDictionary:(NSArray *)pendingUsersDict
                                                inContext:(NSManagedObjectContext *)context;

//- (void)updateUsersOlderThan:(NSDate *)date;
- (void)updateUsersOlderThan:(NSDate *)date inContext:(NSManagedObjectContext *)context withCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;
//- (void)updateUserTweets:(TwitterUser *)user values:(NSArray *)array;
//- (void)updateUserMentions:(NSArray *)values;
- (void)updateRetweetsOfTweet:(UserTweet *)tweet
                       values:(NSArray *)values
                    inContext:(NSManagedObjectContext *)context;
- (void)updateRetweetsOfTweet:(UserTweet *)tweet
                   fullValues:(NSArray *)values
                    inContext:(NSManagedObjectContext *)context;

- (NSInteger)countForFollowers:(BOOL)followers;

//- (User *)getUserInfo;
- (User *)getUserInfoInContext:(NSManagedObjectContext *)context;

- (void)updateBlockedUsersStatusInContext:(NSManagedObjectContext *)context;
- (void)updateBlockedStatusWithIds:(NSArray *)ids
                         inContext:(NSManagedObjectContext *)context;

// Not used?
//- (NSMutableArray *)getAllSelectedFollowingUsers;
// Not used?
//- (NSMutableArray *)getAllSelectedNonFollowersUsers;
- (NSArray *)getAllFollowing;
- (NSArray *)getAllFriends;
- (NSArray *)getAllNonFollowingUsers;
- (NSArray *)getAllFans;
- (NSArray *)getRecentFollowers;
- (NSArray *)getRecentUnfollowers;
- (NSArray *)getBlockedUsers;
- (NSArray *)getInactiveUsers;
- (NSArray *)getAllEggs;
- (NSArray *)getAllRetweeted;
- (NSInteger)countForFollowing;
- (NSInteger)countForFriends;
- (NSInteger)countForNonFollowers;
- (NSInteger)countForFans;
- (NSInteger)countForBlocked;
- (NSInteger)countForInactive;
- (NSInteger)countForEggs;

- (NSArray *)getAllMentions;
- (NSInteger)countForMentions;
- (NSArray *)getAllMentioning;
- (NSInteger)countForMentioning;

- (NSArray *)getAllRetweeters;
- (NSArray *)getAllVideos;
- (NSArray *)getAllImages;
- (NSInteger)countForRetweets;
- (NSInteger)countForRetweeted;
- (NSInteger)countForVideos;
- (NSInteger)countForImages;
- (NSInteger)countForRetweeters;

// Not used?
//- (NSString *)getAllUsersIds;

- (void)verifyUsersHaveDetailsWithIds:(NSArray *)ids
                            inContext:(NSManagedObjectContext *)context;

- (NSArray *)allTwitterUsersMatchingIdsInArray:(NSArray *)array
                                     inContext:(NSManagedObjectContext *)context;

- (void)unfollowUsers:(NSArray *)users;
- (void)unblockUsers:(NSArray *)users;

- (void)saveManagedObjectContext:(NSManagedObjectContext *)context;

- (UserTweet *)userTweetWithTweetIdentifier:(NSString *)tweetIdentifier
                                  inContext:(NSManagedObjectContext *)context;
- (TwitterUser *)userWithIdentifier:(NSString *)identifier
                          inContext:(NSManagedObjectContext *)context;
- (void)updateTwitterUser:(TwitterUser *)user
                 withData:(NSDictionary *)data;
- (void)updateUserMentions:(NSArray *)values
                 inContext:(NSManagedObjectContext *)context;
- (Tweet *)tweetWithIdentifier:(NSString *)tweetIdentifier
                     inContext:(NSManagedObjectContext *)context;


@end
