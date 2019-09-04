//
//  TPRUpdateTweetsOperation.m
//  Tweepr
//
//  Created by Brian Slick on 10/3/13.
//
//

#import "TPRUpdateTweetsOperation.h"

#import "TwitterUser.h"
#import "Tweet.h"

@interface TPRUpdateTweetsOperation ()

@property (nonatomic, strong) TwitterUser *user;
@property (nonatomic, strong) NSArray *tweets;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end


@implementation TPRUpdateTweetsOperation

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

- (id)initWithUser:(TwitterUser *)user
            tweets:(NSArray *)tweets
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    self = [super init];
    if (self)
    {
        [self setUser:user];
        [self setTweets:tweets];
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

    TwitterUser *user = (TwitterUser *)[context existingObjectWithID:[[self user] objectID] error:nil];

    if (user == nil)
    {
		BTITrackingLog(@"<<< Leaving %s >>> EARLY - No user available", __PRETTY_FUNCTION__);
		return;
	}

    for (NSDictionary *tweetInfo in [self tweets])
    {
        NSString *tweetIdentifier = tweetInfo[@"id_str"];

        Tweet *tweet = [dataManager tweetWithIdentifier:tweetIdentifier inContext:context];
        if (tweet == nil)
        {
            tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                         inManagedObjectContext:context];
            [tweet setTweetId:tweetIdentifier];
            [tweet setText:tweetInfo[@"text"]];

            NSString *createdDateString = tweetInfo[@"created_at"];
            NSDate *createdDate = [[dataManager dateFormatter] dateFromString:createdDateString];
            [tweet setCreatedAt:createdDate];

            [tweet setUser:user];
            // This seems redundant
            [user addTweetsObject:tweet];
        }
    }
    
    [dataManager saveManagedObjectContext:context];

    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] postNotificationName:didUpdateUserTweets object:nil];

    });

	BTITrackingLog(@"<<< Leaving %s >>>", __PRETTY_FUNCTION__);
}

@end
