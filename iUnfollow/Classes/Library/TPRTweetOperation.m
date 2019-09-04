//
//  TPRTweetOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 12/06/2013.
//
//

#import "TPRTweetOperation.h"

@interface TPRTweetOperation ()

@property (nonatomic, strong) NSString *status;

@end

@implementation TPRTweetOperation

- (id)initWithStatus:(NSString *)status userID:(NSString *)userID {
    if ((self = [super initWithUserID:userID])) {
        self.status = status;
    }
    return self;
}

//- (id)initWithStatus:(NSString *)status account:(ACAccount *)account {
//    if ((self = [super initWithAccount:account])) {
//        self.status = status;
//    }
//    return self;
//}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [[[NetworkManager sharedInstance] twitterAPI] postStatusUpdate:self.status inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock:^(NSDictionary *status) {
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.statusExecuting = NO;
        self.statusFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        NSLog(@"Tweeted status: %@", self.status);
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

//- (void)start {
//    
//    NSDictionary *dict = @{ @"status" : self.status };
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"] parameters:dict requestMethod:TWRequestMethodPOST];
//    req.account = self.account;
//    [self willChangeValueForKey:@"isExecuting"];
//    self.executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        
//        [self willChangeValueForKey:@"isExecuting"];
//        [self willChangeValueForKey:@"isFinished"];
//        self.executing = NO;
//        self.finished = YES;
//        [self didChangeValueForKey:@"isExecuting"];
//        [self didChangeValueForKey:@"isFinished"];
//        NSLog(@"Tweeted status: %@", self.status);
//    }];
//}

@end
