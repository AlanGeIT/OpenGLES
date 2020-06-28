//
//  SceneCar.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "SceneCar.h"

@implementation SceneCar

static long bounceCount;


#pragma mark - init
- (id)initWithModel:(SceneModel *)aModel
           position:(GLKVector3)aPosition
           velocity:(GLKVector3)aVelocity
              color:(GLKVector4)aColor;
{
    if(nil != (self = [super init]))
    {
        self.position = aPosition;
        self.color = aColor;
        self.velocity = aVelocity;
        self.model = aModel;
        
        SceneAxisAllignedBoundingBox axisAlignedBoundingBox = self.model.axisAlignedBoundingBox;
        
        // 直径最宽的一半是半径
        self.radius = 0.5f * MAX(axisAlignedBoundingBox.max.x -
                                 axisAlignedBoundingBox.min.x,
                                 axisAlignedBoundingBox.max.z -
                                 axisAlignedBoundingBox.min.z);
    }
    
    return self;
}


#pragma mark - method
//碰撞次数
+ (long)getBounceCount
{
    return bounceCount;
    
}

#pragma mark - 更新car的位置、偏航角和速度
- (void)updateWithController: (id <SceneCarControllerProtocol>)controller
{
    //产生一个时间，在0.01-0.5秒之间
    NSTimeInterval elapsedTimeSeconds = MIN(MAX([controller timeSinceLastUpdate], 0.01f), 0.5f);
    
    //行驶距离 = 速度 * 时间
    GLKVector3 travelDistance = GLKVector3MultiplyScalar(self.velocity, elapsedTimeSeconds);
    
    //下一个点 = 当前位置 + 行驶距离
    self.nextPosition = GLKVector3Add(self.position, travelDistance);
    
    //获取场景box
    SceneAxisAllignedBoundingBox rinkBoundingBox = [controller rinkBoundingBox];
    
    //检测car之间的碰撞
    [self bounceOffCars:[controller cars] elapsedTime:elapsedTimeSeconds];
    
    //检测car是否碰墙面
    [self bounceOffWallsWithBoundingBox:rinkBoundingBox];
    
    // 死角检测
    if (GLKVector3Length(self.velocity) < 0.1) {
        
        // 速度太小，方向可能是一个死角。随机产生有一个新方向
        GLfloat randTemp = (random() / (0.5f * RAND_MAX)) - 1.0f;
        self.velocity = GLKVector3Make(randTemp, 0.0f, randTemp);
    } else if(GLKVector3Length(self.velocity) < 4) {
        // 速度太慢，调整一下速度
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.01f);
    }
    
    // car的方向和标准方向的cos值。 向量AB点乘，产生2个向量之间的夹角值。
    float dotProduct = GLKVector3DotProduct(GLKVector3Normalize(self.velocity), GLKVector3Make(0.0f, 0.0f, -1.0f));
    
    if (self.velocity.x > 0.0f) {
        // 偏航角为正
        self.targetYawRadians = acosf(dotProduct);
    } else {
        // 偏航角为负
        self.targetYawRadians = -acosf(dotProduct);
    }
    
    // 根据偏航角设置汽车
    [self spinTowardDirectionOfMotion:elapsedTimeSeconds];
    
    // 更新self.position
    self.position = self.nextPosition;
}

#pragma mark - 绘制
- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect
{
    // 模型视图矩阵
    GLKMatrix4 savedModelViewMatrix = anEffect.transform.modelviewMatrix;
    
    // The diffuse color of the material. 材质的漫反射颜色。
    GLKVector4 savedDiffuseColor = anEffect.material.diffuseColor;
    
    // The ambient color of the material. 材质的环境颜色
    GLKVector4 savedAmbientColor = anEffect.material.ambientColor;
    
    // 移动，转换到模型视图
    anEffect.transform.modelviewMatrix = GLKMatrix4Translate(savedModelViewMatrix,_position.x, _position.y, _position.z);
    
    // 旋转，绕Y轴旋转偏航角大小
    anEffect.transform.modelviewMatrix = GLKMatrix4Rotate(anEffect.transform.modelviewMatrix, self.yawRadians, 0.0f, 1.0f, 0.0f);
    
    // 设置材质颜色
    anEffect.material.diffuseColor = self.color;
    anEffect.material.ambientColor = self.color;
    [anEffect prepareToDraw];
    
    [_model draw];
    
    // 绘制完毕则复原矩阵、颜色
    anEffect.transform.modelviewMatrix = savedModelViewMatrix;
    anEffect.material.diffuseColor = savedDiffuseColor;
    anEffect.material.ambientColor = savedAmbientColor;
}

#pragma mark - 改变速度
- (void)onSpeedChange:(BOOL)slow {
    if (slow) {
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 0.9);
    } else {
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.1);
    }
}

#pragma mark - Car
#pragma mark - 汽车相撞
- (void)bounceOffCars:(NSArray *)cars elapsedTime:(NSTimeInterval)elapsedTimeSeconds
{
    // 参考PPT
    for (SceneCar *currentCar in cars) {
        
        if (currentCar != self) {
            
            // 距离 GLKVector3Distance(A,B),获取向量AB之间的距离
            float distance = GLKVector3Distance(self.nextPosition, currentCar.nextPosition);
            
            // 距离小于边框直径距离，即可理解为2个图形已经处于重叠，即碰撞状态
            // 汽车碰撞了
            if (distance < self.radius * 2.0f) {
                
                // 碰撞次数+1
                bounceCount++;
                
                // 汽车A的速度
                GLKVector3 ownVelocity = self.velocity;
                
                // 汽车B速度
                GLKVector3 otherVeloctiy = currentCar.velocity;
                
                // 计算碰撞路径
                // B.position - A.position = 可能会发送碰撞的路线直线
                GLKVector3 directionToOtherCar = GLKVector3Subtract(currentCar.position, self.position);
                
                // 将directionToOtherCar  规范化
                directionToOtherCar = GLKVector3Normalize(directionToOtherCar);
                
                // directionToOtherCar 的负方向向量
                // 获取碰撞路线 相反的负方向向量
                GLKVector3 negDirectionToOtherCar = GLKVector3Negate(directionToOtherCar);
                
                // 汽车A的速度向量 与 汽车A的行驶方向 点积  => 2个向量之间的夹角cos值，就是碰撞之后速度下降
                GLfloat A_DotProduct =  GLKVector3DotProduct(ownVelocity, negDirectionToOtherCar);
                
                // A汽车方向的碰撞后的速度值
                GLKVector3 tanOwnVelocity = GLKVector3MultiplyScalar(negDirectionToOtherCar,A_DotProduct);
                
                // 汽车B的速度向量 与 汽车A的行驶方向 点积  => 2个向量之间的夹角cos值，就是碰撞之后速度下降
                GLfloat B_DotProduct = GLKVector3DotProduct(otherVeloctiy, directionToOtherCar);
                
                // B汽车方向的碰撞后的速度值
                GLKVector3 tanOtherVelocity = GLKVector3MultiplyScalar(directionToOtherCar,B_DotProduct);
                
                // 距离
                GLKVector3 travelDistance;
                
                // 更新A汽车碰撞后速度 ownVelocity - tanOwnVelocity
                self.velocity = GLKVector3Subtract(ownVelocity, tanOwnVelocity);
                
                // 计算A汽车行驶距离 = 速度 * 时间
                travelDistance = GLKVector3MultiplyScalar(self.velocity, elapsedTimeSeconds);
                
                // 更新A汽车下个位置 = 当前位置 + 距离
                self.nextPosition = GLKVector3Add(self.position, travelDistance);
                
                // 更新汽车B碰撞后的速度 otherVeloctiy - tanOwnVelocity
                currentCar.velocity = GLKVector3Subtract(otherVeloctiy, tanOtherVelocity);
            
                // 计算B汽车行驶距离 = 速度 * 时间
                travelDistance = GLKVector3MultiplyScalar(currentCar.velocity, elapsedTimeSeconds);
                
                // 更新B汽车下个位置 = 当前位置 + 距离
                currentCar.nextPosition = GLKVector3Add(currentCar.position, travelDistance);
            }
        }
    }
}

//检测car 和墙壁碰壁了
- (void)bounceOffWallsWithBoundingBox:(SceneAxisAllignedBoundingBox)rinkBoundingBox
{
     //思路：通过rinkBoundingBox,可以获取最大、最小边界。根据car的radius属性得到半径，通过半径radius + nextPosition 与 rinkBoundingBox的最大与最小边界比较判断是否到达边界
     //如果到达边界，则把对应轴的速度向量，反向。
    
    //如果下一个点的位置 比 边框的最小的X+半径 还小。就意味着它超过了边框的负方向了。
    if ((rinkBoundingBox.min.x + self.radius) > self.nextPosition.x) {
        
        //下一点X的位置超过了最小的边界
        self.nextPosition = GLKVector3Make(rinkBoundingBox.min.b + self.radius, self.nextPosition.y, self.nextPosition.z);
        
        //撞墙后X方向，相反
        self.velocity = GLKVector3Make(-self.velocity.x, self.velocity.y, self.velocity.z);
    }else if((rinkBoundingBox.max.x - self.radius) < self.nextPosition.x)
    {
        //下一点X的位置超过了最大的边界
        self.nextPosition = GLKVector3Make((rinkBoundingBox.max.x - self.radius), self.nextPosition.y, self.nextPosition.z);
        
        //撞墙后X方向，相反
        self.velocity = GLKVector3Make(-self.velocity.x, self.velocity.y, self.velocity.z);
    }
    
    //Z的边界判断
    if ((rinkBoundingBox.min.z + self.radius)> self.nextPosition.z) {
        
        self.nextPosition = GLKVector3Make(self.nextPosition.x, self.nextPosition.y, rinkBoundingBox.min.z + self.radius);
        
        self.velocity = GLKVector3Make(self.velocity.x, self.velocity.y, -self.velocity.z);
        
    }else if((rinkBoundingBox.max.z - self.radius)< self.nextPosition.z)
    {
        self.nextPosition = GLKVector3Make(self.nextPosition.x, self.nextPosition.y, (rinkBoundingBox.max.z - self.radius));
        
        self.velocity = GLKVector3Make(self.velocity.x, self.velocity.y, -self.velocity.z);
    }  
}

#pragma mark - 计算偏转角
- (void)spinTowardDirectionOfMotion:(NSTimeInterval)elapsed
{
    // 偏航角
    self.yawRadians = SceneScalarSlowLowPassFilter(elapsed, self.targetYawRadians, self.yawRadians);
    
    if (self.mCarID > 0) {
        
        NSLog(@"yawRadius %f",GLKMathRadiansToDegrees(self.yawRadians));
        
    }
}

#pragma mark - SpinMethod
//50.0，是可能更改。模型撞墙后震动效果。因为50.0比较大，current值再增加后可能超过target。
GLfloat SceneScalarFastLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLfloat target,GLfloat current)
{
    //YawRadius + （50.0 * 时间 * (targetYawRadians - YawRadius)）
    return current + (50.0 * timeSinceLastUpdate * (target - current));
}

//4.0，是更改的。可以模拟视角切换过程的效果。因为4.0比较小，current会逐渐接近target。
GLfloat SceneScalarSlowLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLfloat target,GLfloat current)
{
    //YawRadius + （4.0 * 时间 * (targetYawRadians - YawRadius)）
    return current + (4.0 * timeSinceLastUpdate * (target - current));

}

//高通滤波器函数- 为了视角切换能平滑切换
GLKVector3 SceneVector3FastLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLKVector3 target,GLKVector3 current)
{
   
    return GLKVector3Make(
                          SceneScalarFastLowPassFilter(timeSinceLastUpdate, target.x, current.x),
                          SceneScalarFastLowPassFilter(timeSinceLastUpdate, target.y, current.y),
                          SceneScalarFastLowPassFilter(timeSinceLastUpdate, target.z, current.z));
    

}

//低通滤波器函数 -为了视角切换能平滑切换
GLKVector3 SceneVector3SlowLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLKVector3 target,GLKVector3 current)
{
    return GLKVector3Make(
                          SceneScalarSlowLowPassFilter(timeSinceLastUpdate, target.x, current.x),
                          SceneScalarSlowLowPassFilter(timeSinceLastUpdate, target.y, current.y),
                          SceneScalarSlowLowPassFilter(timeSinceLastUpdate, target.z, current.z));

}


@end
