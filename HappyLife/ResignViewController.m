//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ResignViewController.h"

@interface ResignViewController ()

@end

@implementation ResignViewController

CGRect rects;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title=@"注册";
    [self setBackBarButton];
    
    ResignBtn.layer.cornerRadius=20;

    for (UIView *line in lines) {
        CGRect rect=line.frame;
        rect.size.height=0.5;
        line.frame=rect;
    }
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

-(IBAction)YzmBtnSelect:(id)sender
{
    if (userName.text.length!=11)
    {
        [UIAlertView showAlertViewWithTitle:@"请输入正确的手机号码!" message:nil];
    }
    
    CANCEL_REQUEST
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    
    Random=[NSString stringWithFormat:@"%d%d%d%d%d%d",arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10];
    SB_MBPHUD_SHOW(@"正在发送验证码...", self.view, NO);
    helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:userName.text,@"Phone", nil]];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:Random,@"Rand", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"CheckRand"];
    [helper asynServiceMethod:@"CheckRand" SoapMessage:soapMsg Tag:200];
}

-(IBAction)ResignBtnPressAction:(UIButton *)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame=rects;
    }completion:^(BOOL finished) {
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
    }];
    NSString *patternPhone = @"^0*(13|15|18|14)\\d{9}$";
    
    NSString* patternPwd = @"^[\\@A-Za-z0-9\\!\\#\\$\\%\\^\\&\\*\\.\\~\\_]{6,14}$";
    
    NSError *error = NULL;
    
    @try {
        
        NSRegularExpression *regexPhone = [NSRegularExpression regularExpressionWithPattern:patternPhone options:0 error:&error];
        
        NSRegularExpression *regexPwd = [NSRegularExpression regularExpressionWithPattern:patternPwd options:0 error:&error];
        
        //使用正则表达式匹配字符
        NSTextCheckingResult *isMatchPhone = [regexPhone firstMatchInString:userName.text
                                                                    options:0
                                                                      range:NSMakeRange(0, [userName.text length])];
        
        NSTextCheckingResult *isMatchPwd = [regexPwd firstMatchInString:Password.text
                                                                options:0
                                                                  range:NSMakeRange(0, [Password.text length])];
        
        //判断注册信息的填写
        if (userName.text.length == 0) {
            
            [UIAlertView showAlertViewWithTitle:@"请输入手机号码!" message:nil];
            return;
        }
        else if (!isMatchPhone){
            [UIAlertView showAlertViewWithTitle:@"请输入正确的手机号码" message:nil];
            return;
        }
        else if (![yzmLab.text isEqualToString:Random])
        {
            [UIAlertView showAlertViewWithTitle:@"请输入正确的验证码" message:nil];
            return;
        }
        else if (Password.text.length ==0){
            
            [UIAlertView showAlertViewWithTitle:@"请输入密码！" message:nil];
            return;
        }
        else if (!isMatchPwd){
            [UIAlertView showAlertViewWithTitle:@"密码必须在六位以上！" message:nil];
            return;
        }
        else if (![Password.text isEqualToString:RPassword.text])
        {
            [UIAlertView showAlertViewWithTitle:@"你两次输入的密码不一样" message:nil];
            return;
        }
        else
        {
            SB_MBPHUD_SHOW(@"注册中...", self.view, NO);
            helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@",userName.text,Password.text,@"西安普瑞米特",[[UIDevice currentDevice].identifierForVendor UUIDString]],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"RegUser1"];
            [helper asynServiceMethod:@"RegUser1" SoapMessage:soapMsg Tag:100];
        }
    }
    @catch (NSException *exception) {
        [UIAlertView showAlertViewWithTitle:@"检查您输入的信息是否正确" message:nil];
    }
    @finally {
        
    }
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{    
    if (request.tag==100)
    {
        //将xml使用SoapXmlParseHelper类转换成想要的结果
        NSString *str=xml[@"RegUser1Response"][@"RegUser1Result"][@"text"];
        if (str==nil||[str intValue]==0)
        {
            SB_MBPHUD_HIDE(@"请检查网络", 3);
        }
        else if ([str isEqualToString:@"-2"])
        {
            SB_MBPHUD_HIDE(@"注册失败", 3);
        }
        else if ([str isEqualToString:@"-1"])
        {
            SB_MBPHUD_HIDE(@"此用户已经注册", 3);
        }
        else if ([str isEqualToString:@"1"])
        {
            SB_MBPHUD_HIDE(@"注册成功,请返回登录", 1);
            helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@",userName.text,Password.text,@"西安普瑞米特",[[UIDevice currentDevice].identifierForVendor UUIDString]],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"RegUser1"];
            [helper asynServiceMethod:@"RegUser1" SoapMessage:soapMsg Tag:300];
        }
    }
    
    else if (request.tag==300)
    {
    
    }

    else if (request.tag==200)
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

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (userName==textField)
    {
        if ([string isEqualToString:@"\n"])
        {
            [Password becomeFirstResponder];
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
    else if (Password==textField)
    {
        if ([string isEqualToString:@"\n"]) {
            [RPassword becomeFirstResponder];
        }
    }
    else if (RPassword==textField)
    {
        if ([string isEqualToString:@"\n"])
        {
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
        }
    }
    return YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    rects=self.view.frame;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame=rects;
    }];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    
    [UIView animateWithDuration:0.35 animations:^{
        CGRect rect=self.view.frame;
        rect.origin.y-=100;
        self.view.frame=rect;
    }];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame=rects;
    }];
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    return YES;
}

- (void)dealloc
{
    CANCEL_REQUEST
}


@end
