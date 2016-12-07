//
//  LocationController.h
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PostLocation)(NSString *city);

@interface LocationController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,weak)IBOutlet UITableView   *m_Tableview;

@property(nonatomic,weak)IBOutlet UILabel       *cityLab;

@property(nonatomic,strong)NSArray              *locationDataArr;

@property(nonatomic,copy) PostLocation          postLocation;

@property(nonatomic,strong)NSString             *currentCity;

@end
