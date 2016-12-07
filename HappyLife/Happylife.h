//
//  Happylife.h
//  HappyLife
//
//  Created by mac on 16/3/19.
//  Copyright © 2016年 mac. All rights reserved.
//


//测试服
#define  defaultWebServiceUrl  @"http://125.76.225.60/GasPay/GasPayService.asmx"

//总库
#define  DNSURL                @"http://125.76.225.60/GasPaySer/GasPaySer.asmx"

#define defaultWebServiceNameSpace @"http://rmturi.org/"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//显示加载状态
#define SB_MBPHUD_SHOW(str,view,yesorno)    [SBPublicAlert showMBProgressHUD:str andWhereView:view states:yesorno];
//提示网络加载错误等相关信息
#define SB_MBPHUD_HIDE(str,numSuccess)      [SBPublicAlert hideYESMBprogressHUDcontent:str isSuccess:numSuccess];
//隐藏提示框
#define SB_HUD_HIDE                         [SBPublicAlert hideMBprogressHUD:self.view];

//显示提示框　　只显示文字， theTime后消失
#define SB_SHOW_Time_HIDE(str,view,time)    [SBPublicAlert showMBProgressHUD:str andWhereView:view hiddenTime:time];
#define winsize                             [UIScreen mainScreen].bounds.size



//判断是否有网络
#define NET_WORK [NetworkUtil canConnect]

//取消网络请求

#define CANCEL_REQUEST     for (ASIHTTPRequest *request in [ASIHTTPRequest sharedQueue].operations) {\
[request clearDelegatesAndCancel];\
}\


/****************取消请求*****************/
#define Request_Cancel  for (ASIHTTPRequest *request in [ASIHTTPRequest sharedQueue].operations) {\
[request clearDelegatesAndCancel];\
}\
