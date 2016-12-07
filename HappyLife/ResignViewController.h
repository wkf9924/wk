//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResignViewController : UIViewController<ServiceHelperDelegate>
{
    IBOutlet UITextField *userName;
    IBOutlet UITextField *yzmLab;
    IBOutlet UITextField *Password;
    IBOutlet UITextField *RPassword;
    IBOutlet UIButton *ResignBtn;
    IBOutletCollection(UIView)NSArray *lines;
    
    //四位验证码
    NSString      *Random;
    ServiceHelper *helper;
}

-(IBAction)ResignBtnPressAction:(UIButton *)sender;

@end
