//
//  TPRUnblockOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 04/06/2013.
//
//

#import "TPRUnblockOperation.h"
#import "TwitterUser.h"

@interface TPRUnblockOperation ()

@property (nonatomic, strong) TwitterUser *user;

@end

@implementation TPRUnblockOperation

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
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [[[NetworkManager sharedInstance] twitterAPI] postBlocksDestroyWithScreenName:self.user.screenName orUserID:self.user.identifier includeEntities:@0 skipStatus:@1 successBlock:^(NSDictionary *user) {
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.statusExecuting = NO;
        self.statusFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        NSLog(@"Unblocked user: %@", self.user.screenName);
    } errorBlock:nil];
}

//- (void)start {
//    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/blocks/destroy.json"];
//    NSDictionary *dict = @{ @"skip_status" : @"true", @"include_entities" : @"false", @"user_id" : self.user.identifier };
//    TWRequest *req = [[TWRequest alloc] initWithURL:url parameters:dict requestMethod:TWRequestMethodPOST];
//    req.account = self.account;
//    
//    [self willChangeValueForKey:@"isExecuting"];
//    self.executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        
//        [self willChangeValueForKey:@"isExecuting"];
//        [self willChangeValueForKey:@"isFinished"];
//        self.executing = NO;
//        self.finished = YES;
//        [self didChangeValueForKey:@"isExecuting"];
//        [self didChangeValueForKey:@"isFinished"];
//        NSLog(@"Unblocked user: %@", self.user.screenName);
//    }];
//}

@end
