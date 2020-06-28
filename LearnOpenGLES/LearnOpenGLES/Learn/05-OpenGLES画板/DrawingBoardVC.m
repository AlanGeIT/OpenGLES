//
//  DrawingBoardVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "DrawingBoardVC.h"
#import "SoundEffect.h"
#import "PaintView.h"

#define kBrightness         1.0     // 亮度
#define kSaturation         0.45    // 饱和度
#define kPaletteHeight      30      // 调色板高度
#define kPaletteSize        4       // 调色板大小
#define kMinEraseInterval   1.0     // 最小擦除区间

//填充率
#define kLeftMargin     10.0
#define kTopMargin      10.0
#define kRightMargin    10.0

@interface DrawingBoardVC (){
    
    SoundEffect     *erasingSound;  // 清除屏幕声音
    SoundEffect     *selectSound;   // 选择颜色声音
    CFTimeInterval  lastTime;
}

@end

@implementation DrawingBoardVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"OpenGLES画板";
    
    // 1.UI实现
    [self setUpUI];
}

#pragma mark - 1.UI实现
- (void)setUpUI
{
    // 1.数组存储颜色选择的图片
    UIImage *redImag = [[UIImage imageNamed:@"Red"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *yellowImag = [[UIImage imageNamed:@"Yellow"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *greenImag =[[UIImage imageNamed:@"Green"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *blueImag = [[UIImage imageNamed:@"Blue"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    NSArray *selectColorImagArr = @[redImag,yellowImag,greenImag,blueImag];
    
    // 2.创建一个分段控件，让用户可以选择画笔颜色
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:selectColorImagArr];
    
    // 3.计算一个矩形的位置，它可以正确设置为用作画笔调色板的分段控件
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
    segmentedControl.frame = frame;

    // 4.为了segmentedControl添加按钮事件--改变画笔颜色
    [segmentedControl addTarget:self action:@selector(changBrushColor:) forControlEvents:UIControlEventValueChanged];

    // 5.设置tintColor & 默认选择
    segmentedControl.tintColor = [UIColor darkGrayColor];
    segmentedControl.selectedSegmentIndex = 2;
    
    [self.view addSubview:segmentedControl];
    
    // 6.定义起始颜色
    // 创建并返回一个颜色对象使用指定的不透明的HSB颜色空间的分量值
    /*
     参数列表：
     Hue:色调 = 选择的index/颜色选择总数
     saturation:饱和度
     brightness:亮度
     */
    CGColorRef color = [UIColor colorWithHue:(CGFloat)2.0/(CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;
    
    // 根据颜色值，返回颜色相关的颜色组件
    const CGFloat *components = CGColorGetComponents(color);
    
    // 8.根据OpenGL视图设置画笔默认颜色
    [(PaintView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
    
    // 9.加载声音--选择颜色声音、清空屏幕颜色
    NSString *erasePath = [[NSBundle mainBundle]pathForResource:@"Erase" ofType:@"caf"];
    NSString *selectPath = [[NSBundle mainBundle]pathForResource:@"Select" ofType:@"caf"];
    
    // 10.根据路径加载声音
    erasingSound = [[SoundEffect alloc] initWithContentsOfFile:erasePath];
    selectSound = [[SoundEffect alloc] initWithContentsOfFile:selectPath];
}

// 改变画笔颜色
-(void)changBrushColor:(id)sender
{
    NSLog(@"Change Color!");
    
    // 1.播放声音
    [selectSound play];
    
    // 2.定义新的画笔颜色，创建并返回一个颜色对象使用指定的不透明的HSB颜色空间的分量值
    CGColorRef color = [UIColor colorWithHue:(CGFloat)[sender selectedSegmentIndex] / (CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;
    
    // 3.获取颜色的组件，红、绿、蓝、alpha颜色值
    const CGFloat *components = CGColorGetComponents(color);
    
    // 4.根据OpenGL视图设置画笔颜色
    [(PaintView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
}

- (IBAction)earse:(id)sender {
    
    // 清理屏幕上的图像
    [self eraseView];
}

// 播放抹去的声音并抹去视图
- (void)eraseView
{
    /*
     参考课件！
     NSDate、CFAbsoluteTimeGetCurrent、CACurrentMedaiTime的区别？
     */
    // 1.防止一直不停的点击清除屏幕！
    // 当前设备时间 > 上一次点击时间 + 间隔时间
    if(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval) {
        
        NSLog(@"清除屏幕！");
        
        // 2.播放系统声音
        [erasingSound play];
        
        // 3.清理屏幕
        [(PaintView *)self.view erase];
        
        // 4.保存这次时间到 lastTime
        lastTime = CFAbsoluteTimeGetCurrent();
    }
}

@end
