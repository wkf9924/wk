//
//  AppDelegate.h
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WXApi.h>
#import "UPPaymentControl.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,ServiceHelperDelegate,WXApiDelegate>

@property (strong, nonatomic) UIWindow      *window;

@property (strong, nonatomic) ServiceHelper *helper;


@end

