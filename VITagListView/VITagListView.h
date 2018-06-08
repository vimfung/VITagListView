//
//  FAVTagsView.h
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/8.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 标签视图
 */
@interface VITagListView : UIScrollView

/**
 标签列表
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *tags;

/**
 文本输入框提示信息
 */
@property (nonatomic, copy) NSString *textFieldPlaceholder;

/**
 单个标签最大长度
 */
@property (nonatomic) NSInteger tagMaxLength;

/**
 标签项高度
 */
@property (nonatomic) CGFloat itemHeight;

/**
 标签间距
 */
@property (nonatomic) CGFloat itemGap;

@end
