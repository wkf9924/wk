//
//  LeftViewController.h
//  HappyLife
//
//  Created by mac on 16/3/28.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LeftViewController : UIViewController<ServiceHelperDelegate>
{
    ServiceHelper *helper;
}
@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (nonatomic, strong) NSArray           *items;

@property (weak,nonatomic)  IBOutlet UILabel    *phoneLab;

@property (weak,nonatomic)  IBOutlet UILabel    *versionLab;

-(IBAction)ExitAction:(id)sender;

@end
