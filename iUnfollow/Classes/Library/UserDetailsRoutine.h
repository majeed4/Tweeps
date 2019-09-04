//
//  UserDetailsRoutine.h
//  Tweepr
//

#import <Foundation/Foundation.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@interface UserDetailsRoutine : NSObject {
	
}

//@property BOOL selectedTab;

+ (UserDetailsRoutine *)sharedRoutine;

- (void)start;
- (void)stop;

@end
