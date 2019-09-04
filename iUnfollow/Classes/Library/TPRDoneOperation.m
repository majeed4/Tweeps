//
//  TPRDoneOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 11/05/2013.
//
//

#import "TPRDoneOperation.h"

@interface TPRDoneOperation ()

@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, assign) BOOL statusFinished;
@property (nonatomic, assign) BOOL statusExecuting;

@end

@implementation TPRDoneOperation

- (id)initWithBlock:(void(^)(void))completion {
    if ((self = [super init])) {
        self.completion = completion;
        self.statusFinished = self.statusExecuting = NO;
    }
    return self;
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    self.completion();
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.statusExecuting = NO;
    self.statusFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.statusFinished;
}

- (BOOL)isExecuting {
    return self.statusExecuting;
}


@end
