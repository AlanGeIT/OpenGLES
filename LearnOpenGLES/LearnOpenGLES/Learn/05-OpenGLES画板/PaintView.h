//
//  PaintView.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

// 导入OpenGL ES 相关类库
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface PaintPoint : NSObject

// 屏幕上的点（x,y）
@property (nonatomic , strong) NSNumber* mY;
@property (nonatomic , strong) NSNumber* mX;

@end

@interface PaintView : UIView

// location 最新的点
@property(nonatomic, readwrite) CGPoint location;
// previousLocation 前一个点
@property(nonatomic, readwrite) CGPoint previousLocation;

// 清屏
- (void)erase;

// 设置画笔颜色
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

// 绘制
- (void)paint;

@end
