//
//  FAVTagView.h
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/8.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 标签视图
 */
@interface VITagView : UIButton

/**
 索引
 */
@property (nonatomic) NSInteger index;

/**
 标签
 */
@property (nonatomic, copy) NSString *text;

/**
 首选标签字体

 @return 字体对象
 */
+ (UIFont *)preferredTagFont;

@end
