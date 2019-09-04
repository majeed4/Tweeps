//
//  UserTweet.h
//  Tweepr
//
//  Created by Kamil Kocemba on 31/05/2013.
//
//

#import <CoreData/CoreData.h>

@class User;
@class TwitterUser;

@interface UserTweet : NSManagedObject

@property (nonatomic, strong) NSDate *createdAt, *lastUpdated;
@property (nonatomic) NSInteger retweetCount;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *tweetId;
@property (nonatomic, strong) NSString *userIdentifier;
@property (nonatomic, strong) User *user;
@property (nonatomic, assign) BOOL hasImage, hasVideo;
@property (nonatomic, strong) NSString *imageUrl, *videoUrl;
@property (nonatomic, strong) TwitterUser *retweetedFrom;
@property (nonatomic, strong) NSSet *retweeters, *mentions;

@end

@interface UserTweet (CoreDataGeneratedAccessors)

- (void)addRetweetersObject:(TwitterUser *)value;
- (void)addMentionsObject:(TwitterUser *)value;


@end
