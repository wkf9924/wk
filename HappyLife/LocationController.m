//
//  LocationController.m
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "LocationController.h"

@interface LocationController ()

@end

@implementation LocationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"选择地区";
    [self setBackBarButton];
    self.locationDataArr=@[@"西安",@"北京首都",@"上海虹桥",@"广州",@"深圳",@"香港",@"澳门",@"天津",@"成都",@"重庆",@"南京",@"郑州"];
    self.cityLab.text=self.currentCity;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.locationDataArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"identify"];
    if (!cell)
    {
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"identify"];
        cell=[tableView dequeueReusableCellWithIdentifier:@"identify"];
    }
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.textLabel.text=configEmpty(self.locationDataArr[indexPath.row]);
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.postLocation)
    {
        self.postLocation(configEmpty(self.locationDataArr[indexPath.row]));
    }
    [self.navigationController popViewControllerAnimated:YES];
}


@end
