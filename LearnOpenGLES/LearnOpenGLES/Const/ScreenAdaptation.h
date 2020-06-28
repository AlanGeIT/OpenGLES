//
//  ScreenAdaptation.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#ifndef ScreenAdaptation_h
#define ScreenAdaptation_h

/* ************** 适配 ************** */

// 判断是否是ipad
#define isPad               ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define kCurrentMode        [UIScreen instancesRespondToSelector:@selector(currentMode)]
#define kCurrentModeSize    [[UIScreen mainScreen] currentMode].size
// 判断iPhone4系列
#define kiPhone4            (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(640, 960), kCurrentModeSize) && !isPad : NO)
// 判断iPhone5系列
#define kiPhone5            (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(640, 1136), kCurrentModeSize) && !isPad : NO)
// 判断iPhone6系列
#define kiPhone6            (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(750, 1334), kCurrentModeSize) && !isPad : NO)
// 判断iphone6+系列
#define kiPhone6Plus        (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(1242, 2208), kCurrentModeSize) && !isPad : NO)
// 判断iPhoneX
#define IS_IPHONE_X         (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(1125, 2436), kCurrentModeSize) && !isPad : NO)
// 判断iPHoneXr
#define IS_IPHONE_Xr        (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(828, 1792), kCurrentModeSize) && !isPad : NO)
// 判断iPhoneXs
#define IS_IPHONE_Xs        (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(1125, 2436), kCurrentModeSize) && !isPad : NO)
// 判断iPhoneXs Max
#define IS_IPHONE_Xs_Max    (kCurrentMode ? CGSizeEqualToSize(CGSizeMake(1242, 2688), kCurrentModeSize) && !isPad : NO)
// iPhoneX系列
#define IS_IPHONE_X_SERIES  (IS_IPHONE_X==YES || IS_IPHONE_Xr ==YES || IS_IPHONE_Xs== YES || IS_IPHONE_Xs_Max== YES)

#define kWIDTH(width)       (width) * kMainScreenWidth / 375.f                      // 返回相对于iphone6宽的相对尺寸
#define kHEIGHT(height)     (height) * kMainScreenHeight / 667.f                    // 返回相对于iphone6高的相对尺寸

#define kMainScreenWidth    [[UIScreen mainScreen] bounds].size.width                       // 屏幕宽度
#define kMainScreenHeight   [UIScreen mainScreen].bounds.size.height                        // 屏幕高度

#define kStatusbarH         [[UIApplication sharedApplication] statusBarFrame].size.height  // 状态栏高度
#define kNavigationbarH     self.navigationController.navigationBar.height                  // 导航栏高度
#define kTabBarH            (IS_IPHONE_X_SERIES ? 83.0 : 49.0)                              // tabbar高度
#define kTopSafeHeight      IS_IPHONE_X_SERIES ? 44 : 0                                     // 顶部安全区域远离高度
#define kBottomSafeHeight   (IS_IPHONE_X_SERIES ? 34 : 0)                                     // 底部安全区域远离高度

#define kWindow             [AppDelegate shareAppDelegate].window

#endif /* ScreenAdaptation_h */
