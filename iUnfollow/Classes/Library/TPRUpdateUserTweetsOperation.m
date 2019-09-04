//
//  TPRUpdateUserTweetsOperation.m
//  Tweepr
//
//  Created by Brian Slick on 10/3/13.
//
//

#import "TPRUpdateUserTweetsOperation.h"

#import "DataManager.h"
#import "UserLoadingRoutine.h"

@interface TPRUpdateUserTweetsOperation ()

@property (nonatomic, strong) NSArray *userTweets;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation TPRUpdateUserTweetsOperation

#pragma mark - Dealloc and Memory Management

- (void)dealloc
{
	BTITrackingLog(@">>> Entering %s <<<", __PRETTY_FUNCTION__);

	// Clear delegates and other global references
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// Public Properties

	// Private Properties

	BTITrackingLog(@"<<< Leaving %s >>>", __PRETTY_FUNCTION__);
}

#pragma mark - Custom Getters and Setters

- (NSManagedObjectContext *)managedObjectContext
{
	if (_managedObjectContext == nil)
	{
		NSPersistentStoreCoordinator *coordinator = [[DataManager sharedInstance] persistentStoreCoordinator];
		if (coordinator != nil)
		{
			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
	return _managedObjectContext;
}

#pragma mark - Initialization

- (id)initWithUserTweets:(NSArray *)userTweets
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    self = [super init];
    if (self)
    {
        [self setUserTweets:userTweets];
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return self;
}

#pragma mark - NSOperation Methods

- (void)main
{
	BTITrackingLog(@">>> Entering %s <<<", __PRETTY_FUNCTION__);

	if ([self isCancelled])
	{
		BTITrackingLog(@"<<< Leaving %s >>> EARLY - Canceled", __PRETTY_FUNCTION__);
		return;
	}

    DataManager *dataManager = [DataManager sharedInstance];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSString *currentUserIdentifier = [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier];

    for (NSDictionary *userTweetInfo in [self userTweets])
    {
        NSString *userTweetIdentifier = [userTweetInfo[@"id_str"] description];

        UserTweet *tweet = [dataManager userTweetWithTweetIdentifier:userTweetIdentifier
                                                           inContext:context];
        if (tweet == nil)
        {
            tweet = [NSEntityDescription insertNewObjectForEntityForName:@"UserTweet"
                                                  inManagedObjectContext:context];
            [tweet setTweetId:userTweetIdentifier];
        }

        [tweet setText:userTweetInfo[@"text"]];
        [tweet setRetweetCount:[userTweetInfo[@"retweet_count"] integerValue]];
        [tweet setUserIdentifier:currentUserIdentifier];
        NSString *createdAt = userTweetInfo[@"created_at"];
        [tweet setCreatedAt:[[dataManager dateFormatter] dateFromString:createdAt]];

        BOOL hasImage = NO;
        NSDictionary *entities = userTweetInfo[@"entities"];
        NSDictionary *mediaItems = entities[@"media"];
        for (NSDictionary *media in mediaItems)
        {
            if ([media[@"type"] isEqualToString:@"photo"])
            {
                hasImage = YES;
                [tweet setImageUrl:media[@"media_url"]];
            }
        }
        [tweet setHasImage:hasImage];

        BOOL hasVideo = NO;
        NSDictionary *urlItems = entities[@"urls"];
        for (NSDictionary *urlInfo in urlItems)
        {
            NSString *originalUrl = urlInfo[@"expanded_url"];
            if ([originalUrl rangeOfString:@"youtube"].location != NSNotFound || [originalUrl rangeOfString:@"youtu.be"].location != NSNotFound)
            {
                hasVideo = YES;
                [tweet setVideoUrl:originalUrl];
            }
        }
        [tweet setHasVideo:hasVideo];

        NSDictionary *retweetInfo = userTweetInfo[@"retweeted_status"];
        if (retweetInfo != nil)
        {
            [tweet setText:retweetInfo[@"text"]];

            NSDictionary *retweetUserInfo = retweetInfo[@"user"];
            NSString *retweetUserIdentifier = retweetUserInfo[@"id_str"];

            TwitterUser *retweetUser = [dataManager userWithIdentifier:retweetUserIdentifier
                                                             inContext:context];
            if (retweetUser == nil)
            {
                retweetUser = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                            inManagedObjectContext:context];
            }

            [dataManager updateTwitterUser:retweetUser
                                  withData:retweetUserInfo];
            [tweet setRetweetedFrom:retweetUser];

            [retweetUser addUserRetweetsObject:tweet];
        }
        else
        {
            NSDictionary *mentions = entities[@"user_mentions"];
            for (NSDictionary *mention in mentions)
            {
                NSString *mentionUserIdentifier = [mention valueForKey:@"id_str"];

                TwitterUser *mentionUser = [dataManager userWithIdentifier:mentionUserIdentifier
                                                                 inContext:context];
                if (mentionUser == nil)
                {
                    mentionUser = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterUser"
                                                                inManagedObjectContext:context];
                    [mentionUser setUserIdentifier:currentUserIdentifier];
                    [mentionUser setIdentifier:mentionUserIdentifier];
                }

                [mentionUser addMentionedInTweetsObject:tweet];
                [tweet addMentionsObject:mentionUser];
            }
        }
        
    }
    
    [dataManager saveManagedObjectContext:context];
    
	BTITrackingLog(@"<<< Leaving %s >>>", __PRETTY_FUNCTION__);
}

@end
