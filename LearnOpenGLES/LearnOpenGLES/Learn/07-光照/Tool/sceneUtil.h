//
//  sceneUtil.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <GLKit/GLKit.h>

// 顶点数据结构
typedef struct {
    GLKVector3  position; // 顶点向量
    GLKVector3  normal;   // 法线向量
}
SceneVertex;


// 三角形数据结构
typedef struct {
    SceneVertex vertices[3];
}
SceneTriangle;


// 顶点数据
// 顶点坐标{x,y,z}，法线坐标{x,y,z};
static const SceneVertex vertexA = {{-0.5,  0.5, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexB = {{-0.5,  0.0, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexC = {{-0.5, -0.5, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexD = {{ 0.0,  0.5, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexE = {{ 0.0,  0.0, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexF = {{ 0.0, -0.5, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexG = {{ 0.5,  0.5, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexH = {{ 0.5,  0.0, -0.5}, {0.0, 0.0, 1.0}};
static const SceneVertex vertexI = {{ 0.5, -0.5, -0.5}, {0.0, 0.0, 1.0}};


// 八个面
#define NUM_FACES (8)

// 顶点信息
// 8个面，每个面3个点，每个点有顶点坐标和顶点法线
// 8 * 6 = 48个点
// 48个顶点，用于绘制8个面
#define NUM_NORMAL_LINE_VERTS (48)

// 光照信息
// 8个面，24个点，每个点需要2个顶点来画法向量，最后2个顶点是光照向量
// 3 * 8 * 2 + 2
#define NUM_LINE_VERTS (NUM_NORMAL_LINE_VERTS + 2)


//静态函数
/**
*  创建一个三角形
*
*  @param vertexA 顶点A
*  @param vertexB 顶点B
*  @param vertexC 顶点C
*
*  @return 三角形
*/
SceneTriangle SceneTriangleMake( const SceneVertex vertexA,const SceneVertex vertexB,const SceneVertex vertexC);

/**
*  以点0为出发点，通过叉积计算平面法向量
*
*  @param triangle 三角形
*
*  @return 平面法向量
*/
GLKVector3 SceneTriangleFaceNormal(const SceneTriangle triangle);

/**
*  计算三角形平面法向量，更新每个点的平面法向量
*
*  @param someTriangles 三角形数组
*
*  @返回 空
*/
void SceneTrianglesUpdateFaceNormals(SceneTriangle someTriangles[NUM_FACES]);

/**
*  计算各三角形的法向量，通过平均值求出每个点的法向量
*
*  @param someTriangles 三角形数组
*
*  @返回 空
*/
void SceneTrianglesUpdateVertexNormals(SceneTriangle someTriangles[NUM_FACES]);

/**
*  以每个顶点的坐标为起点，顶点坐标加上法向量的偏移值作为终点，更新法线显示数组
*  最后一条线是光源
*
*  @param someTriangles          三角型数组
*  @param lightPosition          光源位置
*  @param someNormalLineVertices 法线显示顶点数组
*/
void SceneTrianglesNormalLinesUpdate(const SceneTriangle someTriangles[NUM_FACES],GLKVector3 lightPosition,GLKVector3 someNormalLineVertices[NUM_LINE_VERTS]);

/**
*  通过向量A和向量B的叉积求出平面法向量，单元化后返回
*
*  @param vectorA 向量A
*  @param vectorB 向量B
*
*  @return 单元平面法向量
*  通过叉积求单位法向量函数
*/
GLKVector3 SceneVector3UnitNormal(const GLKVector3 vectorA,const GLKVector3 vectorB);
