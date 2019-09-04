//
//  TPRUsersViewController.h
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

@interface TPRUsersViewController : UIViewController;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) BOOL unfollowEnabled;
@property (nonatomic, assign) BOOL unblockEnabled;

- (void)updateDataSource;
- (void)reloadDataSource;

@end
