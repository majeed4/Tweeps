//
//  TPRTimelineOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 08/06/2013.
//
//

#import "TPRTimelineOperation.h"

#import "TPRUpdateUserTweetsOperation.h"

@implementation TPRTimelineOperation


- (void)start
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [self getTweetsOlderThan:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)getTweetsOlderThan:(NSString *)maxId
{
    NSLog(@"Timeline: %@", maxId);
    
    [[[NetworkManager sharedInstance] twitterAPI] getStatusesUserTimelineForUserID:self.userId screenName:nil sinceID:nil count:@"100" maxID:maxId trimUser:@YES excludeReplies:nil contributorDetails:nil includeRetweets:@YES successBlock:^(NSArray *statuses) {
        BOOL done = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            TPRUpdateUserTweetsOperation *operation = [[TPRUpdateUserTweetsOperation alloc] initWithUserTweets:statuses];
            [[[DataManager sharedInstance] operationQueue] addOperation:operation];
            //                [[DataManager sharedInstance] updateUserTweets:JSON];
            
        });
        
        NSDictionary *maxUser = [statuses lastObject];
        NSString *nextId = [maxUser[@"id_str"] description];
        if (nextId.length && ![maxId isEqualToString:nextId])
        {
            done = NO;
            [self getTweetsOlderThan:nextId];
        }
        
        if (done)
        {
            dispatch_async(dispatch_get_main_queue(), ^{

                [self willChangeValueForKey:@"isExecuting"];
                [self willChangeValueForKey:@"isFinished"];
                self.statusExecuting = NO;
                self.statusFinished = YES;
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];

            });
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

//- (void)getTweetsOlderThan:(NSString *)maxId
//{
//    NSLog(@"Timeline: %@", maxId);
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
//                                   @{ @"count" : @"100", @"trim_user" : @"true", @"include_rts" : @"true", @"include_entities" : @"true",  @"include_user_entities" : @"true" }];
//    if (maxId)
//    {
//        params[@"max_id"] = maxId;
//    }
//
//    NSString *url = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url]
//                                         parameters:params
//                                      requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        BOOL done = YES;
//        NSError *err = nil;
//
//        NSArray *JSON = [NSJSONSerialization JSONObjectWithData:responseData
//                                                        options:0
//                                                          error:&err];
//        if ( ([JSON isKindOfClass:[NSArray class]]) && ([JSON count] > 0) )
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                TPRUpdateUserTweetsOperation *operation = [[TPRUpdateUserTweetsOperation alloc] initWithUserTweets:JSON];
//                [[[DataManager sharedInstance] operationQueue] addOperation:operation];
////                [[DataManager sharedInstance] updateUserTweets:JSON];
//
//            });
//
//            NSDictionary *maxUser = [JSON lastObject];
//            NSString *nextId = [[maxUser objectForKey:@"id_str"] description];
//            if (nextId.length && ![maxId isEqualToString:nextId])
//            {
//                done = NO;
//                [self getTweetsOlderThan:nextId];
//            }
//        }
//
//        if (done)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [self willChangeValueForKey:@"isExecuting"];
//                [self willChangeValueForKey:@"isFinished"];
//                self.executing = NO;
//                self.finished = YES;
//                [self didChangeValueForKey:@"isExecuting"];
//                [self didChangeValueForKey:@"isFinished"];
//
//            });
//        }
//        if (error)
//        {
//            NSLog(@"%@", error);
//        }
//    }];
//}


@end
