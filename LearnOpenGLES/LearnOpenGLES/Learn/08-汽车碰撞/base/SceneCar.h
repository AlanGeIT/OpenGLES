//
//  SceneCar.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SceneCarModel.h"

@protocol SceneCarControllerProtocol

-(NSTimeInterval)timeSinceLastUpdate;
//get方法
-(SceneAxisAllignedBoundingBox)rinkBoundingBox;
-(NSArray *)cars;

@end

@interface SceneCar : NSObject

@property(nonatomic,assign)long mCarID;

@property(nonatomic,strong)SceneModel *model;

@property(nonatomic,assign)GLKVector3 position;

@property(nonatomic,assign)GLKVector3 nextPosition;

//速度
@property(nonatomic,assign)GLKVector3 velocity;

//偏航弧度
@property(nonatomic,assign)GLfloat yawRadians;

//目标偏航弧度
@property(nonatomic,assign)GLfloat targetYawRadians;

//颜色
@property(nonatomic,assign)GLKVector4 color;

//半径
@property(nonatomic,assign)GLfloat radius;


- (id)initWithModel:(SceneModel *)aModel
           position:(GLKVector3)aPosition
           velocity:(GLKVector3)aVelocity
              color:(GLKVector4)aColor;
// 更新汽车信息
- (void)updateWithController: (id <SceneCarControllerProtocol>)controller;
// 绘制
- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect;
// 获取碰撞次数
+ (long)getBounceCount;
// 调整汽车速度
- (void)onSpeedChange:(BOOL)slow;

@end

GLfloat SceneScalarFastLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLfloat target,GLfloat current);

GLfloat SceneScalarSlowLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLfloat target,GLfloat current);

GLKVector3 SceneVector3FastLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLKVector3 target,GLKVector3 current);

GLKVector3 SceneVector3SlowLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLKVector3 target,GLKVector3 current);
