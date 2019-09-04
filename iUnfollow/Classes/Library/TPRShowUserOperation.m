//
//  TPRShowUserOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 12/06/2013.
//
//

#import "TPRShowUserOperation.h"

@interface TPRShowUserOperation ()

@property (nonatomic, strong) TwitterUser *user;

@end

@implementation TPRShowUserOperation

- (id)initWithTwitterUser:(TwitterUser *)user userID:(NSString *)userID {
    if ((self = [super initWithUserID:userID])) {
        self.user = user;
    }
    return self;
}



//- (id)initWithTwitterUser:(TwitterUser *)user account:(ACAccount *)account {
//    if ((self = [super initWithAccount:account])) {
//        self.user = user;
//    }
//    return self;
//}

- (void)start
{
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    __weak TPRShowUserOperation *weakSelf = self;
    void(^finishOperation)(void) = ^{
        
        [weakSelf willChangeValueForKey:@"isExecuting"];
        [weakSelf willChangeValueForKey:@"isFinished"];
        weakSelf.statusExecuting = NO;
        weakSelf.statusFinished = YES;
        [weakSelf didChangeValueForKey:@"isExecuting"];
        [weakSelf didChangeValueForKey:@"isFinished"];
        
    };
    
    [[[NetworkManager sharedInstance] twitterAPI] getUsersShowForUserID:self.user.identifier orScreenName:self.user.screenName includeEntities:@0 successBlock:^(NSDictionary *user) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            [dataManager updateFollowingTwitterUsersWithArraysOfDictionary:@[user]
                                                                 inContext:[dataManager mainThreadContext]];
            
            finishOperation();
        });
    } errorBlock:^(NSError *error) {
        finishOperation();
    }];
}

//- (void)start
//{
//	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
//
//    NSDictionary *dict = @{ @"include_entities" : @"false", @"user_id" : self.user.identifier };
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json"] parameters:dict requestMethod:TWRequestMethodGET];
//    req.account = self.account;
//    
//    [self willChangeValueForKey:@"isExecuting"];
//    self.executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        __weak TPRShowUserOperation *weakSelf = self;
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
//        if (!error)
//        {
//            NSError *jsonParsingError = nil;
//            NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonParsingError];
//            if (userDict)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    DataManager *dataManager = [DataManager sharedInstance];
//                    [dataManager updateFollowingTwitterUsersWithArraysOfDictionary:@[userDict]
//                                                                         inContext:[dataManager mainThreadContext]];
//
//                    finishOperation();
//                });
//            }
//            else
//            {
//                finishOperation();
//            }
//        }
//        else
//        {
//            finishOperation();
//        }
//
//    }];
//
//	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
//}

@end
