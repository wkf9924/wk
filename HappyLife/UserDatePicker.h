//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//
#import <UIKit/UIKit.h>

@class UserDatePicker;

@protocol UserDatePickerDelegate <NSObject>

@optional
- (void)didUserDatePickerDelegate:(UserDatePicker*)picker Date:(NSString*)date uploadDate:(NSString *)udate;

@end

/**
 日期选择器
 */

@interface UserDatePicker : UIView

@property(nonatomic, assign) id<UserDatePickerDelegate>    _delegate;
@property(nonatomic, weak) IBOutlet UIDatePicker*        m_Picker;
@property(nonatomic, weak) IBOutlet UIButton*            m_Commit;
@property(nonatomic, weak) IBOutlet UILabel*             m_Title;
@property(nonatomic, assign)          id                   m_Src;

@property(nonatomic, strong)          UIView*              m_Shadow;

+ (UserDatePicker*)UserDatePicker;
+ (void)DestoryUserPicker;

- (IBAction)OnCommitDown:(UIButton*)sender;
- (void)setTitle:(NSString*)title Delegate:(id)delegate Src:(id)src;

- (void)showUserDatePicker;
- (void)hiddeUserDatePicker;

@end
