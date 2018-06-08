//
//  FAVTagView.m
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/8.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import "VITagView.h"

@implementation VITagView

+ (UIFont *)preferredTagFont
{
    return [UIFont systemFontOfSize:14];
}

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

- (void)setText:(NSString *)text
{
    _text = [text copy];
    
    [self setTitle:_text forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected)
    {
        self.backgroundColor = [UIColor colorWithRed:0x82 / 255.0
                                               green:0xc3 / 255.0
                                                blue:0x39 / 255.0
                                               alpha:1];
        
    }
    else
    {
        self.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Private

- (void)_initView
{
    self.layer.cornerRadius = self.frame.size.height * 0.5;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:0x82 / 255.0
                                             green:0xc3 / 255.0
                                              blue:0x39 / 255.0
                                             alpha:1].CGColor;
    
    self.titleLabel.font = [VITagView preferredTagFont];
    [self setTitleColor:[UIColor colorWithRed:0x82 / 255.0
                                        green:0xc3 / 255.0
                                         blue:0x39 / 255.0
                                        alpha:1]
               forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
}

@end
