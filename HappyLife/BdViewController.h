//
//  BdViewController.h
//  HappyLife
//
//  Created by mac on 16/4/11.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum _BangdingState
{
    OUT_NETWORK,
    NO_PERSON,
    ALREADY_EXIST,
    BEN_BANDING,
    COULD_BANDING
}BangdingState;

@interface BdViewController : UIViewController<ServiceHelperDelegate>
@property(nonatomic,weak)IBOutlet UILabel   *nameLab;

@property(nonatomic,weak)IBOutlet UILabel   *carNumLab;

@property(nonatomic,weak)IBOutlet UILabel   *AddressLab;

@property(nonatomic,weak)IBOutlet UILabel   *BlueToothLab;

@property(nonatomic,strong)ServiceHelper    *helper;

@property(nonatomic,assign)BangdingState     bangdingState;



@end
