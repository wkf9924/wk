//
//  OptionController.m
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "OptionController.h"

@interface OptionController ()

@end

@implementation OptionController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"意见反馈";
    [self setDismissBarButton];
    m_text.layer.borderWidth=1;
    m_text.layer.borderColor=[UIColor orangeColor].CGColor;
    m_text.layer.cornerRadius=8;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

-(IBAction)SummitAction:(id)sender
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    if (m_text.text.length>0)
    {
        
        SB_MBPHUD_SHOW(@"提交中...", self.view, NO);
        
        helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],m_text.text],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"SubmitO"];
        [helper asynServiceMethod:@"SubmitO" SoapMessage:soapMsg Tag:100];
    }
}


#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    NSString *resultStr=xml[@"SubmitOResponse"][@"SubmitOResult"][@"text"];
    if ([resultStr intValue]==-1)
    {
        SB_MBPHUD_HIDE(@"提交失败", 3);
    }
    else if ([resultStr intValue]==0)
    {
        SB_MBPHUD_HIDE(@"连接服务器失败", 3);
    }
    else if ([resultStr intValue]==1)
    {
        SB_MBPHUD_HIDE(@"提交成功", 1);
        m_text.text=@"";
    }
}

-(void)finishFailRequest:(NSError*)error
{
     NSLog(@"异步请发生失败:%@\n",[error description]);
     SB_MBPHUD_HIDE(@"请检查网络", 3)
}

- (void)dealloc
{
    CANCEL_REQUEST
}


@end
