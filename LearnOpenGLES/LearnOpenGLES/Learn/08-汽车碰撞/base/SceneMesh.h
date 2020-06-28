//
//  SceneMesh.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <GLKit/GLKit.h>

//顶点数据
typedef struct
{
    GLKVector3 position;//位置坐标
    GLKVector3 normal;//法线坐标
    GLKVector3 texCoords0;//纹理坐标
}SceneMeshVertex;

@interface SceneMesh : NSObject

/*
 * 初始化
 * 位置 和 法线 是 3 * GLFloat
 * 纹理：2 * GLFloat
 * 索引：1 * GLushort
 
  参数1，somePositions：位置
  参数2，someNormals：法线
  参数3,someTexCoords0：纹理
  参数4,countPositions:顶点数量
  参数5,someIndices：索引
  参数6,countIndices：索引数量
 
 */
- (id)initWithPositionCoords:(const GLfloat *)somePositions
                normalCoords:(const GLfloat *)someNormals
                  texCoords0:(const GLfloat *)someTexCoords0
           numberOfPositions:(size_t)countPositions
                     indices:(const GLushort *)someIndices
             numberOfIndices:(size_t)countIndices;
//准备绘制
- (void)prepareToDraw;

//不使用索引绘制
- (void)drawUnidexedWithMode:(GLenum)mode
            startVertexIndex:(GLint)first
            numberOfVertices:(GLsizei)count;

//分配经常改动(动态)的内存
- (void)makeDynamicAndUpdateWithVertices:(const SceneMeshVertex *)someVerts numberOfVertices:(size_t)count;

@end

