//
//  ServiceHelper.h
//  HttpRequest
//
//  Created by aJia on 2012/10/27.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
@protocol ServiceHelperDelegate
@optional
//非队列异步请求
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request;
-(void)finishFailRequest:(NSError*)error;
//队列异步请求
-(void)finishQueueComplete;
-(void)finishSingleRequestSuccess:(NSString*)xml userInfo:(NSDictionary*)dic;
-(void)finishSingleRequestFailed:(NSError*)error userInfo:(NSDictionary*)dic;
@end

@interface ServiceHelper : NSObject{
     ASINetworkQueue *networkQueue;
}

@property NSInteger numberTag;
@property(nonatomic,assign) id<ServiceHelperDelegate> delegate;
//初始化
-(id)initWithDelegate:(id<ServiceHelperDelegate>)theDelegate;
-(id)initWithQueueDelegate:(id<ServiceHelperDelegate>)theDelegate;


/******设置公有的请求****/
-(ASIHTTPRequest*)commonServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methosName SoapMessage:(NSString*)soapMsg tagType:(NSInteger)num;
+(ASIHTTPRequest*)commonSharedRequestMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg;
+(ASIHTTPRequest*)commonSharedServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methosName SoapMessage:(NSString*)soapMsg;

/******同步请求******/
-(NSDictionary *)syncServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num;
-(NSString*)syncServiceMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num;


/******异步请求******/
-(void)asynServiceRequestUrl:(NSString*)url ServiceNameSpace:(NSString*)nameSapce ServiceMethodName:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num;
-(void)asynServiceMethod:(NSString*)methodName SoapMessage:(NSString*)soapMsg Tag:(NSInteger)num;


/******队列请求******/
//添加队列
-(void)addRequestQueue:(ASIHTTPRequest*)request;
//开始队列
-(void)resetQueue;
-(void)startQueue;


/********对于返回soap信息的处理**********/
-(NSDictionary*)soapMessageResult:(ASIHTTPRequest*)request;
@end
