//
//  ChatTableViewCell.h
//  FirebaseChatPrototype
//
//  Created by Chase Gosingtian on 07/19/2016.
//  Copyright © 2016 Chase Gosingtian. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const CHAT_CELL_REUSE_ID = @"ChatTableViewCell";

@interface ChatTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userNameHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageLabelTopConstraint;

- (void)setUsername:(NSString *)username message:(NSString *)message;

@end
