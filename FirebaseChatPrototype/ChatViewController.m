//
//  ChatViewController.m
//  FirebaseChatPrototype
//
//  Created by Chase Gosingtian on 07/19/2016.
//  Copyright © 2016 Chase Gosingtian. All rights reserved.
//

@import FirebaseDatabase;

#import "ChatViewController.h"
#import "ChatTableViewCell.h"

@interface ChatViewController ()

@property (nonatomic, strong) FIRDatabaseReference *ref;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMessageViewConstraint;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *textFieldsView;

@property (nonatomic, strong) NSMutableArray *messagesArray;

//@property (nonatomic, assign) FIRDatabaseHandle valueHandle;
@property (nonatomic, assign) FIRDatabaseHandle addHandle;
@property (nonatomic, assign) FIRDatabaseHandle deleteHandle;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ref = [[FIRDatabase database] reference];
    
    UINib *cellNib = [UINib nibWithNibName:CHAT_CELL_REUSE_ID
                                    bundle:nil];
    [self.tableView registerNib:cellNib
         forCellReuseIdentifier:CHAT_CELL_REUSE_ID];
    
    UITapGestureRecognizer *tapGC = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleViewTap)];
    [self.view addGestureRecognizer:tapGC];
    
    self.sendButton.enabled = NO;
    
    self.messageTextField.delegate = self;
    self.userNameTextField.delegate = self;
    
    self.messagesArray = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.addHandle = [[self.ref child:@"messages"] observeEventType:FIRDataEventTypeChildAdded
                                                          withBlock:^(FIRDataSnapshot *snapshot) {
                                                              [self.messagesArray addObject:snapshot];
                                                              NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messagesArray.count-1 inSection:0];
                                                              [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                                                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                                                          }];
    
    self.deleteHandle = [[self.ref child:@"messages"] observeEventType:FIRDataEventTypeChildRemoved
                                                             withBlock:^(FIRDataSnapshot *snapshot) {
                                                                 NSInteger index = [self indexOfMessage:snapshot];
                                                                 [self.messagesArray removeObjectAtIndex:index];
                                                                 [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                                                                       withRowAnimation:UITableViewRowAnimationAutomatic];
                                                             }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.ref removeObserverWithHandle:self.addHandle];
    [self.ref removeObserverWithHandle:self.deleteHandle];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// From https://github.com/firebase/quickstart-ios/blob/master/database/DatabaseExample/PostDetailTableViewController.m
// Basically the object you added as a snapshot will be a different object later; you need to verify via key
- (NSInteger) indexOfMessage:(FIRDataSnapshot *)snapshot {
    NSInteger index = 0;
    for (FIRDataSnapshot *message in self.messagesArray) {
        if ([snapshot.key isEqualToString:message.key]) {
            return index;
        }
        ++index;
    }
    return -1;
}

- (void)handleViewTap {
    [self.view endEditing:YES];
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    NSDictionary *keyboardInfo = [notification userInfo];
    NSValue *keyboardFrameValue = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    self.bottomMessageViewConstraint.constant = keyboardFrame.size.height;
    
    NSNumber *number = [keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat duration = [number floatValue];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
    
    [self scrollTableViewWithKeyboardShowing:YES keyboardFrame:keyboardFrame];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    self.bottomMessageViewConstraint.constant = 0;
    
    NSDictionary *keyboardInfo = [notification userInfo];
    NSNumber *number = [keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat duration = [number floatValue];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         [self.tableView layoutIfNeeded];
                         [self.view layoutIfNeeded];
                     }];
    
    NSValue *keyboardFrameValue = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    
    [self scrollTableViewWithKeyboardShowing:NO keyboardFrame:keyboardFrame];
}

- (void)scrollTableViewWithKeyboardShowing:(BOOL)keyboardShowing keyboardFrame:(CGRect)keyboardFrame {
    CGRect visibleRect;
    visibleRect.origin = self.tableView.contentOffset;
    visibleRect.size = self.tableView.bounds.size;
    
    if (keyboardShowing) {
        visibleRect.size.height += keyboardFrame.size.height;
    } else {
        visibleRect.origin.y -= keyboardFrame.size.height;
    }
    
    [self.tableView scrollRectToVisible:visibleRect animated:NO];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.length == textField.text.length && string.length == 0) {
        self.sendButton.enabled = NO;
    } else {
        if (string.length == 0) {
            self.sendButton.enabled = (self.messageTextField.text.length > 1 && self.userNameTextField.text.length > 1);
        } else {
            if (textField == self.messageTextField) {
                self.sendButton.enabled = self.userNameTextField.text.length > 0;
            } else if (textField == self.userNameTextField) {
                self.sendButton.enabled = self.messageTextField.text.length > 0;
            }
        }
    }
    
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CHAT_CELL_REUSE_ID];
    
    FIRDataSnapshot *messageSnapshot = [self.messagesArray objectAtIndex:indexPath.row];
    
    NSString *username = messageSnapshot.value[@"sender"];
    
    if (indexPath.row > 0) {
        FIRDataSnapshot *previousSnapshot = [self.messagesArray objectAtIndex:indexPath.row-1];
        if ([previousSnapshot.value[@"sender"] isEqualToString:username]) {
            username = nil;
        }
    }
    
    [cell setUsername:username message:messageSnapshot.value[@"message"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messagesArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 105;
}

- (IBAction)sendButtonTapped:(id)sender {
    NSString *username = self.userNameTextField.text;
    if (username.length <= 0) {
        username = @"Default";
    }
    NSString *key = [[self.ref child:@"messages"] childByAutoId].key;
    NSDictionary *message = @{@"message":self.messageTextField.text,
                              @"sender":username};
    NSDictionary *childUpdate = @{[@"/messages/" stringByAppendingString:key]:message};
    [self.ref updateChildValues:childUpdate
            withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messagesArray.count-1 inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
            }];
    
    [self.messageTextField setText:@""];
    self.sendButton.enabled = NO;
}

@end
