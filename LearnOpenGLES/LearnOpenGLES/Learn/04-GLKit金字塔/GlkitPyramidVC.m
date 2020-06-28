//
//  GlkitPyramidVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "GlkitPyramidVC.h"
#import "GlkitPyramidView.h"

@interface GlkitPyramidVC ()

@property (nonatomic, strong) GLKView       *glkView;
@property (nonatomic, strong) UIButton      *xBtn;
@property (nonatomic, strong) UIButton      *yBtn;
@property (nonatomic, strong) UIButton      *zBtn;

@property(nonatomic, strong) EAGLContext    *mContext;  // 上下文
@property(nonatomic, strong) GLKBaseEffect  *mEffect;   //

@property(nonatomic, assign) int count;

// 旋转度数
@property(nonatomic, assign) float xDegree;
@property(nonatomic, assign) float yDegree;
@property(nonatomic, assign) float zDegree;

// 是否能在对应轴旋转
@property(nonatomic, assign) BOOL XB;
@property(nonatomic, assign) BOOL YB;
@property(nonatomic, assign) BOOL ZB;

@end

@implementation GlkitPyramidVC {
    // 定时器
    dispatch_source_t timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"GLKit金字塔";
    
    [self setupUI];
    
    // 1.新建图层
    [self setupContext];
    
    // 2.渲染图形
    [self render];
}

#pragma mark - 1.新建图层
-(void)setupContext {
    
   // 1.新建OpenGL ES 上下文
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // 2.GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  // 颜色格式
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;        // 深度格式
    
    // 设置上下文
    [EAGLContext setCurrentContext:self.mContext];
    
    // 开启深度测试
    glEnable(GL_DEPTH_TEST);
}

#pragma mark - 2.渲染图形
-(void)render {
    
    // 1.顶点数据
    // 1.顶点数据
    // 前3个元素，是顶点数据xyz；中间3个元素，是顶点颜色值rgb，最后2个是纹理坐标st
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
 
    // 2.绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    // 3.顶点的个数
    self.count = sizeof(indices)/sizeof(GLuint);
    
    // 4.将顶点数组放入缓存区内--?GL_ARRAY_BUFFER:数组缓冲区
    GLuint buffer;
    glGenBuffers(1, &buffer);// 给缓冲区申请标记
    glBindBuffer(GL_ARRAY_BUFFER, buffer);// 绑定到数组缓冲区
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);// 从CPU拷贝数据到GPU
    
    
    // 5.将索引数组放入缓存区
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    // 6.使用顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 参数1：位置
    // 参数2：每次传进去的数据有几个（顶点数据：x、y、z，所以是3个），attrArr的每个顶点数据
    // 参数3：所传数据的类型
    // 参数4：是否要做归一化
    // 参数5：每次一行读几个数据：-0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
    // 参数6：顶点数据是从哪一行的哪个位置开始读取，读取坐标：从0开始，读取纹理： 从3开始，读取纹理：从6开始
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), NULL);
    
    // 7.颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    // 参数跟6的一样
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat),(GLfloat *)NULL + 3);
    
    // 8.纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    // 参数跟6的一样
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat),(GLfloat *)NULL + 6);
    
    // 9.获取纹理数据
    // 思维导图
    // 存储路径
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"GlkitPyramidView" ofType:@"jpg"];
    
    // 设置纹理的读取参数
    // GLKTextureLoaderOriginBottomLeft：从左下角开始读取
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"1",GLKTextureLoaderOriginBottomLeft, nil];
    
    // 通过 GLKTextureInfo 加载纹理
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    // 10.效果
    self.mEffect = [[GLKBaseEffect alloc]init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    // 11.设置透视投影
    CGSize size = self.view.bounds.size;
    
    // 纵横比 fabs：取绝对值
    float aspect = fabs(size.width / size.height);
    // 创建一个4维投影矩阵
    // GLKMathDegreesToRadians(90.0)：度数转弧度
    // aspect：纵横比
    // 0.1f：近平面的长度
    // 10.0f：远平面的长度
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.0f);
    // 放大缩小
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    // 12.模型视图变换
    // 往屏幕深度上移动了-2.0个距离
    // 参数1：加载一个单元矩阵
    // 参数2：x，参数2：y，参数3：z
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
    // 13.定时器
    // GCD开启
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0f);
    dispatch_source_set_event_handler(timer, ^{
        self.xDegree += 0.1f * self.XB;
        self.yDegree += 0.1f * self.YB;
        self.zDegree += 0.1f * self.ZB;
    });
    dispatch_resume(timer);
}

// 不是由我们调用，由Matrix调用，只是复写了这个方法
-(void)update {
    //  更新
    
    // 模型视图变换
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, _xDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, _yDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, _zDegree);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark - GLKViewDelegate
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // 清空颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 准备绘制
    [self.mEffect prepareToDraw];
    
    // 索引绘制
    // GL_TRIANGLES：绘画模式
    // self.count：顶点个数
    // GL_UNSIGNED_INT：数据类型
    // 0：索引
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

#pragma mark --Button Click

- (void)xBtnClick {
    _XB = !_XB;
}

- (void)yBtnClick {
    _YB = !_YB;
}

- (void)zBtnClick {
    _ZB = !_ZB;
}

#pragma mark - setUI
-(void)setupUI {
    
    self.glkView.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight);
    [self.view addSubview:self.glkView];
    
    self.xBtn.frame = CGRectMake(kWIDTH(50), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self.view addSubview:self.xBtn];
    
    self.yBtn.frame = CGRectMake(kMainScreenWidth/2-kWIDTH(22), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self.view addSubview:self.yBtn];

    self.zBtn.frame = CGRectMake(kMainScreenWidth-kWIDTH(50+44), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self.view addSubview:self.zBtn];
}

#pragma mark - 懒加载
- (GLKView *)glkView {
    if (_glkView != nil) {
        return _glkView;
    }
    
    _glkView = [[GLKView alloc] init];
    
    return _glkView;
}
- (UIButton *)xBtn {
    if (_xBtn != nil) {
        return _xBtn;
    }
    
    _xBtn                      = [[UIButton alloc] init];
    _xBtn.backgroundColor      = [UIColor grayColor];
    [_xBtn setTitle:@"X" forState:UIControlStateNormal];
    [_xBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [_xBtn addTarget:self action:@selector(xBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    return _xBtn;
}

- (UIButton *)yBtn {
    if (_yBtn != nil) {
        return _yBtn;
    }
    
    _yBtn                      = [[UIButton alloc] init];
    _yBtn.backgroundColor      = [UIColor grayColor];
    [_yBtn setTitle:@"Y" forState:UIControlStateNormal];
    [_yBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [_yBtn addTarget:self action:@selector(yBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    return _yBtn;
}

- (UIButton *)zBtn {
    if (_zBtn != nil) {
        return _zBtn;
    }
    
    _zBtn                      = [[UIButton alloc] init];
    _zBtn.backgroundColor      = [UIColor grayColor];
    [_zBtn setTitle:@"Z" forState:UIControlStateNormal];
    [_zBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [_zBtn addTarget:self action:@selector(zBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    return _zBtn;
}

@end
