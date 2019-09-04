//
//  TPRFollowingOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 18/05/2013.
//
//

#import "TPRFollowingOperation.h"

@implementation TPRFollowingOperation

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self getFollowingWithCursor:@"-1"];
}

- (void)getFollowingWithCursor:(NSString *)cursor
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    NSLog(@"Following: %@", cursor);
    
    [[[NetworkManager sharedInstance] twitterAPI] getFriendsIDsForUserID:self.userId orScreenName:nil cursor:cursor count:@"" successBlock:^(NSArray *ids, NSString *previousCursor, NSString *nextCursor) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            [dataManager updateFriendshipStatusWithIds:ids
                                             followers:NO
                                             inContext:[dataManager mainThreadContext]];
            
            if (nextCursor && ![nextCursor isEqualToString:@"0"])
            {
                [self getFollowingWithCursor:nextCursor];
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
            
        });

    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
    BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

//- (void)getFollowingWithCursor:(NSString *)cursor
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//    NSLog(@"Following: %@", cursor);
//    NSDictionary *params = @{ @"user_id": self.userId,  @"stringify_ids" : @"true", @"cursor" : cursor };
//    NSString *url = @"https://api.twitter.com/1.1/friends/ids.json";
//
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
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            DataManager *dataManager = [DataManager sharedInstance];
//            [dataManager updateFriendshipStatusWithIds:ids
//                                             followers:NO
//                                             inContext:[dataManager mainThreadContext]];
//
//            if (nextCursor && ![nextCursor isEqualToString:@"0"])
//            {
//                [self getFollowingWithCursor:nextCursor];
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
//
//        });
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
