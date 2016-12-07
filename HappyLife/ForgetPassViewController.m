//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ForgetPassViewController.h"

@interface ForgetPassViewController ()

@end

@implementation ForgetPassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title=@"修改密码";
    [self setBackBarButton];
    _submitBtn.layer.cornerRadius=20;
    
    for (UIView *line in _lines) {
        CGRect rect=line.frame;
        rect.size.height=0.5;
        line.frame=rect;
    }
}

-(BOOL)UserNameIsUserable
{
    
    NSString *patternPhone = @"^0*(13|15|18|14)\\d{9}$";
    NSError *error = NULL;
    NSRegularExpression *regexPhone = [NSRegularExpression regularExpressionWithPattern:patternPhone options:0 error:&error];
    NSTextCheckingResult *isMatchPhone = [regexPhone firstMatchInString:_userName.text
                                                                options:0
                                                                  range:NSMakeRange(0, [_userName.text length])];
    return isMatchPhone?YES:NO;
}

-(IBAction)GetYZMPress:(UIButton *)sender
{

    CANCEL_REQUEST
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    
    _Random=[NSString stringWithFormat:@"%d%d%d%d%d%d",arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10];
    SB_MBPHUD_SHOW(@"正在发送验证码...", self.view, NO);
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:_userName.text,@"Phone", nil]];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:_Random,@"Rand", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"CheckRand"];
    [_helper asynServiceMethod:@"CheckRand" SoapMessage:soapMsg Tag:300];
}

-(IBAction)submitActionPress:(UIButton *)sender
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    
    if (_userName.text.length==0) {
        [UIAlertView showAlertViewWithTitle:@"请输入手机号码" message:nil];
        return;
    }
    else if (![self UserNameIsUserable])
    {
        [UIAlertView showAlertViewWithTitle:@"请输入正确的手机号码" message:nil];
        return;
    }
    if (![_YZM.text isEqualToString:_Random])
    {
        [UIAlertView showAlertViewWithTitle:@"请输入正确的验证码" message:nil];
        return;
    }
    if (_Password.text.length<6)
    {
        
        [UIAlertView showAlertViewWithTitle:@"密码必须大于6位" message:nil];
        
        return;
    }
    
    else
    {
        [SBPublicAlert showMBProgressHUD:@"密码修改中..." andWhereView:self.view states:NO];
        
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",_userName.text,_Password.text],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"FindPassword"];
        [_helper asynServiceMethod:@"FindPassword" SoapMessage:soapMsg Tag:100];
    }
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        NSString *str=xml[@"FindPasswordResponse"][@"FindPasswordResult"][@"text"];
        
        if (str==nil||[str intValue]==0)
        {
            SB_MBPHUD_HIDE(@"请检查网络", 3);
        }
        else if ([str isEqualToString:@"-1"])
        {
            SB_MBPHUD_HIDE(@"用户名不存在", 3)
        }
        else if ([str isEqualToString:@"1"])
        {
            SB_MBPHUD_HIDE(@"密码修改成功", 1);
            [self.navigationController popViewControllerAnimated:YES];
            
            _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",_userName.text,_Password.text],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"FindPassword"];
            [_helper asynServiceMethod:@"FindPassword" SoapMessage:soapMsg Tag:200];
        }
    }
    else if (request.tag==200)
    {
    
    }
    
    else if (request.tag==300)
    {
        NSString *result=xml[@"CheckRandResponse"][@"CheckRandResult"][@"text"];
        if ([result intValue]==2)
        {
            SB_MBPHUD_HIDE(@"验证码获取成功", 1);
        }
        else if ([result integerValue]==4085)
        {
            SB_MBPHUD_HIDE(@"验证码获取次数过多", 3);
        }
        else
        {
            SB_MBPHUD_HIDE(@"验证码获取失败", 3);
        }
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (_userName==textField) {
        if (_userName.text.length>=11) {
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
    
    if ([string isEqualToString:@"\n"])
    {
        if (_YZM==textField) {
            [_YZM becomeFirstResponder];
        }
        else if (_Password==textField)
        {
            [_Password resignFirstResponder];
        }
    }
    
    return YES;
}

- (void)dealloc
{
    CANCEL_REQUEST
}
@end
