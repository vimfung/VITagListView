//
//  FAVTagsView.m
//  Tools
//
//  Created by 冯鸿杰 on 2018/6/8.
//  Copyright © 2018年 vimfung. All rights reserved.
//

#import "VITagListView.h"
#import "VITagField.h"
#import "VITagView.h"
#import "VITagLayoutAttributes.h"

static CGFloat FAVTagFieldDefaultWidth = 80;

@interface VITagListView () <UIScrollViewDelegate, UITextFieldDelegate>

/**
 标签数组
 */
@property (nonatomic, strong) NSMutableArray<NSString *> *tagArray;

/**
 标签排版属性集合
 */
@property (nonatomic, strong) NSMutableArray<VITagLayoutAttributes *> *tagLayoutAttributesArray;

/**
 可见区域
 */
@property (nonatomic) CGRect visibleRect;

/**
 上一次的内容偏移
 */
@property (nonatomic) CGPoint prevContentOffset;

/**
 最后的排版定位，用于计算textField的位置
 */
@property (nonatomic) CGPoint lastLayoutPoint;

/**
 起始显示索引
 */
@property (nonatomic) NSInteger startIndex;

/**
 结束显示索引
 */
@property (nonatomic) NSInteger endIndex;

/**
 显示的标签集合
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, VITagView *> *visibleTagsDict;

/**
 复用的标签集合
 */
@property (nonatomic, strong) NSMutableArray<VITagView *> *reuseTagsArray;

/**
 标签输入文本框
 */
@property (nonatomic, strong) VITagField *tagInputField;

/**
 菜单控制器
 */
@property (nonatomic, strong) UIMenuController *menuController;

/**
 菜单隐藏观察者
 */
@property (nonatomic, strong) id menuHideObserver;

@end

@implementation VITagListView

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.menuHideObserver];
}

- (NSArray *)tags
{
    return self.tagArray;
}

- (CGFloat)itemHeight
{
    if (_itemHeight == 0)
    {
        return 30;
    }
    
    return _itemHeight;
}

- (void)setTextFieldPlaceholder:(NSString *)textFieldPlaceholder
{
    self.tagInputField.placeholder = textFieldPlaceholder;
}

- (NSString *)textFieldPlaceholder
{
    return self.tagInputField.placeholder;
}

#pragma mark - Private

/**
 初始化视图
 */
- (void)_initView
{
    __weak typeof(self) theView = self;
    
    self.clipsToBounds = YES;
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;

    self.tagArray = [NSMutableArray array];
    self.tagLayoutAttributesArray = [NSMutableArray array];
    self.visibleTagsDict = [NSMutableDictionary dictionary];
    self.reuseTagsArray = [NSMutableArray array];
    
    //初始化菜单
    self.menuController = [UIMenuController sharedMenuController];
    
    UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"删除", @"") action:@selector(_deleteTagHandler:)];
    self.menuController.menuItems = @[deleteMenuItem];
    
    //初始化输入框
    self.tagInputField = [[VITagField alloc] initWithFrame:CGRectMake(0, 0, FAVTagFieldDefaultWidth, self.itemHeight)];
    self.tagInputField.delegate = self;
    self.tagInputField.returnKeyType = UIReturnKeyDone;
    self.tagInputField.font = [VITagView preferredTagFont];
    self.tagInputField.placeholder = NSLocalizedString(@"输入标签", @"");
    [self.tagInputField addTarget:self
                           action:@selector(_textChangedHandler:)
                 forControlEvents:UIControlEventEditingChanged];
    
    //监听输入框的删除按键，在没有文本的情况下删除最后一个标签
    [self.tagInputField onDeleteBackward:^{
       
        if (theView.tagInputField.tagSelectedIndex == -1)
        {
            //选中最后一个标签
            theView.tagInputField.tagSelectedIndex = theView.tagArray.count - 1;
            [theView _updateTagLayout];
        }
        else
        {
            //移除选中标签
            [theView.tagArray removeObjectAtIndex:theView.tagInputField.tagSelectedIndex];
            theView.tagInputField.tagSelectedIndex = -1;
            [theView _reloadData];
            
            //隐藏菜单
            [self.menuController setMenuVisible:NO animated:YES];
        }

    }];
    [self addSubview:self.tagInputField];
    
    self.tagMaxLength = 20;
    self.itemGap = 7;
    self.visibleRect = self.bounds;
    self.tagInputField.tagSelectedIndex = -1;
    self.startIndex = 0;
    self.endIndex = self.tagArray.count - 1;
    self.lastLayoutPoint = CGPointMake(self.itemGap, self.itemGap);

    [self _updateTagFieldLayout];

    [self.tagInputField becomeFirstResponder];
    
}

/**
 重新加载数据
 */
- (void)_reloadData
{
    //计算所有标签的位置
    [self.tagLayoutAttributesArray removeAllObjects];
    
    __block CGFloat left = self.itemGap;
    __block CGFloat top = self.itemGap;
    
    __weak typeof(self) theView = self;
    [self.tagArray enumerateObjectsUsingBlock:^(NSString * _Nonnull tag, NSUInteger idx, BOOL * _Nonnull stop) {
       
        VITagLayoutAttributes *attrs = [[VITagLayoutAttributes alloc] init];
        
        CGSize tagSize = [tag sizeWithAttributes:@{NSFontAttributeName : [VITagView preferredTagFont]}];
        tagSize.width += 30;
        tagSize.height = theView.itemHeight;
        
        if (left + tagSize.width + theView.itemGap > theView.bounds.size.width)
        {
            //换行
            left = theView.itemGap;
            top += theView.itemHeight + theView.itemGap;
        }
        
        attrs.frame = CGRectMake(left, top, tagSize.width, tagSize.height);
        [theView.tagLayoutAttributesArray addObject:attrs];
        
        left += tagSize.width + theView.itemGap;
        
    }];
    
    self.lastLayoutPoint = CGPointMake(left, top);
    
    [self _updateTagLayout];
    [self _updateTagFieldLayout];
}

/**
 排版内容
 */
- (void)_updateTagLayout
{
    //计算显示区域内的标签起始索引和结束索引
    CGFloat yOffset = self.contentOffset.y - self.prevContentOffset.y;
    
    if (yOffset > 0)
    {
        //上滑
        //以endIndex为基准点计算上限和下限
        for (NSInteger i = self.endIndex; i >= 0 && i < self.tagLayoutAttributesArray.count; i--)
        {
            VITagLayoutAttributes *attrs = self.tagLayoutAttributesArray[i];
            if (attrs.frame.origin.y + attrs.frame.size.height > self.visibleRect.origin.y - 15)
            {
                self.startIndex = i;
            }
            else
            {
                break;
            }
        }
        
        for (NSInteger i = self.endIndex; i < self.tagLayoutAttributesArray.count; i++)
        {
            VITagLayoutAttributes *attrs = self.tagLayoutAttributesArray[i];
            if (attrs.frame.origin.y < self.visibleRect.origin.y + self.visibleRect.size.height + 15)
            {
                self.endIndex = i;
            }
            else
            {
                break;
            }
        }
        
    }
    else
    {
        //下滑
        //以startIndex为基准点计算上限和下限
        for (NSInteger i = self.startIndex; i < self.tagLayoutAttributesArray.count; i++)
        {
            VITagLayoutAttributes *attrs = self.tagLayoutAttributesArray[i];
            if (attrs.frame.origin.y < self.visibleRect.origin.y + self.visibleRect.size.height + 15)
            {
                self.endIndex = i;
            }
            else
            {
                break;
            }
        }
        
        for (NSInteger i = self.startIndex; i >= 0 && i < self.tagLayoutAttributesArray.count; i--)
        {
            VITagLayoutAttributes *attrs = self.tagLayoutAttributesArray[i];
            if (attrs.frame.origin.y + attrs.frame.size.height > self.visibleRect.origin.y - 15)
            {
                self.startIndex = i;
            }
            else
            {
                break;
            }
        }
    }
    
    //排版标签
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    for (NSInteger i = self.startIndex; i <= self.endIndex && i < self.tagLayoutAttributesArray.count; i++)
    {
        NSNumber *index = @(i);
        VITagLayoutAttributes *attrs = self.tagLayoutAttributesArray[i];
        
        //先从可视列表中View
        VITagView *tagView = [self.visibleTagsDict objectForKey:index];
        if (!tagView)
        {
            //检测是否有复用View
            tagView = self.reuseTagsArray.lastObject;
            [self.reuseTagsArray removeLastObject];
            
            if (!tagView)
            {
                //创建View
                tagView = [[VITagView alloc] initWithFrame:attrs.frame];
                [tagView addTarget:self
                            action:@selector(_tagViewClickedHandler:)
                  forControlEvents:UIControlEventTouchUpInside];
            }
            [self addSubview:tagView];
        }
        
        tagView.index = i;
        tagView.selected = self.tagInputField.tagSelectedIndex == i;
        tagView.frame = attrs.frame;
        tagView.text = self.tagArray[i];
        
        [tmpDict setObject:tagView forKey:index];
        [self.visibleTagsDict removeObjectForKey:index];
    }
    
    __weak typeof(self) theView = self;
    [self.visibleTagsDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, VITagView * _Nonnull obj, BOOL * _Nonnull stop) {
        
        [theView.reuseTagsArray addObject:obj];
        [obj removeFromSuperview];
        
    }];
    
    [self.visibleTagsDict removeAllObjects];
    [self.visibleTagsDict addEntriesFromDictionary:tmpDict];
}


/**
 更新标签输入框排版
 */
- (void)_updateTagFieldLayout
{
    [self.tagInputField sizeToFit];
    CGSize contentSize = self.tagInputField.bounds.size;
    contentSize.width += 20;
    if (contentSize.width < FAVTagFieldDefaultWidth)
    {
        contentSize.width = FAVTagFieldDefaultWidth;
    }
    
    CGFloat left = self.lastLayoutPoint.x;
    CGFloat top = self.lastLayoutPoint.y;
    
    if (left + contentSize.width + self.itemGap > self.bounds.size.width)
    {
        //换行
        if (left > self.itemGap + 0.5)
        {
            //textField在非第一个元素时进行换行
            left = self.itemGap;
            top += self.itemHeight + self.itemGap;
        }
    }
    
    CGRect frame = self.tagInputField.frame;
    frame.origin.x = left;
    frame.origin.y = top;
    frame.size.width = contentSize.width;
    frame.size.height = self.itemHeight;
    self.tagInputField.frame = frame;
    [self.tagInputField layoutIfNeeded];
    
    //设置contentSize
    self.contentSize = CGSizeMake(self.bounds.size.width, top + self.itemHeight + self.itemGap);
    [self scrollRectToVisible:self.visibleRect animated:YES];
}

/**
 文本变更事件

 @param sender 事件对象
 */
- (void)_textChangedHandler:(id)sender
{
    if (self.tagInputField.tagSelectedIndex != -1)
    {
        //取消标签选中
        self.tagInputField.tagSelectedIndex = -1;
        [self _updateTagLayout];
    }
    
    [self _updateTagFieldLayout];
}


/**
 标签视图点击事件

 @param tagView 标签视图
 */
- (void)_tagViewClickedHandler:(VITagView *)tagView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.menuHideObserver];
    
    if (self.tagInputField.tagSelectedIndex != tagView.index)
    {
        self.tagInputField.tagSelectedIndex = tagView.index;
        
        //判断是否能够正常显示菜单项
        CGRect tagViewRect = [self convertRect:tagView.frame toView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
        if (tagViewRect.origin.y >= 44)
        {
            self.menuController.arrowDirection = UIMenuControllerArrowDown;
        }
        else
        {
            self.menuController.arrowDirection = UIMenuControllerArrowUp;
        }
        
        [self.menuController setTargetRect:tagView.bounds inView:tagView];
        [self.menuController setMenuVisible:YES animated:YES];
        
        __weak typeof(self) theView = self;
        self.menuHideObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerDidHideMenuNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            
            if (theView.tagInputField.tagSelectedIndex != -1)
            {
                theView.tagInputField.tagSelectedIndex = -1;
                [theView _updateTagLayout];
            }
            
            //移除监听
            [[NSNotificationCenter defaultCenter] removeObserver:theView.menuHideObserver];
            
        }];
    }
    else
    {
        self.tagInputField.tagSelectedIndex = -1;
        [self.menuController setMenuVisible:NO animated:YES];
    }
    
    [self _updateTagLayout];
}


/**
 删除菜单项点击事件

 @param sender 事件对象
 */
- (void)_deleteTagHandler:(id)sender
{
    if (self.tagInputField.tagSelectedIndex != -1)
    {
        [self.tagArray removeObjectAtIndex:self.tagInputField.tagSelectedIndex];
        self.tagInputField.tagSelectedIndex = -1;
        [self _reloadData];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat yOffset = 0;
    if (@available(iOS 11, *))
    {
        yOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    }
    else
    {
        yOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
    }
    self.visibleRect = CGRectMake(0,
                                  yOffset,
                                  scrollView.bounds.size.width,
                                  yOffset + scrollView.bounds.size.height);
    
    [self _updateTagLayout];
    
    self.prevContentOffset = self.contentOffset;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length - range.length + string.length > self.tagMaxLength)
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *tag = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (tag.length == 0)
    {
        return NO;
    }
    
    //清空内容
    textField.text = @"";
    textField.frame = CGRectMake(0, 0, FAVTagFieldDefaultWidth, self.itemHeight);
    
    [self.tagArray addObject:tag];
    [self _reloadData];
    
    return NO;
}

@end
