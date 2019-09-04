//
//  TwitterUser.h
//  Tweepr
//
//  Created by Kamil Kocemba on 27/05/2013.
//
//

#import <CoreData/CoreData.h>

@class Tweet;
@class UserTweet;

@interface TwitterUser : NSManagedObject

@property (nonatomic, retain) NSString * biography;
@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSNumber * followed;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * lastTweetDate;
@property (nonatomic, assign) NSInteger numFollowing, numFollowers, numTweets, numFavourites;
@property (nonatomic, retain) NSString * profileImageUrl;
@property (nonatomic, retain) NSString * screenName;
@property (nonatomic, retain) NSNumber * selected;
@property (nonatomic, strong) NSNumber * isUnfollower;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * userIdentifier;
@property (nonatomic, retain) NSString * websiteUrl;
@property (nonatomic, retain) NSSet *tweets;
@property (nonatomic, strong) NSString *profileBackgroundUrl;
@property (nonatomic, strong) NSSet *retweets;
@property (nonatomic, assign) BOOL hasDefaultImg, didTweet;
@property (nonatomic, strong) NSSet *userRetweets, *mentionedInTweets, *tweetsMentioningUser;
@property (nonatomic, strong) NSDate *lastFollowedOn, *lastFollowingOn;

- (BOOL)hasDetails;

@end

@interface TwitterUser (CoreDataGeneratedAccessors)

- (void)addTweetsObject:(Tweet *)value;
- (void)addRetweetsObject:(UserTweet *)value;
- (void)addUserRetweetsObject:(UserTweet *)value;
- (void)addMentionedInTweetsObject:(UserTweet *)value;
- (void)addTweetsMentioningUserObject:(Tweet *)value;

@end
