//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ForgetPassViewController : UIViewController<ServiceHelperDelegate>

//登录接口请求用户编号，密码参数为空
@property(nonatomic,strong)NSString *Code;

@property(nonatomic,weak)IBOutlet UITextField *userName;

@property(nonatomic,weak)IBOutlet UITextField *YZM;

@property(nonatomic,weak)IBOutlet UITextField *Password;

@property(nonatomic,weak)IBOutlet UIView *Topview;

@property(nonatomic,weak)IBOutlet UIButton *submitBtn;

@property(nonatomic,weak)IBOutletCollection(UIView)NSArray *lines;

//四位验证码
@property(nonatomic,strong)NSString     *Random;

@property(nonatomic,strong) ServiceHelper *helper;

-(IBAction)submitActionPress:(UIButton *)sender;

-(IBAction)GetYZMPress:(UIButton *)sender;

@end
