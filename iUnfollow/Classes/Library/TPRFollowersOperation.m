//
//  TPRFollowersOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 18/05/2013.
//
//

#import "TPRFollowersOperation.h"

@implementation TPRFollowersOperation


- (void)start
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self getFollowersWithCursor:@"-1"];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)getFollowersWithCursor:(NSString *)cursor
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    NSLog(@"Followers: %@", cursor);

    __weak TPRFollowersOperation *weakSelf = self;
    void(^finishOperation)(void) = ^{
        
        [weakSelf willChangeValueForKey:@"isExecuting"];
        [weakSelf willChangeValueForKey:@"isFinished"];
        weakSelf.statusExecuting = NO;
        weakSelf.statusFinished = YES;
        [weakSelf didChangeValueForKey:@"isExecuting"];
        [weakSelf didChangeValueForKey:@"isFinished"];
        
    };
    
    [[[NetworkManager sharedInstance] twitterAPI] getFollowersIDsForUserID:self.userId orScreenName:nil cursor:cursor count:nil successBlock:^(NSArray *followersIDs, NSString *previousCursor, NSString *nextCursor) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            
            [dataManager updateFriendshipStatusWithIds:followersIDs
                                             followers:YES
                                             inContext:[dataManager mainThreadContext]];
            
        });
        
        if (nextCursor && ![nextCursor isEqualToString:@"0"])
        {
            [self getFollowersWithCursor:nextCursor];
        }
        else
        {
            finishOperation();
        }


    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
        
        finishOperation();
    }];
    
    BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    
}

//- (void)getFollowersWithCursor:(NSString *)cursor
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//    NSLog(@"Followers: %@", cursor);
//
//    NSDictionary *params = @{ @"user_id": self.userId,  @"stringify_ids" : @"true", @"cursor" : cursor };
//    NSString *url = @"https://api.twitter.com/1.1/followers/ids.json";
//
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url]
//                                         parameters:params
//                                      requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        __weak TPRFollowersOperation *weakSelf = self;
//        void(^finishOperation)(void) = ^{
//
//            [weakSelf willChangeValueForKey:@"isExecuting"];
//            [weakSelf willChangeValueForKey:@"isFinished"];
//            weakSelf.executing = NO;
//            weakSelf.finished = YES;
//            [weakSelf didChangeValueForKey:@"isExecuting"];
//            [weakSelf didChangeValueForKey:@"isFinished"];
//
//        };
//
//        if (error)
//        {
//            NSLog(@"%@", error);
//            finishOperation();
//        }
//        else
//        {
//            NSError *err = nil;
//            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData
//                                                                 options:0
//                                                                   error:&err];
//            //TODO handle error
//            if (err)
//            {
//                NSLog(@"%@", err);
//            }
//
//            NSArray *ids = [JSON objectForKey:@"ids"];
//            NSString *nextCursor = [[JSON objectForKey:@"next_cursor"] description];
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                DataManager *dataManager = [DataManager sharedInstance];
//
//                [dataManager updateFriendshipStatusWithIds:ids
//                                                 followers:YES
//                                                 inContext:[dataManager mainThreadContext]];
//
//            });
//
//                if (nextCursor && ![nextCursor isEqualToString:@"0"])
//                {
//                    [self getFollowersWithCursor:nextCursor];
//                }
//                else
//                {
//                    finishOperation();
//                }
//
////            });
//        }
//
//    }];
//
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

@end
