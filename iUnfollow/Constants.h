//
//  Constants.h
//  Tweepr
//

// App ID:  com.tweepr.tweepr


#ifndef __TWEEPR_CONSTANTS__H__
#define __TWEEPR_CONSTANTS__H__

#define TWEEPR_ACCOUNT_ID @"1376999588"

extern NSString *const userDetailsFinished;
extern NSString *const unfollowUsersFinished;
extern NSString *const deleteUsersFinished;
extern NSString *const deleteAllUsersFinish;
extern NSString *const applicationDidLoadData;

extern NSString *const didSwitchAccountNotification;
extern NSString *const didFetchUserDetailsNotifcation;
extern NSString *const didFetchUserTweetsNotification;
extern NSString *const didUpdateFrienshipStatusNotification;
extern NSString *const didExceedRateLimitNotification;
extern NSString *const didPurchaseTweeprProNotification;
extern NSString *const didUpdateUserTweets;

extern NSString *const twitterConsumerKey;
extern NSString *const twitterConsumerSecret;

//#define BTI_TRACKING_ENABLED 1

//#define is_iOS6 ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending)

// This is only being done to avoid a ton of ifdef stuff while supporting newer iOS 7 features.
// It can be removed at any time once older OS support is no longer required.  Search/replace with UI* equivalents.
typedef enum : NSUInteger {
    TPBackgroundFetchResultNewData,
    TPBackgroundFetchResultNoData,
    TPBackgroundFetchResultFailed
} TPBackgroundFetchResult;

#ifdef DCBLOCKNSLOGSTATEMENTS
#define NSLog(format, ...)
#else
#define NSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#endif

#ifndef BTI_TRACKING_ENABLED
#define BTITrackingLog(...)
#else
#define BTITrackingLog NSLog
#endif

#endif