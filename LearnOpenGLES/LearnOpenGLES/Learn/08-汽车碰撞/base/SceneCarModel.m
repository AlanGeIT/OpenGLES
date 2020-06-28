//
//  SceneCarModel.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "SceneCarModel.h"
#import "SceneMesh.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "bumperCar.h"

@implementation SceneCarModel

- (id)init
{
    SceneMesh *carMesh = [[SceneMesh alloc] initWithPositionCoords:bumperCarVerts normalCoords:bumperCarNormals texCoords0:NULL numberOfPositions:bumperCarNumVerts indices:NULL numberOfIndices:0];
    
    self = [super initWithName:@"bumberCar" mesh:carMesh numberOfVertices:bumperCarNumVerts];
    
    if(self != nil)
    {
        //顶点数据改变后，重新计算边界
        [self updateAlignedBoundingBoxForVertices:bumperCarVerts count:bumperCarNumVerts];
    }
    
    return self;
}


@end
