//
//  myCustomFilterCell.m
//  SimpleDrawing
//
//  Created by android on 6/7/13.
//  Copyright (c) 2013 Nathanial Woolls. All rights reserved.
//

#import "myCustomFilterCell.h"

@implementation myCustomFilterCell
@synthesize inCellLabel,inCellImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
