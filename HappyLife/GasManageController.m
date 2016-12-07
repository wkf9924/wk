//
//  GasManageController.m
//  HappyLife
//
//  Created by mac on 16/3/24.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "GasManageController.h"
#import "MsgView.h"
#import "BdViewController.h"
#import "ChangeBlueToothController.h"

@interface GasManageController ()

@end

@implementation GasManageController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"燃气表管理";
    [self setBackBarButton];
    [self setDoneBarButtonWithSelector:@selector(gotoBanding) andTitle:@"添加"];
    self.BangdingCountArr=[NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self BundlingQuery];
}

-(IBAction)ChangeBlueToothDeviceAction:(id)sender
{
    [self.navigationController pushViewController:[[ChangeBlueToothController alloc] init] animated:YES];
}

-(void)SetScrollview
{
    for (NSLayoutConstraint *contents in self.m_Scrollview.constraints)
    {
        if (contents.firstAttribute==NSLayoutAttributeHeight)
        {
            contents.constant+=60*self.BangdingCountArr.count;
        }
    }
    for (int i=0; i<self.BangdingCountArr.count; i++)
    {
        NSDictionary *dics=[self.BangdingCountArr objectAtIndex:i];
        MsgView *views=[[MsgView alloc] init];
        views.frame=CGRectMake(0, 60*i, winsize.width, 60);
        
        NSLog(@"---frame===%@",NSStringFromCGRect(views.frame));
        [views setLabeltitle:dics];
        [self.m_Scrollview addSubview:views];
        UITapGestureRecognizer *TapGest=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(TapACtion:)];
        [views addGestureRecognizer:TapGest];
        UIView *TapView=[TapGest view];
        TapView.tag=i+100;
    }
}

-(void)TapACtion:(UITapGestureRecognizer *)sender
{
    KDXActionSheet *action=[[KDXActionSheet alloc] initWithTitle:@"是否解除" cancelButtonTitle:@"取消" cancelActionBlock:nil destructiveButtonTitle:@"解除" destructiveActionBlock:^{
        SB_MBPHUD_SHOW(@"解除中...", self.view, NO);
        NSDictionary *dics=[self.BangdingCountArr objectAtIndex:(sender.view.tag-100)];
        self.helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:configEmpty(dics[@"kahao1"][@"text"]),@"strParm",nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"UnBundling"];
        [self.helper asynServiceMethod:@"UnBundling" SoapMessage:soapMsg Tag:200];
    }];
    [action showInView:self.view];
}

-(void)gotoBanding
{
    if (self.BangdingCountArr.count>=5)
    {
        [UIAlertView showAlertViewWithTitle:@"最多只能绑定五个账号" message:nil];
    }
    else
    {
        BdViewController *bdVc=[[BdViewController alloc] init];
        [self.navigationController pushViewController:bdVc animated:YES];
    }
}

//绑定信息查询
-(void)BundlingQuery
{
    self.helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:configEmpty(logerDic[@"phone"]),@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"BundlingQuery"];
    [self.helper asynServiceMethod:@"BundlingQuery" SoapMessage:soapMsg Tag:100];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        id resultObj=xml[@"BundlingQueryResponse"][@"BundlingQueryResult"][@"UserModel"];
        
        [self.BangdingCountArr removeAllObjects];
        if ([resultObj isKindOfClass:[NSDictionary class]])
        {
            [self.BangdingCountArr addObject:resultObj];
        }
        else if ([resultObj isKindOfClass:[NSArray class]])
        {
            [self.BangdingCountArr addObjectsFromArray:resultObj];
        }
        for (UIView *view in _m_Scrollview.subviews) {
            [view removeFromSuperview];
        }
        [self SetScrollview];
    }
    
    else if (request.tag==200)
    {
        NSString *str=configEmpty(xml[@"UnBundlingResponse"][@"UnBundlingResult"][@"text"]);
        if ([str intValue]==1)
        {
            SB_MBPHUD_HIDE(@"解除成功", 1);
            for (UIView *view in _m_Scrollview.subviews) {
                [view removeFromSuperview];
            }
            [self BundlingQuery];
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
