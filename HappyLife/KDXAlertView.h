//
//  GEAlertView.h
//  Grouvent
//
//  Created by Blankwonder on 11/17/12.
//  Copyright (c) 2012 Suixing Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KDXAlertView : NSObject

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
        cancelBlock:(void ( ^)())cancelBlock;

- (void)addButtonWithTitle:(NSString *)title actionBlock:(void ( ^)())actionBlock;
- (void)show;


@end
