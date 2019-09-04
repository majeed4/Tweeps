//
//  TPRUsersTableCell.h
//  Tweepr
//
//  Created by Kamil Kocemba on 14/06/2013.
//
//

@interface TPRUsersTableCell : UITableViewCell

@property (nonatomic, assign) BOOL loaded, showRetweetCount, showMentionsCount, showCheckbox, showDisclosureIndicator;
@property (nonatomic, strong) UIButton *checkBox;
@property (nonatomic, strong) UILabel *screenNameLabel, *nameLabel, *retweetsLabel, *followingLabel, *followersLabel;

@end
