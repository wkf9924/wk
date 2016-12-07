//
//  NearByModal.h
//  HappyLife
//
//  Created by mac on 16/4/11.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface NearByModal : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *RSSI;
@property (nonatomic, copy) NSString *UUID;
@property (nonatomic, copy) NSString *name2;
@property (nonatomic, copy) NSString *macAddress;
@property (nonatomic, strong) CBPeripheral *Peripheral;
@end
