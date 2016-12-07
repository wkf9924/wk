//
//  ProtectController.m
//  HappyLife
//
//  Created by mac on 16/5/18.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ProtectController.h"

@interface ProtectController ()

@end

@implementation ProtectController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setDismissBarButton];
    self.title=@"账户保护";
        
}

-(IBAction)SwitchTouch:(UISwitch *)sender
{
    SB_MBPHUD_SHOW(@"提交中...", self.view, NO);
    
    helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    
    if (sender.on)
    {
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],@"1"],@"strParm", nil]];
       ;
    }
    else
    {
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],@"0"],@"strParm", nil]];
        ;
    }
    
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"UpdateRegMac"];
    [helper asynServiceMethod:@"UpdateRegMac" SoapMessage:soapMsg Tag:100];
}


#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        NSString *resultStr=xml[@"UpdateRegMacResponse"][@"UpdateRegMacResult"][@"text"];
        if ([resultStr intValue]==1)
        {
            SB_MBPHUD_HIDE(@"操作成功", 1);
        }
        else if ([resultStr intValue]==0)
        {
            SB_MBPHUD_HIDE(@"连接服务器有误", 3);
        }
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
