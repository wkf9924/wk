//
//  JsonFunction.h
//  eDiancheDriver
//
//  Created by Mars on 13-6-24.
//  Copyright (c) 2013年 SKTLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONFunction : NSObject

// Utillity function
+ (NSData *) jsonDateWithNSDictionary:(NSDictionary *)dict;

+ (id) jsonObjectWithData:(NSData *) data;

+ (NSString *) jsonStringWithNSDictionary:(NSDictionary *) dict;

+ (id) jsonObjectWithNSString:(NSString *) jsonString;

//将NSArray或者NSDictionary转化为NSString
+ (NSData*)JSONString:(id)theData;

// 将字典或者数组转化为JSON串
+ (NSData *)toJSONData:(id)theData;

//数组或者字典封装成string
+ (NSString *)dataString:(id)dataTemp;

@end
