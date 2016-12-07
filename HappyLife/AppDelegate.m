//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import <AlipaySDK/AlipaySDK.h>
#import "ChildController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [WXApi registerApp:@"wx33467def475933e7" withDescription:@"demo 2.0"];

    [[Config Instance] isBlueToothConnect:@"0"];
    
//    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
//    NSMutableArray *verSionArr=[NSMutableArray array];
//    [verSionArr addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"西安普瑞米特",@"strParm",nil]];
//    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:verSionArr methodName:@"Version"];
//    [_helper asynServiceMethod:@"Version" SoapMessage:soapMsg Tag:200];
    
//    NSDictionary *logDic=[[Config Instance] getPhoneAndPass];
//    NSString *phone=configEmpty(logDic[@"phone"]);
//    NSString *pass=configEmpty(logDic[@"pass"]);
//    if (pass.length>0&&phone.length>0)
//    {
//        
//        self.helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
//        NSMutableArray *arr=[NSMutableArray array];
//        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",phone,pass],@"strParm", nil]];
//        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"LogUser"];
//        [self.helper asynServiceMethod:@"LogUser" SoapMessage:soapMsg Tag:100];
//    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary*)options
{
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
    }
    
    //银联支付结果
    else if ([url.host isEqualToString:@"uppayresult"])
    {
        [[UPPaymentControl defaultControl]handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data)
        {
            NSString * num;
            if ([code isEqualToString:@"success"])
            {
                NSLog(@"----支付成功----");
                num=@"1";
            }
            else if([code isEqualToString:@"fail"]) {
                //交易失败
                num=@"2";
            }
            else if([code isEqualToString:@"cancel"]) {
                //交易取消
                num=@"3";
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"yinlianPay" object:num];
        }];
    }
    
    else if ([url.host isEqualToString:@"pay"])
    {
         [WXApi handleOpenURL:url delegate:self];
    }

    return YES;
}

- (void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
        NSString *strMsg,*strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"yinlianPay" object:@"1"];
                break;
                
            default:
                strMsg = @"支付失败";
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"yinlianPay" object:@"0"];
                break;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

//- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
//{
//    return [self applicationOpenURL:url];
//}
//
//- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary*)options
//{
//    return [self applicationOpenURL:url];
//}
//
//- (BOOL)applicationOpenURL:(NSURL *)url
//{
////    if([[url absoluteString] rangeOfString:@"wx000000000000://pay"].location == 0) //你的微信开发者appid
//        return [WXApi handleOpenURL:url delegate:self];
//}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==200)
    {
        NSString *version=xml[@"VersionResponse"][@"VersionResult"][@"text"];
        NSString *code=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        if ([[version componentsSeparatedByString:@"|"][0] intValue]>[code intValue])
        {
            KDXAlertView *alert=[[KDXAlertView alloc] initWithTitle:@"有新版本更新" message:nil cancelButtonTitle:@"确定" cancelBlock:^{
                
            }];
            [alert addButtonWithTitle:@"取消" actionBlock:nil];
            [alert show];
        }
    }
//    else if (request.tag==100)
//    {
//        NSString *str=xml[@"LogUserResponse"][@"LogUserResult"][@"text"];
//        if ([str intValue]==1)
//        {
//            LeftViewController *leftVc=[[LeftViewController alloc] init];
//            RootViewController *rootVc=[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RootViewController"];
//            self.window.rootViewController=[[ChildController alloc] initWithCenterVC:rootVc CleftVC:leftVc];
//        }
//        else
//        {
//            self.window.rootViewController=[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LogInViewController"];
//        }
//    }
}

-(void)finishFailRequest:(NSError*)error
{
                NSLog(@"异步请发生失败:%@\n",[error description]);
                SB_MBPHUD_HIDE(@"请检查网络", 3)
}


@end
