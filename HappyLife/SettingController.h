//
//  SettingController.h
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingController : UIViewController<ServiceHelperDelegate>

@property (strong, nonatomic) ServiceHelper *helper;

@end
