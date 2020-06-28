//
//  SkyBoxEffect.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/18.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

// GLKNamedEffect 提供基于着色器的OpenGL渲染效果的对象的标准接口
@interface SkyBoxEffect : NSObject<GLKNamedEffect>

@property(nonatomic, assign) GLKVector3  center;
@property(nonatomic, assign) GLfloat     xSize;
@property(nonatomic, assign) GLfloat     ySize;
@property(nonatomic, assign) GLfloat     zSize;

@property(strong, nonatomic, readonly) GLKEffectPropertyTexture     *textureCubeMap;// 纹理
@property(strong, nonatomic, readonly) GLKEffectPropertyTransform   *transform;     // 变换

//准备绘制
-(void)prepareToDraw;
//绘制
-(void)draw;

@end

NS_ASSUME_NONNULL_END
