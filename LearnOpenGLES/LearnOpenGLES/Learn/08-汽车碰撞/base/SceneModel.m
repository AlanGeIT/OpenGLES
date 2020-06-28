//
//  SceneModel.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "SceneModel.h"
#import "SceneMesh.h"
#import "AGLKVertexAttribArrayBuffer.h"

@interface SceneModel ()

@property(nonatomic,strong)SceneMesh *mesh;
@property(nonatomic,assign)GLsizei numberOfVertices;

@end

@implementation SceneModel

-(id)initWithName:(NSString *)aName mesh:(SceneMesh *)aMesh numberOfVertices:(GLsizei)aCount {
    self = [super init];
    if(self != nil)
    {
        _name = aName;
        _mesh= aMesh;
        _numberOfVertices = aCount;
        
    }
    return self;
    
}


-(void)draw {
    [self.mesh prepareToDraw];
    [self.mesh drawUnidexedWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:self.numberOfVertices];
}


-(void)updateAlignedBoundingBoxForVertices:(float *)verts count:(int)aCount {
    //初始化对象result
    SceneAxisAllignedBoundingBox result = {{0,0,0},{0,0,0}};
    
    //类型转换
    const GLKVector3 *positions = (const GLKVector3 *)verts;
    
    //判断aCount > 0
    //假设第一个元素既是最大也是最小
    if (aCount > 0 ) {
        //result.min/max = position[0]
        result.min.x = result.max.x = positions[0].x;
        result.min.y = result.max.y = positions[0].y;
        result.min.z = result.max.z = positions[0].z;
    }
    
    //遍历数组，获取最大、最小的点
    for(int i = 1; i < aCount; i++)
    {
        result.min.x = MIN(result.min.x, positions[i].x);
        result.min.y = MIN(result.min.y, positions[i].y);
        result.min.z = MIN(result.min.z, positions[i].z);
        
        result.max.x = MAX(result.max.x, positions[i].x);
        result.max.y = MAX(result.max.y, positions[i].y);
        result.max.z = MAX(result.max.z, positions[i].z);
    }
    
    self.axisAlignedBoundingBox = result;
}

@end
