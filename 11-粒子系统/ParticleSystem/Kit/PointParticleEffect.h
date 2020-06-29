//
//  PointParticleEffect.h
//  ParticleSystem
//
//  Created by Alan Ge on 2020/6/20.
//  Copyright © 2020 AlanGe. All rights reserved.
//

// 管理并且绘制所有的粒子
// 参数包括初始速度、受力、大小、持续时间、渐隐时间.粒子会根据生命周期进行复用

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
    
NS_ASSUME_NONNULL_BEGIN

/////////////////////////////////////////////////////////////////
// Default gravity acceleration vector matches Earth's
// {0, (-9.80665 m/s/s), 0} assuming +Y up coordinate system
extern const GLKVector3 CCDefaultGravity;// 默认地球重力

@interface PointParticleEffect : NSObject

@property (nonatomic, assign) GLKVector3    gravity;        //重力
@property (nonatomic, assign) GLfloat       elapsedSeconds; //耗时

@property (nonatomic, strong, readonly) GLKEffectPropertyTexture    *texture2d0;    //纹理
@property (nonatomic, strong, readonly) GLKEffectPropertyTransform  *transform;     //变换

// 添加粒子
/*
 aPosition: 位置
 aVelocity: 速度
 aForce: 重力
 aSize: 大小
 aSpan: 跨度
 aDuration: 时长
 */
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

// 准备绘制
- (void)prepareToDraw;

// 绘制
- (void)draw;

@end

NS_ASSUME_NONNULL_END
