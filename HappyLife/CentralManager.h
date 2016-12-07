//
//  CentralManager.h
//  HappyLife
//
//  Created by mac on 16/8/25.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralManager : NSObject

+(CentralManager *) Instance;

+(id)allocWithZone:(NSZone *)zone;

@property (nonatomic, strong) CBPeripheral      *discoveredPeripheral;

@property (nonatomic, strong) CBCharacteristic  *writeCharacteristic;


@property (nonatomic,strong)  CBCharacteristic  *A29Characteristric;


@end
