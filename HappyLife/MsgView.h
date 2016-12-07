//
//  MsgView.h
//  HappyLife
//
//  Created by mac on 16/3/26.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MsgView : UIView

@property(nonatomic,weak)IBOutlet UILabel       *nameLab;

@property(nonatomic,weak)IBOutlet UILabel       *numLab;

@property(nonatomic,weak)IBOutlet UILabel       *addressLab;

-(void)setLabeltitle:(NSDictionary *)dic;


@end
