//
//  User.h
//  Tweepr
//

#import <CoreData/CoreData.h>

@class UserTweet;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber *favoritesNo;
@property (nonatomic, retain) NSNumber *followersNo;
@property (nonatomic, retain) NSNumber *followingNo;
@property (nonatomic, retain) NSString *fullName;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *profileImageUrl;
@property (nonatomic, retain) NSNumber *tweetsNo;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *userPageUrl;
@property (nonatomic, retain) NSString *userIdentifier;
@property (nonatomic, strong) NSString *biography;
@property (nonatomic, strong) NSString *profileBackgroundUrl;
@property (nonatomic, strong) NSSet *tweets;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addTweetsObject:(UserTweet *)value;
- (void)removeTweetsObject:(UserTweet *)value;
- (void)addTweets:(NSSet *)values;
- (void)removeTweets:(NSSet *)values;


@end
