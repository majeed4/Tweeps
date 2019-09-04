//
//  Tweet.h
//  Tweepr
//
//  Created by Kamil Kocemba on 27/05/2013.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TwitterUser;

@interface Tweet : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, strong) NSString *tweetId;
@property (nonatomic, strong) TwitterUser *user;
@property (nonatomic, strong) TwitterUser *mentioner;


@end
