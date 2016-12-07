//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

@interface LogInViewController : UIViewController<UITextFieldDelegate,UIGestureRecognizerDelegate,ServiceHelperDelegate>
{
    IBOutlet UITextField  *userName;
    IBOutlet UITextField *PassWord;
    IBOutlet UIButton *LogBtn;
    ServiceHelper *helper;
}

-(IBAction)LogBtnPressAction:(UIButton *)sender;

-(IBAction)ForGetPasswordAction:(UIButton *)sender;


@end
