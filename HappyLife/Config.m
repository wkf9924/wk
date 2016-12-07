//
//  Config.m
//  Temperature
//
//  Created by 王迪 on 15/4/29.
//

#import "Config.h"

@implementation Config
static Config * instance = nil;
+(Config *) Instance
{
    @synchronized(self)
    {
        if(nil == instance)
        {
            [self new];
        }
    }
    return instance;
}
+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [super allocWithZone:zone];
            return instance;
        }
    }
    return nil;
}

-(void)SavePhoneAndPass:(NSDictionary *)dic
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    [personInformation removeObjectForKey:@"phone"];
    [personInformation setValue:dic forKey:@"phone"];
    [personInformation synchronize];
}

-(NSDictionary *)getPhoneAndPass
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    return     [personInformation objectForKey:@"phone"];
}

-(void)judjeIfBlueToothisBanging:(NSDictionary *)str
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    [personInformation removeObjectForKey:@"BandingStatus"];
    [personInformation setValue:str forKey:@"BandingStatus"];
    [personInformation synchronize];
}

-(NSDictionary *)getBandingStatus
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    return     [personInformation objectForKey:@"BandingStatus"];
}

-(void)isBlueToothConnect:(NSString *)str
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    [personInformation removeObjectForKey:@"bluttoothState"];
    [personInformation setValue:str forKey:@"bluttoothState"];
    [personInformation synchronize];
}

-(BOOL)getBlutToothConnectState
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    NSString *result=[personInformation objectForKey:@"bluttoothState"];
    return [result intValue]==1?YES:NO;
}

-(void)saveBluetoothNo:(NSString *)str;
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    [personInformation removeObjectForKey:@"saveBluetoothNo"];
    [personInformation setValue:str forKey:@"saveBluetoothNo"];
    [personInformation synchronize];
}

-(NSString *)getBlutToothNo
{
    NSUserDefaults *personInformation = [NSUserDefaults standardUserDefaults];
    return     [personInformation objectForKey:@"saveBluetoothNo"];
}

@end

