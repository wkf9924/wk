//
//  ServiceHelper.m
//  HttpRequest
//
//  Created by aJia on 2012/10/27.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ServiceHelper.h"
#import "SoapXmlParseHelper.h"
#import "XMLReader.h"
#import "JSONFunction.h"
#import "ASIFormDataRequest.h"
@implementation ServiceHelper
@synthesize delegate;
#pragma mark -
#pragma mark 初始化操作
-(id)initWithDelegate:(id<ServiceHelperDelegate>)theDelegate
{
	if (self=[super init]) {
		self.delegate=theDelegate;
	}
	return self;
}
-(id)initWithQueueDelegate:(id<ServiceHelperDelegate>)theDelegate{
    if (self=[super init]) {
		self.delegate=theDelegate;
        networkQueue=[[ASINetworkQueue alloc] init];
	}
	return self;
}
#pragma mark -
#pragma mark 获取公有请求的ASIHTTPRequest
-(ASIHTTPRequest*)commonServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methosName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num{
    NSURL *webUrl=[NSURL URLWithString:url];
    ASIHTTPRequest *request=[ASIHTTPRequest requestWithURL:webUrl];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMsg length]];
	
    //以下对请求信息添加属性前四句是必有的，第五句是soap信息。
	[request addRequestHeader:@"Host" value:[webUrl host]];
    [request addRequestHeader:@"Content-Type" value:@"text/xml; charset=utf-8"];
	[request addRequestHeader:@"Content-Length" value:msgLength];
    [request addRequestHeader:@"SOAPAction" value:[NSString stringWithFormat:@"%@%@",nameSapce,methosName]];
    [request setRequestMethod:@"POST"];
    request.tag = num;
    //设置用户信息
    [request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:methosName,@"name", nil]];
	//传soap信息
    [request appendPostData:[soapMsg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValidatesSecureCertificate:NO];
    [request setTimeOutSeconds:10.0];//表示30秒请求超时
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    return request;
}
+(ASIHTTPRequest*)commonSharedServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methosName SoapMessage:(NSString*)soapMsg{
    NSURL *webUrl=[NSURL URLWithString:url];
    ASIHTTPRequest *request=[ASIHTTPRequest requestWithURL:webUrl];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMsg length]];
	
    //以下对请求信息添加属性前四句是必有的，第五句是soap信息。
	[request addRequestHeader:@"Host" value:[webUrl host]];
    [request addRequestHeader:@"Content-Type" value:@"text/xml; charset=utf-8"];
	[request addRequestHeader:@"Content-Length" value:msgLength];
    [request addRequestHeader:@"SOAPAction" value:[NSString stringWithFormat:@"%@%@",nameSapce,methosName]];
    [request setRequestMethod:@"POST"];
    //设置用户信息
    //[request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:methosName,@"name", nil]];
	//传soap信息
    [request appendPostData:[soapMsg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValidatesSecureCertificate:NO];
    [request setTimeOutSeconds:10.0];//表示30秒请超时
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    return request;

}
+(ASIHTTPRequest*)commonSharedRequestMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg{
    return [self commonSharedServiceRequestUrl:defaultWebServiceUrl ServiceNameSpace:defaultWebServiceNameSpace ServiceMethodName:methodName SoapMessage:soapMsg];
}
#pragma mark -
#pragma mark 同步请求
-(NSDictionary *)syncServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num{
    ASIHTTPRequest *request=[self commonServiceRequestUrl:url ServiceNameSpace:nameSapce ServiceMethodName:methodName SoapMessage:soapMsg Tag:num];
    //设置同步
    [request startSynchronous];
    //处理返回的结果
    return [self soapMessageResult:request];
}
-(NSDictionary *)syncServiceMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num{
    return [self syncServiceRequestUrl:defaultWebServiceUrl ServiceNameSpace:defaultWebServiceNameSpace ServiceMethodName:methodName SoapMessage:soapMsg Tag:num];
}
#pragma mark -
#pragma mark 异步请求  //wkf  add  num 标记多次请求
-(void)asynServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num{
     ASIHTTPRequest *request=[self commonServiceRequestUrl:url ServiceNameSpace:nameSapce ServiceMethodName:methodName SoapMessage:soapMsg Tag:num];
    
    [request setDelegate:self];
    //异步请求
	[request startAsynchronous];
}

/*
 *
 *  @param methodName 方法名
 *  @param soapMsg    拼接的xml参数
 */
-(void)asynServiceMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num{
    
    if ([methodName isEqualToString:@"Version"]||([methodName isEqualToString:@"RegUser1"]&&num==300)||([methodName isEqualToString:@"PurchaseGas"]&&num==6000)||([methodName isEqualToString:@"GouQiU"]&&num==7000)||([methodName isEqualToString:@"FindPassword"]&&num==200)||([methodName isEqualToString:@"ChangeB"]&&num==200)||([methodName isEqualToString:@"BluetoothOrConnection"])||([methodName isEqualToString:@"Bunding"]&&num==400))
    {
        [self asynServiceRequestUrl:DNSURL ServiceNameSpace:defaultWebServiceNameSpace ServiceMethodName:methodName SoapMessage:soapMsg Tag:num];
        return;
    }
    [self asynServiceRequestUrl:defaultWebServiceUrl ServiceNameSpace:defaultWebServiceNameSpace ServiceMethodName:methodName SoapMessage:soapMsg Tag:num];
}

#pragma mark -
#pragma mark ASIHTTPRequest delegate Methods
- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSDictionary *result=[self soapMessageResult:request];

	[self.delegate finishSuccessRequest:result ASIRequest:request];
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	[self.delegate finishFailRequest:error];
}

#pragma mark -
#pragma mark 队列请求
//开始排列
-(void)resetQueue{
    if (!networkQueue) {
        networkQueue = [[ASINetworkQueue alloc] init];
    }
    [networkQueue reset];
    //表示队列操作完成
    [networkQueue setQueueDidFinishSelector:@selector(queueFetchComplete:)];
    [networkQueue setRequestDidFinishSelector:@selector(requestFetchComplete:)];
    [networkQueue setRequestDidFailSelector:@selector(requestFetchFailed:)];
    [networkQueue setDelegate:self];
}
-(void)startQueue{
    [networkQueue go];
}
//添加队列
-(void)addRequestQueue:(ASIHTTPRequest*)request{
    [networkQueue addOperation:request];
}
//队列请求处理
-(void)queueFetchComplete:(ASIHTTPRequest*)request{
    [self.delegate finishQueueComplete];
}
-(void)requestFetchComplete:(ASIHTTPRequest*)request{
   
	NSDictionary *resultDic=[self soapMessageResult:request];
    //wkf
    NSString *result = [JSONFunction jsonStringWithNSDictionary:resultDic];
    [self.delegate finishSingleRequestSuccess:result userInfo:[request userInfo]];
    
}
-(void)requestFetchFailed:(ASIHTTPRequest*)request{
    [self.delegate finishSingleRequestFailed:[request error] userInfo:[request userInfo]];
}
#pragma mark -
#pragma mark 对于返回soap信息的处理
/********对于返回soap信息的处理**********/
-(NSDictionary*)soapMessageResult:(ASIHTTPRequest*)request{
    int statusCode = [request responseStatusCode];
    NSError *error=[request error];
    //如果发生错误，就返回空
    if (error||statusCode!=200) {
        return @{};
    }
	NSString *soapAction=[[request requestHeaders] objectForKey:@"SOAPAction"];
    NSString *methodName=@"";
    NSRange range = [soapAction  rangeOfString:@"/" options:NSBackwardsSearch];
    if(range.location!=NSNotFound){
        int pos=(int)range.location;
        methodName=[soapAction stringByReplacingCharactersInRange:NSMakeRange(0, pos+1) withString:@""];
    }
    NSError *errors=nil;
    NSDictionary *dic=[XMLReader dictionaryForXMLData:[request.responseData retain] error:&errors][@"soap:Envelope"][@"soap:Body"];
    return dic;
}
-(void)dealloc{
    if (networkQueue) {
        [networkQueue reset];
        [networkQueue release];
    }
    
    
	[super dealloc];
}
@end
