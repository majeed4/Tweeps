#import "DataManager.h"
#import <CoreData/CoreData.h>
#import "User.h"
#import "Constants.h"
#import "UserLoadingRoutine.h"
#import "Tweet.h"
#import "UserTweet.h"

@interface DataManager ()

@property (strong, nonatomic) NSManagedObjectContext *mainThreadContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSArray *unfollowedUsers;

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation DataManager

+ (DataManager *)sharedInstance
{
	static DataManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[DataManager alloc] init];
	});
	return sharedInstance;
}

#pragma mark - Custom Getters and Setters

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [dateFormatter setDateFormat:@"EEE MMM d HH:mm:ss Z yyyy"];
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
    }
    return _operationQueue;
}

- (NSDate *)recentTimestamp
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    [components setHour: 0];
    [components setMinute: 0];
    [components setSecond: 0];
    NSDate *midnight = [calendar dateFromComponents:components];
    NSDate *initalLoadDate = [UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser;
    return initalLoadDate ? [midnight laterDate:initalLoadDate] : midnight;
}

- (NSDate *)dateForInactiveUsers
{
    return [[NSDate date] dateByAddingTimeInterval:-20 * 24 * 60 * 60];
}

- (Tweet *)tweetWithIdentifier:(NSString *)tweetIdentifier
                     inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    Tweet *tweet = nil;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tweetId = %@", tweetIdentifier]];

    NSArray *results = [context executeFetchRequest:fetchRequest
                                              error:NULL];
    if ([results count] > 0)
    {
        tweet = results[0];
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return tweet;
}


// SLICK - OK for main thread
- (NSInteger)countForFollowers:(BOOL)followers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - No user identifier", self, __PRETTY_FUNCTION__);
        return 0;
	}

    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - No initial load date for current user", self, __PRETTY_FUNCTION__);
        return 0;
	}

    NSLog(@"Recent time stamp: %@", [self recentTimestamp]);

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    NSPredicate *predicate = nil;
    if (followers)
    {
        predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND followed == 1 AND timeStamp >= %@ AND identifier != %@", userIdentifier, [self recentTimestamp], TWEEPR_ACCOUNT_ID];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND isUnfollower == 1 AND timeStamp >= %@ AND identifier != %@", userIdentifier, [self recentTimestamp], TWEEPR_ACCOUNT_ID];
    }

    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSInteger count = [[self mainThreadContext] countForFetchRequest:fetchRequest error:&error];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return count;
}

#pragma mark - insert

- (void)insertUserWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
	NSString *identifier = dictionary[@"id_str"];
    
	NSString *favs = dictionary[@"favourites_count"];
	NSNumber *favsN = @([favs integerValue]);
    
	NSString *followers_count = dictionary[@"followers_count"];
	NSNumber *followers_countN = @([followers_count integerValue]);
    
	NSString *friends_count = dictionary[@"friends_count"];
	NSNumber *friends_countN = @([friends_count integerValue]);
    
	NSString *name = dictionary[@"name"];
    
	NSString *imageUrl = dictionary[@"profile_image_url"];
	NSString *profileBackgroundUrl = dictionary[@"profile_banner_url"];
    NSString *biography = dictionary[@"description"];
    
	NSString *screenName = dictionary[@"screen_name"];
    
	//NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    
	User *user = [self getUserInfoInContext:context];
    
	NSString *url = nil;
    
	NSDictionary *entities = dictionary[@"entities"];
	if (entities && [entities isKindOfClass:[NSDictionary class]])
    {
		NSDictionary *urls = entities[@"url"];
		if (urls && [urls isKindOfClass:[NSDictionary class]])
        {
			NSArray *urlsArray = urls[@"urls"];
			if (urlsArray && [urlsArray isKindOfClass:[NSArray class]] && [urlsArray count] > 0)
            {
				NSDictionary *displaUrls = urlsArray[0];
				if (displaUrls && [displaUrls isKindOfClass:[NSDictionary class]])
                {
					url = displaUrls[@"expanded_url"];
				}
			}
		}
	}
    
	NSString *tweets = dictionary[@"statuses_count"];
	NSNumber *tweetsN = @([tweets integerValue]);
    
	if (user != nil)
    {
		if (identifier && (NSNull *)identifier != [NSNull null])
        {
			user.identifier = identifier;
		}
        
		if (favsN && (NSNull *)favsN != [NSNull null])
        {
			user.favoritesNo = favsN;
		}
        
        if (followers_countN && (NSNull *)followers_countN != [NSNull null])
        {
			user.followersNo = followers_countN;
		}
        
		if (friends_countN && (NSNull *)friends_countN != [NSNull null])
        {
			user.followingNo = friends_countN;
		}
        
		if (name && (NSNull *)name != [NSNull null])
        {
			user.fullName = name;
		}
        
        if (imageUrl && (NSNull *)imageUrl != [NSNull null])
        {
			user.profileImageUrl = imageUrl;
		}
        
		if (screenName && (NSNull *)screenName != [NSNull null])
        {
			user.userName = screenName;
		}
        
        if (tweetsN && (NSNull *)tweetsN != [NSNull null])
        {
			user.tweetsNo = tweetsN;
		}
        
		if (url && (NSNull *)url != [NSNull null])
        {
			user.userPageUrl = url;
		}
        
        if (profileBackgroundUrl && (NSNull *)profileBackgroundUrl != [NSNull null])
        {
            user.profileBackgroundUrl = [profileBackgroundUrl stringByAppendingString:@"/web"];
        }
        if (biography && (NSNull *)biography != [NSNull null])
            user.biography = biography;
        
        [self saveManagedObjectContext:context];
        
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
		return;
	}
    
	user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                         inManagedObjectContext:context];
    
	if (identifier && (NSNull *)identifier != [NSNull null])
    {
		user.identifier = identifier;
	}
    
	if (favsN && (NSNull *)favs != [NSNull null])
    {
		user.favoritesNo = favsN;
	}
    
	if (followers_countN && (NSNull *)followers_countN != [NSNull null])
    {
		user.followersNo = followers_countN;
	}
    
    if (friends_countN && (NSNull *)friends_countN != [NSNull null])
    {
		user.followingNo = friends_countN;
	}
    
    if (name && (NSNull *)name != [NSNull null])
    {
		user.fullName = name;
	}
    
    if (imageUrl && (NSNull *)imageUrl != [NSNull null])
    {
		user.profileImageUrl = imageUrl;
	}
    
	if (screenName && (NSNull *)screenName != [NSNull null])
    {
		user.userName = screenName;
	}
    
    if (tweetsN && (NSNull *)tweetsN != [NSNull null])
    {
		user.tweetsNo = tweetsN;
	}
    
    if (url && (NSNull *)url != [NSNull null])
    {
		user.userPageUrl = url;
	}
    
    //user.userIdentifier = userIdentifier;
    
    [self saveManagedObjectContext:context];
    
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);

}

- (void)insertUserWithDictionary2:(NSDictionary *)dictionary
                       inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	NSString *identifier = dictionary[@"id_str"];

	NSString *favs = dictionary[@"favourites_count"];
	NSNumber *favsN = @([favs integerValue]);

	NSString *followers_count = dictionary[@"followers_count"];
	NSNumber *followers_countN = @([followers_count integerValue]);

	NSString *friends_count = dictionary[@"friends_count"];
	NSNumber *friends_countN = @([friends_count integerValue]);

	NSString *name = dictionary[@"name"];

	NSString *imageUrl = dictionary[@"profile_image_url"];
	NSString *profileBackgroundUrl = dictionary[@"profile_banner_url"];
    NSString *biography = dictionary[@"description"];

	NSString *screenName = dictionary[@"screen_name"];

	NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

	User *user = [self getUserInfoInContext:context];

	NSString *url = nil;

	NSDictionary *entities = dictionary[@"entities"];
	if (entities && [entities isKindOfClass:[NSDictionary class]])
    {
		NSDictionary *urls = entities[@"url"];
		if (urls && [urls isKindOfClass:[NSDictionary class]])
        {
			NSArray *urlsArray = urls[@"urls"];
			if (urlsArray && [urlsArray isKindOfClass:[NSArray class]] && [urlsArray count] > 0)
            {
				NSDictionary *displaUrls = urlsArray[0];
				if (displaUrls && [displaUrls isKindOfClass:[NSDictionary class]])
                {
					url = displaUrls[@"expanded_url"];
				}
			}
		}
	}

	NSString *tweets = dictionary[@"statuses_count"];
	NSNumber *tweetsN = @([tweets integerValue]);

	if (user != nil)
    {
		if (identifier && (NSNull *)identifier != [NSNull null])
        {
			user.identifier = identifier;
		}

		if (favsN && (NSNull *)favsN != [NSNull null])
        {
			user.favoritesNo = favsN;
		}

        if (followers_countN && (NSNull *)followers_countN != [NSNull null])
        {
			user.followersNo = followers_countN;
		}

		if (friends_countN && (NSNull *)friends_countN != [NSNull null])
        {
			user.followingNo = friends_countN;
		}

		if (name && (NSNull *)name != [NSNull null])
        {
			user.fullName = name;
		}

        if (imageUrl && (NSNull *)imageUrl != [NSNull null])
        {
			user.profileImageUrl = imageUrl;
		}

		if (screenName && (NSNull *)screenName != [NSNull null])
        {
			user.userName = screenName;
		}

        if (tweetsN && (NSNull *)tweetsN != [NSNull null])
        {
			user.tweetsNo = tweetsN;
		}

		if (url && (NSNull *)url != [NSNull null])
        {
			user.userPageUrl = url;
		}

        if (profileBackgroundUrl && (NSNull *)profileBackgroundUrl != [NSNull null])
        {
            user.profileBackgroundUrl = [profileBackgroundUrl stringByAppendingString:@"/web"];
        }
        if (biography && (NSNull *)biography != [NSNull null])
            user.biography = biography;
        
        [self saveManagedObjectContext:context];

		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
		return;
	}

	user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                         inManagedObjectContext:context];

	if (identifier && (NSNull *)identifier != [NSNull null])
    {
		user.identifier = identifier;
	}

	if (favsN && (NSNull *)favs != [NSNull null])
    {
		user.favoritesNo = favsN;
	}

	if (followers_countN && (NSNull *)followers_countN != [NSNull null])
    {
		user.followersNo = followers_countN;
	}

    if (friends_countN && (NSNull *)friends_countN != [NSNull null])
    {
		user.followingNo = friends_countN;
	}

    if (name && (NSNull *)name != [NSNull null])
    {
		user.fullName = name;
	}

    if (imageUrl && (NSNull *)imageUrl != [NSNull null])
    {
		user.profileImageUrl = imageUrl;
	}

	if (screenName && (NSNull *)screenName != [NSNull null])
    {
		user.userName = screenName;
	}

    if (tweetsN && (NSNull *)tweetsN != [NSNull null])
    {
		user.tweetsNo = tweetsN;
	}

    if (url && (NSNull *)url != [NSNull null])
    {
		user.userPageUrl = url;
	}

    user.userIdentifier = userIdentifier;

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (NSDictionary *)usersWithIds:(NSArray *)ids
                     inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.returnsObjectsAsFaults = NO;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND (identifier IN %@)", userIdentifier, ids];

    NSError *error;
    NSArray *users = [context executeFetchRequest:fetchRequest
                                            error:&error];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[users count]];
    for (TwitterUser *user in users)
    {
        result[[user identifier]] = user;
    }
    
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return result;
}

- (void)updateFriendshipStatusWithIds:(NSArray *)ids
                            followers:(BOOL)isForMyFollowers
                            inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *currentUserIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!currentUserIdentifier || !ids)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }

    NSInteger count = 0;

    ids = [ids sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    NSDictionary *users = [self usersWithIds:ids
                                   inContext:context];

    NSDate *rightNow = [NSDate date];

    for (NSString *identifier in ids)
    {
        TwitterUser *user = users[identifier];
        if (user == nil)
        {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                 inManagedObjectContext:context];
            [user setIdentifier:identifier];
            [user setUserIdentifier:currentUserIdentifier];
            [user setFollowed:@(isForMyFollowers)];
            [user setFollowing:@(!isForMyFollowers)];
            [user setTimeStamp:rightNow];
        }
        else
        {
            if (isForMyFollowers)
            {
                BOOL isUserFollowed = [[user followed] boolValue];
                if (!isUserFollowed)
                {
                    [user setIsUnfollower:@NO];
                    [user setDidTweet:NO];
                    [user setFollowed:@YES];
                    [user setTimeStamp:rightNow];
                }
            }
            else
            {
                BOOL isUserFollowing = [[user following] boolValue];
                if (!isUserFollowing)
                {
                    [user setFollowing:@YES];
                    [user setTimeStamp:rightNow];
                }
            }
        }

        if (isForMyFollowers)
        {
            [user setLastFollowedOn:rightNow];
        }
        else
        {
            [user setLastFollowingOn:rightNow];
        }
        
        if (++count == 1000)
        {
			count = 0;
            [self saveManagedObjectContext:context];
		}
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}


- (void)updateBlockedUsersStatusInContext:(NSManagedObjectContext *)context;
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }

    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND blocked == 1 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];

    NSArray *users = [context executeFetchRequest:fetchRequest error:&error];
    
    for (TwitterUser *user in users)
    {
        user.blocked = @NO;
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateBlockedStatusWithIds:(NSArray *)ids
                         inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier || !ids)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }

    NSInteger count = 0;
//    NSError *error;
    ids = [ids sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    NSDictionary *users = [self usersWithIds:ids inContext:context];
    for (NSString *identifier in ids)
    {
        TwitterUser *user = users[identifier];
        if (user == nil)
        {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                 inManagedObjectContext:context];
            user.identifier = identifier;
			user.userIdentifier = userIdentifier;
        }

        user.blocked = @YES;

        if (++count == 1000)
        {
			count = 0;
            [self saveManagedObjectContext:context];
		}
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

//- (void)updateUsersOlderThan:(NSDate *)date
- (void)updateUsersOlderThan:(NSDate *)date
                   inContext:(NSManagedObjectContext *)context
       withCompletionHandler:(void (^)(TPBackgroundFetchResult))completionHandler;
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
    {
        if (completionHandler)
        {
            completionHandler(TPBackgroundFetchResultNewData);
        }

		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND (lastFollowedOn < %@ OR lastFollowingOn < %@) AND identifier != %@", userIdentifier, date, date, TWEEPR_ACCOUNT_ID];
    [fetchRequest setIncludesPropertyValues:YES];
    [fetchRequest setReturnsObjectsAsFaults:NO];

    NSError *error;
    NSArray *users = [context executeFetchRequest:fetchRequest
                                            error:&error];

    NSLog(@"Fetched users: %@", users);

    NSMutableArray *unfollowingUsersToTweet = [NSMutableArray array];
    NSMutableArray *unfollowingUsersToNotify = [NSMutableArray array];
    NSDate *lastUnfollowTweetDate = [[UserLoadingRoutine sharedRoutine] lastUnfollowTweetDateForCurrentUser];
    BOOL isTweetingEnabled = ([[NSDate date] timeIntervalSinceDate:lastUnfollowTweetDate] > 14 * 60); //6 * 60 * 60
    if (!lastUnfollowTweetDate)
    {
        isTweetingEnabled = YES;
    }
    
    if (![UserLoadingRoutine sharedRoutine].notificationsEnabled)
    {
        NSLog(@"Notifications are disabled");
        isTweetingEnabled = NO;
    }

    NSDate *rightNow = [NSDate date];

    for (TwitterUser *user in users)
    {
        BOOL isValidFollowerDate = ([user.lastFollowedOn laterDate:date] == date);
        if (isValidFollowerDate)
        {
            BOOL userWasAFollower = [[user followed] boolValue];
            if (userWasAFollower)
            {
#warning Here is where unfollower is determined

                [user setFollowed:@NO];
                [user setIsUnfollower:@YES];

                [unfollowingUsersToNotify addObject:user];

                BOOL canTweetThisUser = ![user didTweet];
                BOOL isUnderTweetLimit = ([unfollowingUsersToTweet count] < 2);

                NSLog(@"isTweetingEnabled: %@", (isTweetingEnabled) ? @"YES" : @"NO");
                NSLog(@"canTweetThisUser: %@", (canTweetThisUser) ? @"YES" : @"NO");
                NSLog(@"isUnderTweetLimit: %@", (isUnderTweetLimit) ? @"YES" : @"NO");

                if (isTweetingEnabled && canTweetThisUser && isUnderTweetLimit)
                {
                    [unfollowingUsersToTweet addObject:user];

                    [user setDidTweet:YES];
                }

                [user setLastFollowedOn:rightNow];
            }
        }
        else
        {
            BOOL wasFollowingUser = [[user following] boolValue];
            if (wasFollowingUser)
            {
                [user setFollowing:@NO];
                [user setLastFollowingOn:rightNow];
            }
        }

        [user setTimeStamp:rightNow];
    }

    [self saveManagedObjectContext:context];

    if ([unfollowingUsersToTweet count] > 0)
    {
        [[UserLoadingRoutine sharedRoutine] setLastUnfollowTweetDateForCurrentUser:[NSDate date]];
    }
    
//    for (TwitterUser *user in toTweet)
//    {
//        [[NetworkManager sharedInstance] addUnfollowTweetForUser:user];
//    }

    if ([unfollowingUsersToNotify count] > 0)
    {
        [self alertOrNotifyForUnfollowers:unfollowingUsersToNotify];
    }

    [[NetworkManager sharedInstance] addUnfollowTweetForUsers:unfollowingUsersToTweet withCompletionHandler:completionHandler];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)alertOrNotifyForUnfollowers:(NSArray *)unfollowers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *message = nil;

    NSInteger numberOfUnfollowers = [unfollowers count];
    if (numberOfUnfollowers == 1)
    {
        TwitterUser *user = [unfollowers lastObject];
        NSString *userName = [user screenName];
        if ([userName length] == 0)
        {
            userName = NSLocalizedString(@"someone", @"someone");
        }

        message = [NSString stringWithFormat:NSLocalizedString(@"%@ has unfollowed you", @"{Twitter Name} has unfollowed you"), userName];
    }
    else
    {
        message = [NSString stringWithFormat:NSLocalizedString(@"%d users have unfollowed you", @"{number} users have unfollowed you"), numberOfUnfollowers];
    }

    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[NSDate dateWithTimeIntervalSinceNow:5]];
        [localNotification setAlertBody:message];
        [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];

        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - update

- (UserTweet *)userTweetWithTweetIdentifier:(NSString *)tweetIdentifier
                                  inContext:(NSManagedObjectContext *)context;
{
    UserTweet *tweetToReturn = nil;
    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND tweetId = %@", userIdentifier, tweetIdentifier]];

    NSError *error;
    NSArray *tweets = [context executeFetchRequest:fetchRequest
                                             error:&error];
    if ([tweets count] > 0)
    {
        tweetToReturn = tweets[0];
    }

    return tweetToReturn;
}

- (TwitterUser *)userWithIdentifier:(NSString *)identifier
                          inContext:(NSManagedObjectContext *)context
{
    TwitterUser *userToReturn = nil;
    NSString *currentUserIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND identifier = %@", currentUserIdentifier, identifier]];

    NSError *error;
    NSArray *users = [context executeFetchRequest:fetchRequest
                                            error:&error];
    if ([users count] > 0)
    {
        userToReturn = users[0];
    }

    return userToReturn;
}

- (void)updateRetweetsOfTweet:(UserTweet *)tweet
                       values:(NSArray *)values
                    inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    for (NSString *userIdentifier in values)
    {
        TwitterUser *user = [self userWithIdentifier:userIdentifier inContext:context];
        if (user == nil)
        {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                 inManagedObjectContext:context];
        }
        user.identifier = userIdentifier;
        user.userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

        [tweet addRetweetersObject:user];
        [user addRetweetsObject:tweet];
    }

    tweet.lastUpdated = [NSDate date];

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateRetweetsOfTweet:(UserTweet *)tweet
                   fullValues:(NSArray *)values
                    inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    for (NSDictionary *dictionary in values)
    {
        NSDictionary *userDict = [dictionary valueForKey:@"user"];
        NSString *userIdentifier = [userDict valueForKey:@"id_str"];
        TwitterUser *user = [self userWithIdentifier:userIdentifier
                                           inContext:context];
        if (user == nil)
        {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                 inManagedObjectContext:context];
        }

        [self updateTwitterUser:user withData:userDict];

        [tweet addRetweetersObject:user];
        [user addRetweetsObject:tweet];
    }
    tweet.lastUpdated = [NSDate date];

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateUserMentions:(NSArray *)values
                 inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    User *user = [self getUserInfoInContext:context];

    for (NSDictionary *dictionary in values)
    {
        NSDictionary *userData = [dictionary valueForKey:@"user"];
        NSString *identifier = [userData valueForKey:@"id_str"];
        if (![identifier isEqualToString:[user identifier]])
        {
            TwitterUser *user = [self userWithIdentifier:identifier inContext:context];
            if (user == nil)
            {
                user = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                     inManagedObjectContext:context];
            }

            [self updateTwitterUser:user withData:userData];

            NSString *text = [dictionary valueForKey:@"text"];
            NSString *dateStr = [dictionary valueForKey:@"created_at"];
            NSString *tweetId = [dictionary valueForKey:@"id_str"];
            NSDate *createdDate = [self.dateFormatter dateFromString:dateStr];

            Tweet *tweet = [self tweetWithIdentifier:tweetId inContext:context];
            if (tweet == nil)
            {
                tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                      inManagedObjectContext:context];
                tweet.tweetId = tweetId;
                tweet.text = text;
                tweet.createdAt = createdDate;
            }
            [user addTweetsMentioningUserObject:tweet];
            tweet.mentioner = user;
        }
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateTwitterUser:(TwitterUser *)user
                 withData:(NSDictionary *)data
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if ( (user == nil) || (data == nil) )
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }

    NSString *userId = data[@"id_str"];
    NSString *websiteUrl = [data valueForKey:@"url"];
    NSString *screenName = data[@"screen_name"];
    NSString *fullName = data[@"name"];
    NSString *imageUrl = data[@"profile_image_url"];
    NSString *profileBackgroundUrl = data[@"profile_banner_url"];
    NSString *biography = data[@"description"];
    NSInteger numFollowers = [data[@"followers_count"] intValue];
    NSInteger numFollowing = [data[@"friends_count"] intValue];
    NSInteger numTweets = [data[@"statuses_count"] intValue];
    NSInteger numFavourites = [data[@"favourites_count"] intValue];
    NSDictionary *lastTweet = data[@"status"];
    NSString *createdAt = lastTweet[@"created_at"];
    NSDate *lastTweetDate = [self.dateFormatter dateFromString:createdAt];
    user.identifier = userId;
    user.userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (screenName)
    {
        user.screenName = screenName;
        user.fullName = fullName;
        user.profileImageUrl = imageUrl;
        if (biography != (NSString *)[NSNull null])
        {
            user.biography = biography;
        }
        
        if (profileBackgroundUrl != (NSString *)[NSNull null])
        {
            user.profileBackgroundUrl = [profileBackgroundUrl stringByAppendingString:@"/web"];
        }
        
        user.numFollowing = numFollowing;
        user.numFollowers = numFollowers;
        user.numTweets = numTweets;
        user.numFavourites = numFavourites;
        user.lastTweetDate = lastTweetDate;
        
        if ([imageUrl rangeOfString:@"default_profile_images"].location != NSNotFound)
        {
            user.hasDefaultImg = YES;
        }
        else
        {
            user.hasDefaultImg = NO;
        }
        
        if (websiteUrl != (NSString *)[NSNull null])
        {
            user.websiteUrl = websiteUrl;
        }
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

// SLICK - OK for main thread for now.  Maybe revisit later.
- (void)updateUserWithDictionary:(NSDictionary *)data
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSManagedObjectContext *context = [self mainThreadContext];

    NSString *userIdentifier = [data valueForKey:@"id_str"];
//    TwitterUser *user = [self userWithId:userId];
    TwitterUser *user = [self userWithIdentifier:userIdentifier
                                       inContext:context];

    [self updateTwitterUser:user withData:data];

    NSError *error;
    [context save:&error];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateFollowingTwitterUsersWithArraysOfDictionary:(NSArray *)pendingUsersDict
                                                inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSMutableArray *idsArr = [[NSMutableArray alloc] init];
    NSSortDescriptor *identifierDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id_str" ascending:YES];
    NSArray *sortDescriptors = @[identifierDescriptor];
    NSArray *pending = [pendingUsersDict sortedArrayUsingDescriptors:sortDescriptors];
    
    for (NSDictionary *dict in pending)
    {
        NSString *userId = dict[@"id_str"];
        [idsArr addObject:userId];
    }

    NSMutableArray *allUsers = [[self allTwitterUsersMatchingIdsInArray:idsArr inContext:context] mutableCopy];
    NSLog(@"allUsers count: %lu", (unsigned long)[allUsers count]);
    
    for (NSDictionary *dictionary in pendingUsersDict)
    {
        NSString *userId = dictionary[@"id_str"];
        if (userId)
        {
            TwitterUser *user = nil;
            for (TwitterUser *aUser in allUsers)
            {
                if ([aUser.identifier isEqualToString:userId])
                {
                    user = aUser;
                    [allUsers removeObject:aUser];
                    break;
                }
            }
            if (user)
            {
                [self updateTwitterUser:user withData:dictionary];
                if (!user.screenName)
                {
                    [context deleteObject:user];
                }
            }
        }
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - get one user

//- (User *)getUserInfo
- (User *)getUserInfoInContext:(NSManagedObjectContext *)context;
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *lastUserIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

	if (lastUserIdentifier == nil)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
		return nil;
	}

    User *userToReturn = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setReturnsObjectsAsFaults:NO];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
											  inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userName beginswith[cd] %@", lastUserIdentifier];
    [fetchRequest setPredicate:predicate];

	NSError *requestError = nil;
	NSArray *items = [context executeFetchRequest:fetchRequest
                                            error:&requestError];
	for (User *user in items)
    {
		if ([[user userName] isEqualToString:lastUserIdentifier])
        {
			userToReturn = user;
            break;
		}
	}
    
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
	return userToReturn;
}


#pragma mark - get all

// SLICK - OK for main thread
- (NSArray *)getAllFollowing
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    NSManagedObjectContext *context = [self mainThreadContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    fetchRequest.fetchLimit = 20;

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TwitterUser"
											  inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    [fetchRequest setSortDescriptors:@[ sortDescriptor ]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID]];

	NSError *requestError = nil;
	NSArray *items = [context executeFetchRequest:fetchRequest
                                            error:&requestError];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
	return items;
}

// SLICK - OK for main thread
- (NSArray *)getAllFriends
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    NSManagedObjectContext *context = [self mainThreadContext];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];[fetchRequest setReturnsObjectsAsFaults:NO];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TwitterUser"
											  inManagedObjectContext:context];
	NSSortDescriptor *sortD = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
	NSArray *sdArray = @[sortD];
	fetchRequest.sortDescriptors = sdArray;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND followed == 1 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];
	[fetchRequest setEntity:entity];
    fetchRequest.fetchLimit = 100;
	
	NSError *requestError = nil;
	NSArray *items = [context executeFetchRequest:fetchRequest error:&requestError];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
	return items;
}

// SLICK - OK for main thread
- (NSArray *)getAllNonFollowingUsers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    NSManagedObjectContext *context = [self mainThreadContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];[fetchRequest setReturnsObjectsAsFaults:NO];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TwitterUser"
											  inManagedObjectContext:context];
	NSSortDescriptor *sortD = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
	NSArray *sdArray = @[sortD];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND followed == 0 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];
	fetchRequest.sortDescriptors = sdArray;
	[fetchRequest setEntity:entity];
    fetchRequest.fetchLimit = 100;
    
    NSError *requestError = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&requestError];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return items;
}

// SLICK - OK for main thread
- (NSArray *)getAllFans
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userIdentifier)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    NSManagedObjectContext *context = [self mainThreadContext];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];[fetchRequest setReturnsObjectsAsFaults:NO];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TwitterUser"
											  inManagedObjectContext:context];
	NSSortDescriptor *sortD = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
	NSArray *sdArray = @[sortD];
	fetchRequest.sortDescriptors = sdArray;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 0 AND followed == 1 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];
	[fetchRequest setEntity:entity];
    fetchRequest.fetchLimit = 100;
	
	NSError *requestError = nil;
	NSArray *items = [context executeFetchRequest:fetchRequest error:&requestError];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
	return items;
}

// SLICK - OK for main thread
- (NSArray *)getRecentFollowers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }

    NSManagedObjectContext *context = [self mainThreadContext];

    NSLog(@"recentTimeStamp: %@", [self recentTimestamp]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.fetchLimit = 100;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND timeStamp >= %@ AND followed == 1 AND identifier != %@", userId, [self recentTimestamp], TWEEPR_ACCOUNT_ID];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getRecentUnfollowers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    
    if (!userIdentifier)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    
    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    NSLog(@"Recent time stamp: %@", [self recentTimestamp]);

    NSManagedObjectContext *context = [self mainThreadContext];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    [fetchRequest setFetchLimit:100];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND timeStamp >= %@ AND isUnfollower == 1 AND identifier != %@", userIdentifier, [self recentTimestamp], TWEEPR_ACCOUNT_ID]];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO] ]];

    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getBlockedUsers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    if (!userIdentifier)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}

    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    NSLog(@"Recent time stamp: %@", [self recentTimestamp]);

    NSManagedObjectContext *context = [self mainThreadContext];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.fetchLimit = 100;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND blocked == 1 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getInactiveUsers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    if (!userIdentifier)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}

    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    NSLog(@"Recent time stamp: %@", [self recentTimestamp]);

    NSManagedObjectContext *context = [self mainThreadContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.fetchLimit = 100;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND lastTweetDate < %@ AND identifier != %@", userIdentifier, [self dateForInactiveUsers], TWEEPR_ACCOUNT_ID];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllEggs
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    if (!userIdentifier)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}

    if (![UserLoadingRoutine sharedRoutine].initialLoadDateForCurrentUser)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    NSLog(@"Recent time stamp: %@", [self recentTimestamp]);

    NSManagedObjectContext *context = [self mainThreadContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.fetchLimit = 100;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND followed == 1 AND hasDefaultImg == 1 AND identifier != %@", userIdentifier, TWEEPR_ACCOUNT_ID];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForNonFollowers {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND followed == 0 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForFollowing {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForFriends {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND followed == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForFans {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 0 AND followed == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForBlocked {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND blocked == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForInactive {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND following == 1 AND lastTweetDate < %@  AND identifier != %@", userId, [self dateForInactiveUsers], TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForEggs {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND followed == 1 AND hasDefaultImg == 1 AND identifier != %@", userId, TWEEPR_ACCOUNT_ID];
    NSError *error;
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForRetweets
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND retweetCount > 0 AND retweetedFrom = nil", userId];
    fetchRequest.fetchLimit = 50;
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllRetweeted
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND userRetweets.@count > 0", userId];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForRetweeted
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND userRetweets.@count > 0", userId];
    fetchRequest.fetchLimit = 20;
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForVideos {
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND hasVideo = 1", userId];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForImages {
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND hasImage = 1", userId];
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllRetweeters
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - No user ID", self, __PRETTY_FUNCTION__);
        return nil;
	}
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND retweets.@count > 0", userId];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO] ];
    
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForRetweeters {
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND retweets.@count > 0", userId];
    fetchRequest.fetchLimit = 20;
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllMentions {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND mentionedInTweets.@count > 0", userId];
    NSError *error;
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForMentions {
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND mentionedInTweets.@count > 0", userId];
    fetchRequest.fetchLimit = 50;
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllMentioning {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND tweetsMentioningUser.@count > 0", userId];
    NSError *error;
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSInteger)countForMentioning {
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return 0;
	}
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TwitterUser"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND tweetsMentioningUser.@count > 0", userId];
    fetchRequest.fetchLimit = 50;
    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [self.mainThreadContext countForFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllVideos {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND hasVideo = 1", userId];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

// SLICK - OK for main thread
- (NSArray *)getAllImages {
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
        return nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND hasImage = 1", userId];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO]];
    NSError *error;
    return [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
}

- (NSArray *)allTwitterUsersMatchingIdsInArray:(NSArray *)array
                                     inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    NSString *userId = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];
    if (!userId)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return nil;
    }
    
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TwitterUser"
                                              inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[ sortDescriptor ]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND identifier IN %@", userId, array]];

    NSError *error;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [context executeFetchRequest:fetchRequest error:&error];
}

- (void)verifyUsersHaveDetailsWithIds:(NSArray *)ids
                            inContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSArray *users = [self allTwitterUsersMatchingIdsInArray:ids
                                                   inContext:context];
    for (TwitterUser *user in users)
    {
        if (![user hasDetails])
        {
            [context deleteObject:user];
        }
    }

    [self saveManagedObjectContext:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}


- (void)unfollowUsers:(NSArray *)users
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSManagedObjectContext *context = [(TwitterUser *)[users lastObject] managedObjectContext];

    for (TwitterUser *user in users)
    {
        user.following = @NO;
    }
    
    self.unfollowedUsers = users;

    [self saveManagedObjectContext:context];

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:deleteUsersFinished object:users];
//    });
    
    [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:deleteUsersFinished object:users userInfo:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)unblockUsers:(NSArray *)users
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSManagedObjectContext *context = [(TwitterUser *)[users lastObject] managedObjectContext];

    for (TwitterUser *user in users)
    {
        user.blocked = @NO;
    }

    [self saveManagedObjectContext:context];


    [[NSNotificationCenter defaultCenter] postNotificationNameOnMainThreadBTI:deleteUsersFinished];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}


#pragma mark - Core Data stack

- (void)saveManagedObjectContext:(NSManagedObjectContext *)context
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if (context == nil)
    {
        BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - No context", self, __PRETTY_FUNCTION__);
        return;
    }

    if (context == [self mainThreadContext])
    {
        [self saveMainThreadContext];
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Main thread context", self, __PRETTY_FUNCTION__);
        return;
    }

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self
                           selector:@selector(managedObjectContextDidSave:)
                               name:NSManagedObjectContextDidSaveNotification
                             object:context];

	// http://stackoverflow.com/questions/1283960/iphone-core-data-unresolved-error-while-saving

	NSError *error;
	if (![context save:&error])
	{
		NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
		NSArray *detailedErrors = [error userInfo][NSDetailedErrorsKey];
		if (detailedErrors != nil && [detailedErrors count] > 0)
		{
			for (NSError *detailedError in detailedErrors)
			{
				NSLog(@"DetailedError: %@", [detailedError userInfo]);
			}
		}
		else
		{
			NSLog(@"  %@", [error userInfo]);
		}
	}

	[notificationCenter removeObserver:self
                                  name:NSManagedObjectContextDidSaveNotification
                                object:context];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
	BTITrackingLog(@">>> Entering %s <<<", __PRETTY_FUNCTION__);

    dispatch_async(dispatch_get_main_queue(), ^{

        NSManagedObjectContext *context = [self mainThreadContext];

        [context mergeChangesFromContextDidSaveNotification:notification];
        
        if (self.unfollowedUsers.count > 0) {
            NSLog(@"Hello");
        }
    });

	BTITrackingLog(@"<<< Leaving %s >>>", __PRETTY_FUNCTION__);
}

- (void)saveMainThreadContext
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self mainThreadContext];

    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (NSManagedObjectContext *)mainThreadContext
{
    if (_mainThreadContext == nil)
    {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainThreadContext setPersistentStoreCoordinator:coordinator];
    }
    return _mainThreadContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil)
    {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"UnfollowModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil)
    {
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"UnfollowModel.sqlite"];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]])
        {
            NSDictionary *existingPersistentStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                                                       URL:storeURL
                                                                                                                     error:&error];
            if (![self.managedObjectModel isConfiguration:nil
                              compatibleWithStoreMetadata:existingPersistentStoreMetadata] )
            {
                NSLog(@"Incompatible persistent store detected. Removing old one.");
                [[NSFileManager defaultManager] removeItemAtURL:storeURL
                                                          error:&error];
                
                NSDictionary *defaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
                for (NSString *key in [defaultsDictionary allKeys])
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }

        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:nil
                                                               error:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end