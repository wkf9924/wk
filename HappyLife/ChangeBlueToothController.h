//
//  ChangeBlueToothController.h
//  HappyLife
//
//  Created by mac on 16/5/18.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ChangeBlueToothController : UIViewController<ServiceHelperDelegate>

@property(nonatomic,strong)ServiceHelper      *helper;

@property(nonatomic,weak)IBOutlet UITextField *textfield;

@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;

@end
