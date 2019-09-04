//
//  TPRBlockedOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRBlockedOperation.h"

@interface TPRBlockedOperation ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation TPRBlockedOperation

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

- (void)start
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;

    [[DataManager sharedInstance] updateBlockedUsersStatusInContext:[self managedObjectContext]];

    [self didChangeValueForKey:@"isExecuting"];
    [self getBlockedWithCursor:@"-1"];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)getBlockedWithCursor:(NSString *)cursor
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    NSLog(@"Blocked: %@", cursor);
    
    [[[NetworkManager sharedInstance] twitterAPI] getBlocksIDsWithCursor:cursor successBlock:^(NSArray *ids, NSString *previousCursor, NSString *nextCursor) {
        DataManager *dataManager = [DataManager sharedInstance];
        [dataManager updateBlockedStatusWithIds:ids
                                      inContext:[self managedObjectContext]];
        
        if (nextCursor && ![nextCursor isEqualToString:@"0"])
        {
            [self getBlockedWithCursor:nextCursor];
        }
        else
        {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.statusExecuting = NO;
            self.statusFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
        }

    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

//- (void)getBlockedWithCursor:(NSString *)cursor
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//    NSLog(@"Blocked: %@", cursor);
//    NSDictionary *params = @{ @"user_id": self.userId,  @"stringify_ids" : @"true", @"cursor" : cursor };
//    NSString *url = @"https://api.twitter.com/1.1/blocks/ids.json";
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url]
//                                         parameters:params
//                                      requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        NSError *err = nil;
//        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&err];
//        NSArray *ids = [JSON objectForKey:@"ids"];
//        NSString *nextCursor = [[JSON objectForKey:@"next_cursor"] description];
////        dispatch_async(dispatch_get_main_queue(), ^{
//
//            DataManager *dataManager = [DataManager sharedInstance];
//            [dataManager updateBlockedStatusWithIds:ids
//                                          inContext:[self managedObjectContext]];
//
//            if (nextCursor && ![nextCursor isEqualToString:@"0"])
//            {
//                [self getBlockedWithCursor:nextCursor];
//            }
//            else
//            {
//                [self willChangeValueForKey:@"isExecuting"];
//                [self willChangeValueForKey:@"isFinished"];
//                self.executing = NO;
//                self.finished = YES;
//                [self didChangeValueForKey:@"isExecuting"];
//                [self didChangeValueForKey:@"isFinished"];
//            }
////        });
//
//        if (error)
//        {
//            NSLog(@"%@", error);
//        }
//
//    }];
//
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

@end
