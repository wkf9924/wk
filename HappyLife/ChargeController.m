//
//  ChargeController.m
//  HappyLife
//
//  Created by mac on 16/3/22.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ChargeController.h"
#import "DataSigner.h"
#import "DataVerifier.h"
#import "Order.h"
#import "PartnerConfig.h"
#import <AlipaySDK/AlipaySDK.h>
#import "WechatAuthSDK.h"
#import "WXApi.h"
#import "WXApiObject.h"


@interface ChargeController ()<WXApiDelegate,ServiceHelperDelegate>
{
    ServiceHelper *helper;
}
@end

@implementation ChargeController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"支付";
    [self setBackBarButton];
}

-(IBAction)ZfbAction:(id)sender
{
    NSString *partner =PartnerID;
    NSString *seller =SellerID;
    NSString *privateKey = PartnerPrivKey;
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.seller = seller;
    order.tradeNO =[self generateTradeNO];

    order.productName =@"燃气费充值"; //商品标题
    order.productDescription =@"kktt"; //商品描述
    order.amount =@"0.1"; //商品价格
    order.notifyURL =@"http://alipay.youfanfan.com/notify_url.aspx"; //回调URL
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showUrl = @"m.alipay.com";
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"com.easylif.cn";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }

}

-(void)WeChat
{
    [self PayAction];
}

-(IBAction)Yinlian
{
    SB_MBPHUD_SHOW(@"正在接入银联支付", self.view, NO);
    helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    
    NSDateFormatter *dateformat=[[NSDateFormatter alloc] init];
    dateformat.dateFormat=@"yyyyMMddHHmmss";
    NSString *date=[dateformat stringFromDate:[NSDate date]];
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@",[self generateTradeNO],date,@"1"];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"UnionPay"];
    [helper asynServiceMethod:@"UnionPay" SoapMessage:soapMsg Tag:100];
}

- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand(time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

-(NSString *)PayAction
{
    //============================================================
    // V3&V4支付流程实现
    // 注意:参数配置请查看服务器端Demo
    // 更新时间：2015年11月20日
    //============================================================
    NSString *urlString   = @"http://wxpay.weixin.qq.com/pub_v2/app/app_pay.php?plat=ios";
    //解析服务端返回json数据
    NSError *error;
    //加载一个NSURL对象
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    //将请求的url数据放到NSData对象中
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if ( response != nil) {
        NSMutableDictionary *dict = NULL;
        //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
        dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
        
        NSLog(@"url:%@",urlString);
        if(dict != nil){
            NSMutableString *retcode = [dict objectForKey:@"retcode"];
            if (retcode.intValue == 0){
                NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
                
                //调起微信支付
                PayReq* req             = [[PayReq alloc] init];
                req.partnerId           = [dict objectForKey:@"partnerid"];
                req.prepayId            = [dict objectForKey:@"prepayid"];
                req.nonceStr            = [dict objectForKey:@"noncestr"];
                req.timeStamp           = stamp.intValue;
                req.package             = [dict objectForKey:@"package"];
                req.sign                = [dict objectForKey:@"sign"];
                [WXApi sendReq:req];
                //日志输出
                NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
                return @"";
            }else{
                return [dict objectForKey:@"retmsg"];
            }
        }else{
            return @"服务器返回错误，未获取到json对象";
        }
    }else{
        return @"服务器返回错误";
    }
}

- (void)onResp:(BaseResp *)resp {
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
        NSString *strMsg,*strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}


-(void)UPPayPluginResult:(NSString *)result
{
    //充值提醒，您尾号为****的加油卡于yyyyMMddHHss 充值成功，金额****元，订单号：*******
    
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.tag = 200;
    
    NSLog(@"%@",result);
    if ([result isEqualToString:@"success"])
    {
        NSLog(@"--银联支付成功!--");
    }
    if ([result isEqualToString:@"cancel"])
    {
        //[MyAlertView AlertViewTitle:@"取消支付"];
        alert.title = @"取消支付";
        [alert show];
    }
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    NSString *resultStr=configEmpty(xml[@"UnionPayResponse"][@"UnionPayResult"][@"text"]);
    if (resultStr.length>0)
    {
        SB_HUD_HIDE;
        [[UPPaymentControl defaultControl] startPay:resultStr fromScheme:@"ylhappylife" mode:@"01" viewController:self];
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

- (void)dealloc
{
    NSLog(@"-CANCEL_REQUEST");
    CANCEL_REQUEST;
}

@end
