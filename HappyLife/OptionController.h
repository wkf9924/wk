//
//  OptionController.h
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionController : UIViewController<ServiceHelperDelegate>
{
    ServiceHelper           *helper;
    IBOutlet UITextView     *m_text;
}

@end
