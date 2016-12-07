//
//  GasManageController.h
//  HappyLife
//
//  Created by mac on 16/3/24.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GasManageController : UIViewController<ServiceHelperDelegate>

@property(nonatomic,weak)IBOutlet UIScrollView *m_Scrollview;

@property(nonatomic,strong)ServiceHelper       *helper;

//存放绑定查询的结果
@property(nonatomic,strong)NSMutableArray      *BangdingCountArr;

@end
