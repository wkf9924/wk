//
//  Config.h
//  Temperature
//
//  Created by 王迪 on 15/4/29.
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

+(Config *) Instance;
+(id)allocWithZone:(NSZone *)zone;

//保存账号密码
-(void)SavePhoneAndPass:(NSDictionary *)dic;
-(NSDictionary *)getPhoneAndPass;

/**
 *蓝牙是否绑定,
 *0没有绑定
 *1已经绑定
 */
-(void)judjeIfBlueToothisBanging:(NSDictionary *)str;
-(NSDictionary *)getBandingStatus;

//蓝牙连接状态
-(void)isBlueToothConnect:(NSString *)str;
-(BOOL)getBlutToothConnectState;

//保存蓝牙编号
-(void)saveBluetoothNo:(NSString *)str;
-(NSString *)getBlutToothNo;

@end
