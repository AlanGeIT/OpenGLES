//
//  SceneModel.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <GLKit/GLKit.h>
@class AGLKVertexAttribArrayBuffer;
@class SceneMesh;

//现场包围盒
typedef struct
{
    GLKVector3 min;
    GLKVector3 max;
}SceneAxisAllignedBoundingBox;

@interface SceneModel : NSObject

@property(nonatomic,strong)NSString *name;
@property(nonatomic,assign)SceneAxisAllignedBoundingBox axisAlignedBoundingBox;


- (id)initWithName:(NSString *)aName mesh:(SceneMesh *)aMesh numberOfVertices:(GLsizei)aCount;

//绘制
- (void)draw;

//顶点数据改变后，重新计算边界
- (void)updateAlignedBoundingBoxForVertices:(float *)verts count:(int)aCount;


@end
