//
//  NSObject+NullConfig.h
//  Toon
//
//  Created by guanglong on 15/8/4.
//  Copyright (c) 2015年 思源. All rights reserved.
//


#define WS(weakSelf)  __weak __typeof(self)weakSelf = self;

#define NSStringWithFormat(...)             [NSString stringWithFormat:__VA_ARGS__]

/**
 *  @author LGL, 15-01-07 12:01:06
 *
 *  @brief  将某个对象，转换成一个非空的字符串，如果对象是空，则转换成 string
 *
 *  @param rawObj 需要进行转换的对象
 *  @param toStr  对象为空时需要转化成的字符串
 *
 *  @return 一个长度大于0的字符串，或者 toStr
 */
#define ConfigEmptyToStr(rawObj, toStr)     \
    (rawObj == nil ||   \
     [rawObj isKindOfClass:[NSNull class]] ||   \
     [rawObj isEqual:@"(null)"] ||  \
     [rawObj isEqual:@"null"]) ?    \
    toStr : [NSString stringWithFormat:@"%@", rawObj]

/**
 *  @author LGL, 15-01-07 13:01:10
 *
 *  @brief  将某个对象(可能为空或者空对象)，转换成一个非空的字符串
 *
 *  @param rawObj 需要进行转换的对象(一般情况下为数值对象)
 *
 *  @return 一个非空的字符串,长度可能为0
 */
#define ConfigEmpty(rawObj)         ConfigEmptyToStr(rawObj, @"")
#define ConfigEmptyZW(rawObj)       ConfigEmptyToStr(rawObj, @"暂无")

/**
 *  @author LGL, 15-01-07 14:01:46
 *
 *  @brief  将某个对象(一般情况下为数值对象),转化成某种形式的字符串
 *
 *  @param rawObj    需要进行转换的对象(一般情况下为数值对象)
 *  @param formatStr 转换后的字符串格式，如:@"价格为%.2f元"。目前只支持%f系列，如:%.0f,%.1f……（0，1，……表示小数的位数）
 *
 *  @return 一个带格式的字符串
 */
#define ConvertWithFormat(rawObj, formatStr)            \
    (![ConfigEmpty(rawObj) length]) ? @"-" : NSStringWithFormat(formatStr, [rawObj floatValue])

/**
 *  @author LGL, 15-01-07 14:01:42
 *
 *  @brief  将某个对象(一般情况下为数值对象),转化成某个带单位的字符串
 *
 *  @param rawObj  需要进行转换的对象(一般情况下为数值对象)
 *  @param unitStr 单位
 *
 *  @return 一个带单位的字符串
 */
#define ConvertWithUnit(rawObj, unitStr)        \
    (![ConfigEmpty(rawObj) length]) ? @"-" : NSStringWithFormat(@"%@%@", rawObj, unitStr)
#define ConvertPrice(rawObj)        \
    ConvertWithFormat(rawObj, @"%.2f元")


#pragma mark - - - 

#import <Foundation/Foundation.h>

// 判断是否为纯数字
BOOL isPureNumStr(NSString* string);

NSString* convertWithFormat(NSString* rawObj, NSString* formatStr);

NSString* convertWithUnit(NSString* rawObj, NSString* unitStr);

NSString* convertPrice(NSString* rawObj);

NSString* configEmptyToStr(id rawObj, NSString* toStr);

NSString* configEmpty(id rawObj);

// 将某个对象(可能为空或者空对象)，转换成一个非空的字符串，如果是对象是空或空对象，则转换成nil
NSString* configNull(id rawObj);

// 将rawObj（要求是一个纯数字对象）转换成一个整数
// 如果rawObj不是一个纯数字对象，则返回“-”，表示未知
NSString* convertPureIntStr(id rawObj);

NSString* configEmptyZW(id rawObj);

NSString* convertEmptyToSpace(NSString* rawObj);

@interface NSObject (NullConfig)


@end
