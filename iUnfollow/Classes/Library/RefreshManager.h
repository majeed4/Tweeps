//
//  RefreshManager.h
//  Tweepr
//

@interface RefreshManager : NSObject

+ (RefreshManager *)sharedInstance;
- (void)start;
- (void)stop;
- (NSDate *)nextRefreshDate;

@end
