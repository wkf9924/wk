//
//  GEActionSheet.h
//  Grouvent
//
//  Created by Blankwonder on 11/20/12.
//  Copyright (c) 2012 Suixing Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KDXActionSheet : NSObject

- (id)initWithTitle:(NSString *)title
  cancelButtonTitle:(NSString *)cancelButtonTitle
  cancelActionBlock:(void ( ^)())cancelActionBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
destructiveActionBlock:(void ( ^)())destructiveActionBlock;

- (void)addButtonWithTitle:(NSString *)title actionBlock:(void ( ^)())actionBlock;

- (void)showInView:(UIView *)view;

@end
