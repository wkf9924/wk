//
//  NSObject+NullConfig.m
//  Toon
//
//  Created by guanglong on 15/8/4.
//  Copyright (c) 2015年 思源. All rights reserved.
//

#import "NSObject+NullConfig.h"
// 判断字符串是纯数字
BOOL isPureNumStr(NSString* string)
{
    if ([string isKindOfClass:[NSString class]] && string.length > 0) {
        
        unichar c;
        for (int i=0; i<string.length; i++) {
            c=[string characterAtIndex:i];
            if (!isdigit(c)) {
                return NO;
            }
        }
        return YES;
    }
    
    return NO;
}

NSString* convertWithFormat(NSString* rawObj, NSString* formatStr)
{
    return (![configEmpty(rawObj) length]) ? @"-" : NSStringWithFormat(formatStr, [rawObj floatValue]);
}

NSString* convertWithUnit(NSString* rawObj, NSString* unitStr)
{
    return (![configEmpty(rawObj) length]) ? @"-" : NSStringWithFormat(@"%@%@", rawObj, unitStr);
}

NSString* convertPrice(NSString* rawObj)
{
    return convertWithFormat(rawObj, @"%.2f元");
    
//    return ConvertPrice(rawObj);
}

NSString* configEmptyToStr(id rawObj, NSString* toStr)
{
    return (rawObj == nil
            || [rawObj isKindOfClass:[NSNull class]]
            || [rawObj isEqual:@"(null)"]
            || [rawObj isEqual:@"null"]) ? toStr : [NSString stringWithFormat:@"%@", rawObj];
}

NSString* configEmpty(id rawObj)
{
    return configEmptyToStr(rawObj, @"");
//    return nil;
}

NSString* configNull(id rawObj)
{
    NSString* str = configEmpty(rawObj);
    if ([str isEqual:@""]) {
        return nil;
    }
    return str;
}

NSString* convertPureIntStr(id rawObj)
{
    NSString* pureIntStr = @"-";
    @try {
        
        if (isPureNumStr(rawObj)) {
            pureIntStr = [NSString stringWithFormat:@"%i", [rawObj intValue]];
        }
    }
    @catch (NSException *exception) {
        
    }
    return pureIntStr;
}

NSString* configEmptyZW(id rawObj)
{
    return configEmptyToStr(rawObj, @"暂无");
}

NSString* convertEmptyToSpace(NSString* rawObj)
{
    NSString* str = configEmpty(rawObj);
    if (!str.length) {
        return @" ";
    }
    else {
        return str;
    }
}

