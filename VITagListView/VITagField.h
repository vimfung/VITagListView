//
//  FAVTagField.h
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/7.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VITagField : UITextField

@property (nonatomic) NSInteger tagSelectedIndex;

/**
 删除键点击事件

 @param handler 事件对象
 */
- (void)onDeleteBackward:(void (^)(void))handler;

@end
