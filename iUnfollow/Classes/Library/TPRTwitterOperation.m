//
//  TPRTwitterOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 18/05/2013.
//
//

#import "TPRTwitterOperation.h"

@implementation TPRTwitterOperation

- (id)initWithUserID:(NSString *)userID {
    if ((self = [super init])) {
        self.userId = userID;
        self.statusExecuting = NO;
        self.statusFinished = NO;
    }
    return self;
}

//- (id)initWithAccount:(ACAccount *)account {
//    if ((self = [super init])) {
//        self.account = account;
//        self.userId = [[self.account valueForKey:@"properties"] valueForKey:@"user_id"];
//        self.executing = NO;
//        self.finished = NO;
//    }
//    return self;
//}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return self.statusExecuting;
}

- (BOOL)isFinished {
    return self.statusFinished;
}

-(void)setStatusExecuting:(BOOL)statusExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _statusExecuting = statusExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

-(void)setStatusFinished:(BOOL)statusFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _statusFinished = statusFinished;
    [self didChangeValueForKey:@"isFinished"];
}


@end
