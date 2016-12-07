//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "LogInViewController.h"
#import "ForgetPassViewController.h"
#include "ResignViewController.h"
#import "LeftViewController.h"
#import "ChildController.h"
#import "RootViewController.h"

@interface LogInViewController ()

@end

@implementation LogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//  userName.text=@"15829752238";
//  PassWord.text=@"888888";
//    userName.text=@"13572130314";
//    PassWord.text=@"111111";
    userName.text=@"18700489142";
    PassWord.text=@"888888";
//    userName.text=@"18049633857";
//    PassWord.text=@"111111";
    self.navigationItem.title=@"登录";
    self.navigationController.navigationBar.barTintColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"navBar"]];
    self.navigationController.navigationBar.translucent=NO;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont systemFontOfSize:18],
       NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    LogBtn.layer.cornerRadius=20;
    [self setDoneBarButtonWithSelector:@selector(ResignActionPress:) andTitle:@"注册"];
    
    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
    if (logerDic!=nil)
    {
        userName.text=logerDic[@"phone"];
        PassWord.text=logerDic[@"pass"];
    }
    LogBtn.layer.cornerRadius=20;
}

-(IBAction)LogBtnPressAction:(UIButton *)sender
{
    NSString *patternPhone = @"^0*(13|15|18|14)\\d{9}$";
    NSError *error = NULL;
    NSRegularExpression *regexPhone = [NSRegularExpression regularExpressionWithPattern:patternPhone options:0 error:&error];
    NSTextCheckingResult *isMatchPhone = [regexPhone firstMatchInString:userName.text
                                                                options:0
                                                                  range:NSMakeRange(0, [userName.text length])];
    
    if (userName.text.length==0)
    {
        [UIAlertView showAlertViewWithTitle:@"请输入账号!" message:nil];
        return;
    }
    else if (!isMatchPhone)
    {
        [UIAlertView showAlertViewWithTitle:@"请输入正确的手机号码" message:nil];
        return;
    }
    else if (PassWord.text.length==0)
    {
        [UIAlertView showAlertViewWithTitle:@"请输入密码！" message:nil];
        return;
    }
    else
    {
        SB_MBPHUD_SHOW(@"登录中...", self.view, NO);
        
        helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",userName.text,PassWord.text],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"LogUser"];
        [helper asynServiceMethod:@"LogUser" SoapMessage:soapMsg Tag:100];
    }
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    NSString *str=xml[@"LogUserResponse"][@"LogUserResult"][@"text"];
    
    if (str==nil||[str intValue]==0)
    {
        SB_MBPHUD_HIDE(@"请检查网络", 3);
    }
    else if ([str isEqualToString:@"-1"])
    {
        SB_MBPHUD_HIDE(@"用户名不存在", 3);
    }
    else if ([str isEqualToString:@"-2"])
    {
        SB_MBPHUD_HIDE(@"密码错误", 3)
    }
    else
    {
        helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",userName.text],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"LoginLog"];
        [helper asynServiceMethod:@"LoginLog" SoapMessage:soapMsg Tag:200];
    }
    
    if (request.tag==200)
    {
        SB_HUD_HIDE;
//        PassWord.text=@"";
        //保存账号密码
        [[Config Instance] SavePhoneAndPass:@{@"phone":userName.text,
                                              @"pass":PassWord.text
                                              }];
        LeftViewController *leftVc=[[LeftViewController alloc] init];
        RootViewController *rootVc=[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RootViewController"];
        [UIApplication sharedApplication].keyWindow.rootViewController=[[ChildController alloc] initWithCenterVC:rootVc CleftVC:leftVc];
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

-(IBAction)ForGetPasswordAction:(UIButton *)sender
{
    ForgetPassViewController *forGetVc=[[ForgetPassViewController alloc] init];
    [self.navigationController pushViewController:forGetVc animated:YES];
}

-(IBAction)ResignActionPress:(UIButton *)sender
{
    ResignViewController *resigner=[[ResignViewController alloc] init];
    [self.navigationController pushViewController:resigner animated:YES];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (userName==textField)
    {
        if ([string isEqualToString:@"\n"])
        {
            [PassWord becomeFirstResponder];
        }
        if (userName.text.length>=11) {
            if (range.length==1)
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
    }
    else if (PassWord==textField)
    {
        if ([string isEqualToString:@"\n"]) {
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
        }
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)dealloc
{
    CANCEL_REQUEST
}
@end
