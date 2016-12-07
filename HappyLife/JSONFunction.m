//
//  JsonFunction.m
//  eDiancheDriver
//
//  Created by Mars on 13-6-24.
//  Copyright (c) 2013年 SKTLab. All rights reserved.
//

#import "JSONFunction.h"

@implementation JSONFunction

+ (NSData *) jsonDateWithNSDictionary:(NSDictionary *)dict{
    NSError *error = nil;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if(error == nil)
    {
//		DLog(@"Serialization body: %@",dict);
    }else {
//        DLog(@"Serialization Eror: %@",error);
    }
    return requestBody;
}

+ (id) jsonObjectWithData:(NSData *) data{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if(error == nil)
    {
//		DLog(@"Serialization body: %@",jsonObject);
    }else {
//        DLog(@"Serialization Eror: %@",error);
    }
    return jsonObject;
}

+ (NSString *) jsonStringWithNSDictionary:(NSDictionary *) dict{
    NSData *jsonData = [JSONFunction jsonDateWithNSDictionary:dict];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (id) jsonObjectWithNSString:(NSString *) jsonString{
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [JSONFunction jsonObjectWithData:jsonData];
    return jsonObject;
}

//将NSArray或者NSDictionary转化为NSString
+(NSData*)JSONString:(id)theData

{
    
    NSError* error = nil;
    
    id result = [NSJSONSerialization dataWithJSONObject:theData
                 
                                                options:kNilOptions error:&error];
    
    if (error != nil) return nil;
    
    return result;
    
}

//数组或者字典封装成string
+ (NSString *)dataString:(id)dataTemp {
    NSData *data = [JSONFunction JSONString:dataTemp];
    NSDictionary *s = [JSONFunction jsonObjectWithData:data];
    NSString *string = [JSONFunction jsonStringWithNSDictionary:s];
    return string;
}

//数组转成json串
//NSData *jsonDataa = [JSONFunction JSONString:resultTempArray];
//NSString *jsonString = [[NSString alloc] initWithData:jsonDataa encoding:NSUTF8StringEncoding];

//将statusArray数组转换成  NSString
//NSData *data = [JSONFunction JSONString:_statusArray];
//NSDictionary *s = [JSONFunction jsonObjectWithData:data];
//NSString *string = [JSONFunction jsonStringWithNSDictionary:s];

// 将字典或者数组转化为JSON串

+ (NSData *)toJSONData:(id)theData{
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData
                        
                                                       options:NSJSONWritingPrettyPrinted
                        
                                                         error:&error];
    
    
    
    if ([jsonData length] > 0 && error == nil){
        
        return jsonData;
        
    }else{
        
        return nil;
        
    }
    
    //使用这个方法的返回，我们就可以得到想要的JSON串
    
    //    NSString *jsonString = [[NSString alloc] initWithData:jsonData
    //                                                     encoding:NSUTF8StringEncoding];
    //
}

@end
