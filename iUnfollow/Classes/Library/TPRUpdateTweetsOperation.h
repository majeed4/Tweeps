//
//  TPRUpdateTweetsOperation.h
//  Tweepr
//
//  Created by Brian Slick on 10/3/13.
//
//

#import <Foundation/Foundation.h>
@class TwitterUser;

@interface TPRUpdateTweetsOperation : NSOperation

- (id)initWithUser:(TwitterUser *)user tweets:(NSArray *)tweets;

@end
