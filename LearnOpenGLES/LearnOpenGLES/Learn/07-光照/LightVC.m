//
//  LightVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "LightVC.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sceneUtil.h"

@interface LightVC ()

@property(nonatomic, strong) EAGLContext                    *mContext;
@property(nonatomic, strong) GLKBaseEffect                  *baseEffect;            // 基本光照纹理
@property(nonatomic, strong) GLKBaseEffect                  *extraEffect;           // 额外光照纹理
@property(nonatomic, strong) AGLKVertexAttribArrayBuffer    *vertexBuffer;          // 顶点缓存区
@property(nonatomic, strong) AGLKVertexAttribArrayBuffer    *extraBuffer;           // 法线位置缓存区
@property(nonatomic, assign) BOOL                           shouldUseFaceNormals;   // 是否使用面法线
@property(nonatomic, assign) BOOL                           shouldDrawNormals;      // 是否绘制法线
@property(nonatomic, assign) GLfloat                        centexVertexHeight;     // 中心点的高

@end

@implementation LightVC {
    // 三角形-8面
    SceneTriangle triangles[NUM_FACES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // 1.
    [self setUp];
}

#pragma mark -- OpenGL ES
-(void)setUp
{
    // 1.新建上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView * )self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  // 颜色格式
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;        // 深度格式
    
    [EAGLContext setCurrentContext:self.mContext];
    
    
    // 2.GLKBaseEffecta
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.light0.enabled = GL_TRUE;
    
    // 光的漫反射颜色
    self.baseEffect.light0.diffuseColor =  GLKVector4Make(0.7f, 0.7f, 0.7f, 1.0f);
    
    // 世界坐标中光位置
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 0.5f, 0.0f);
    
    // 法线
    self.extraEffect = [[GLKBaseEffect alloc]init];
    self.extraEffect.useConstantColor = GL_TRUE;// 是否使用环境光
    
    // 调整模型矩阵,为了更好的观察
    if (true) {
        
        // 围绕X轴旋转60度
        GLKMatrix4 modelViewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-60.0f), 1.0f, 0.0f, 0.0f);
        
        // 围绕Z轴旋转-30度
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(-30), 0.0f, 0.0f, 1.0f);
        
        // 围绕Z轴移动 0.25f
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.0f, 0.25f);
        
        // baseEffect/extraEffect
        self.baseEffect.transform.modelviewMatrix  = modelViewMatrix;
        self.extraEffect.transform.modelviewMatrix = modelViewMatrix;
    }
    
    // 设置清屏颜色
    [self setClearColor:GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f)];
 
    // 确定图形的8个面
    triangles[0] = SceneTriangleMake(vertexA, vertexB, vertexD);
    triangles[1] = SceneTriangleMake(vertexB, vertexC, vertexF);
    triangles[2] = SceneTriangleMake(vertexD, vertexB, vertexE);
    triangles[3] = SceneTriangleMake(vertexE, vertexB, vertexF);
    triangles[4] = SceneTriangleMake(vertexD, vertexE, vertexH);
    triangles[5] = SceneTriangleMake(vertexE, vertexF, vertexH);
    triangles[6] = SceneTriangleMake(vertexG, vertexD, vertexH);
    triangles[7] = SceneTriangleMake(vertexH, vertexF, vertexI);
    
    // 初始化缓存区
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles usage:GL_DYNAMIC_DRAW];
    
    self.extraBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneVertex) numberOfVertices:0 bytes:NULL usage:GL_DYNAMIC_DRAW];
    
    self.centexVertexHeight   = 0.0f;
    self.shouldUseFaceNormals = YES;
}

- (void)setClearColor:(GLKVector4)clearColorRGBA
{
    glClearColor(clearColorRGBA.r,
                 clearColorRGBA.g,
                 clearColorRGBA.b,
                 clearColorRGBA.a);
}

#pragma mark -- GLKView DrawRect
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    
    // 准备绘制顶点数据
    [self.vertexBuffer  prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(SceneVertex,position) shouldEnable:YES];
    
    // 准会绘制光照数据
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:offsetof(SceneVertex,normal) shouldEnable:YES];
    
    // 绘制
    [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sizeof(triangles)/sizeof(SceneVertex)];
    
    if (self.shouldDrawNormals) {
        [self drawNormals];
    }
}


#pragma mark - 绘制法线
-(void)drawNormals
{
    GLKVector3 normalLineVerteices[NUM_LINE_VERTS];
    
    // 以每个顶点的坐标为起点,顶点坐标上的法向量的作为终点.
    SceneTrianglesNormalLinesUpdate(triangles, GLKVector3MakeWithArray(self.baseEffect.light0.position.v), normalLineVerteices);
    
    // extraBuffer 重新开辟空间
    [self.extraBuffer reinitWithAttribStride:sizeof(GLKVector3) numberOfVertices:NUM_LINE_VERTS bytes:normalLineVerteices];
    
    // 准备绘制数据
    [self.extraBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    
    self.extraEffect.useConstantColor = GL_TRUE;
    
    // 用绿色将顶点法线绘制出来
    self.extraEffect.constantColor = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    
    // 准备绘制
    [self.extraEffect prepareToDraw];
    
    // 开始绘制
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:0 numberOfVertices:NUM_NORMAL_LINE_VERTS];
    
    // 绘制光源线,黄色
    self.extraEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 0.0f, 1.0f);
    
    // 准备绘制
    [self.extraEffect prepareToDraw];
    
    // 绘制
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:NUM_NORMAL_LINE_VERTS numberOfVertices:(NUM_LINE_VERTS - NUM_NORMAL_LINE_VERTS)];
}

#pragma mark - 更新法向量
-(void)updateNormals
{
    if (self.shouldUseFaceNormals) {
        // 更新每个点的平面法向量
        SceneTrianglesUpdateFaceNormals(triangles);
    } else {
        // 更新每个点的顶点法向量
        SceneTrianglesUpdateVertexNormals(triangles);
    }
    
    [self.vertexBuffer reinitWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles];
}

#pragma mark --Set
-(void)setCentexVertexHeight:(GLfloat)centexVertexHeight
{
    _centexVertexHeight = centexVertexHeight;
    
    // 更新顶点E
    SceneVertex newVertexE = vertexE;
    newVertexE.position.z = _centexVertexHeight;
    
    // 把与顶点E相关的三角形的数组数据修改
    // 如果不理解为什么改变2345的同学,可以参考PPT中金字塔平面图
    triangles[2] = SceneTriangleMake(vertexD, vertexB, newVertexE);
    triangles[3] = SceneTriangleMake(newVertexE, vertexB, vertexF);
    triangles[4] = SceneTriangleMake(vertexD, newVertexE, vertexH);
    triangles[5] = SceneTriangleMake(newVertexE, vertexF, vertexH);
    
    // 更新法线
    [self updateNormals];
}

-(void)setShouldUseFaceNormals:(BOOL)shouldUseFaceNormals
{
    if (shouldUseFaceNormals != _shouldUseFaceNormals) {
        _shouldUseFaceNormals = shouldUseFaceNormals;
        [self updateNormals];// 更新法线
    }
}

#pragma makr --UI Change

//绘制法线
- (IBAction)takeShouldDrawNormals:(UISwitch *)sender {
    self.shouldDrawNormals = sender.isOn;
}

//绘制屏幕法线
- (IBAction)takeShouldUseFaceNormals:(UISwitch *)sender {
    self.shouldUseFaceNormals = sender.isOn;
}


//改变Z的高度
- (IBAction)changeCenterVertexHeight:(UISlider *)sender {
    self.centexVertexHeight = sender.value;
}

@end
