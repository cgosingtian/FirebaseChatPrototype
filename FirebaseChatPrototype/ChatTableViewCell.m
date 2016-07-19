//
//  ChatTableViewCell.m
//  FirebaseChatPrototype
//
//  Created by Chase Gosingtian on 07/19/2016.
//  Copyright © 2016 Chase Gosingtian. All rights reserved.
//

#import "ChatTableViewCell.h"

@implementation ChatTableViewCell

- (void)setUsername:(NSString *)username message:(NSString *)message {
    if (username) {
        self.userNameLabel.text = username;
        [self.userNameLabel sizeToFit];
        self.userNameHeightConstraint.constant = 21;
        self.messageLabelTopConstraint.constant = 5;
    } else {
        self.userNameHeightConstraint.constant = 0;
        self.messageLabelTopConstraint.constant = 0;
    }
    self.messageLabel.text = message;
    [self.messageLabel sizeToFit];
}

@end
