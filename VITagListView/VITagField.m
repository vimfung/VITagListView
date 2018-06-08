//
//  FAVTagField.m
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/7.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import "VITagField.h"

@interface VITagField ()

/**
 删除键点击事件
 */
@property (nonatomic, copy) void (^deleteBackwardHandler)(void);

@end

@implementation VITagField

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self _initView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self _initView];
    }
    return self;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    rect.origin.x = 10;

    return rect;
}

- (void)deleteBackward
{
    if (self.text.length == 0 && self.deleteBackwardHandler)
    {
        self.deleteBackwardHandler();
    }
    
    [super deleteBackward];
}

- (BOOL)keyboardInputShouldDelete:(UITextField *)textField
{
    BOOL shouldDelete = YES;
    
    if ([UITextField instancesRespondToSelector:_cmd])
    {
        BOOL (*keyboardInputShouldDelete)(id, SEL, UITextField *) = (BOOL (*)(id, SEL, UITextField *))[UITextField instanceMethodForSelector:_cmd];
        
        if (keyboardInputShouldDelete) {
            shouldDelete = keyboardInputShouldDelete(self, _cmd, textField);
        }
    }
    
    BOOL isIos8 = ([[[UIDevice currentDevice] systemVersion] intValue] == 8);
    BOOL isLessThanIos8_3 = ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.3f);
    
    if (![textField.text length] && isIos8 && isLessThanIos8_3)
    {
        [self deleteBackward];
    }
    
    return shouldDelete;
}

- (void)onDeleteBackward:(void (^)(void))handler
{
    self.deleteBackwardHandler = handler;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.tagSelectedIndex == -1)
    {
        return [super canPerformAction:action withSender:sender];
    }
    
    return NO;
}

#pragma mark - Private

- (void)_initView
{
    self.layer.cornerRadius = self.bounds.size.height * 0.5;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

@end
