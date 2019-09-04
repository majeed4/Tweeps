//
//  TPRTableCell.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRTableCell.h"

@implementation TPRTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureCell];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        [self configureCell];
    }
    return self;
}

- (void)configureCell {
    self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg-selected_overlay"]];
    self.backgroundColor = [UIColor clearColor];
    
    UIColor *bgColor = [UIColor colorWithRed:246.0 / 255.0 green:245.0 / 255.0 blue:240.0 / 255.0 alpha:1.0];
    if ([self respondsToSelector:@selector(tintColor)])
        bgColor = [UIColor clearColor];
    
    self.textLabel.backgroundColor = bgColor;
    self.textLabel.font = [UIFont TPRFontWithSize:18];
    self.textLabel.textColor = [UIColor blackColor];
    self.textLabel.highlightedTextColor = [UIColor TPRHighlightedTextColor];
    
    self.detailTextLabel.backgroundColor = bgColor;
    self.detailTextLabel.font = [UIFont TPRFontWithSize:11];
    self.detailTextLabel.textColor = [UIColor blackColor];
    self.detailTextLabel.highlightedTextColor = [UIColor TPRHighlightedTextColor];
    
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.font = [UIFont TPRFontWithSize:24];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.textColor = [UIColor whiteColor];
    countLabel.highlightedTextColor = [UIColor TPRHighlightedTextColor];

    [self addSubview:countLabel];
    self.countLabel = countLabel;
    
    self.imageView.contentMode = UIViewContentModeCenter;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundView.frame = CGRectInset(self.bounds, 9, 4);
    self.selectedBackgroundView.frame = self.backgroundView.frame;
    self.textLabel.frame = CGRectOffset(self.textLabel.frame, 10, 0);
    
    if (self.imageView.image) {
        self.imageView.frame = CGRectMake(10, 4, 50, 58);

        CGRect frame = self.textLabel.frame;
        frame.origin = CGPointMake(60, frame.origin.y);
        self.textLabel.frame = frame;
    }
        
    self.detailTextLabel.frame = CGRectOffset(self.detailTextLabel.frame, 10, 0);
    self.countLabel.frame = CGRectMake(240, 4, 70, 58);
}

@end
