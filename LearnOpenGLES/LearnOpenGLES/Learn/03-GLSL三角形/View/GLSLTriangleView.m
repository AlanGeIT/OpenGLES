//
//  GLSLTriangleView.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "GLSLTriangleView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface GLSLTriangleView ()

@property(nonatomic, strong) CAEAGLLayer    *myEagLayer;        // 专门显示OpenGLES的东西
@property(nonatomic, strong) EAGLContext    *myContext;         // 图形上下文

@property(nonatomic, assign) GLuint         myColorRenderBuffer;// 缓冲区
@property(nonatomic, assign) GLuint         myColorFrameBuffer;

@property(nonatomic, assign) GLuint         myProgram;
@property(nonatomic, assign) GLuint         myVertices;         // 顶点数组

@property (nonatomic, strong) UIButton        *xBtn;
@property (nonatomic, strong) UIButton        *yBtn;
@property (nonatomic, strong) UIButton        *zBtn;

@end

@implementation GLSLTriangleView {
    float xDegree;// x轴旋转度数
    float yDegree;// y轴旋转度数
    float zDegree;// z轴旋转度数
    BOOL bX;// 是否在x轴上旋转
    BOOL bY;// 是否在y轴上旋转
    BOOL bZ;// 是否在z轴上旋转
    NSTimer *myTimer;
}


#pragma mark- setUpRC
-(void)layoutSubviews {
    // 1.设置图层
    [self setupLayer];
    
    // 2.设置上下文
    [self setupContext];
    
    // 3.清空缓存区
    [self deleteBuffer];
    
    // 4.设置renderBuffer;
    [self setupRenderBuffer];
    
    // 5.设置frameBuffer
    [self setupFrameBuffer];
    
    // 6.绘制
    [self render];
}

#pragma mark - 1.设置图层
-(void)setupLayer {
    
    // 设置图层
    self.myEagLayer = (CAEAGLLayer *)self.layer;// 要重写+(Class)layerClass方法才有效
    
    // 设置比例因子
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    // CALayer默认是透明的，必须将它设置为不透明才能其可见
    self.myEagLayer.opaque = YES;
    
    //4.描述属性
    /*
     kEAGLDrawablePropertyRetainedBacking
     表示绘图表面显示后,是否保留其内容,一般设置为false;
     它是一个key值,通过一个NSNumber包装bool值.
     kEAGLDrawablePropertyColorFormat:绘制对象内部的颜色缓存区格式
     kEAGLColorFormatRGBA8:32位RGBA的颜色, 4*8=32;
     kEAGLColorFormatRGB565:16位RGB的颜色
     kEAGLColorFormatSRGBA8:SRGB,
     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - 2.设置上下文
-(void)setupContext {
    
    // 1.指定API版本 1.0~3.0
    /*
     kEAGLRenderingAPIOpenGLES1 = 1,
     kEAGLRenderingAPIOpenGLES2 = 2,
     kEAGLRenderingAPIOpenGLES3 = 3,
     */
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    // 2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    
    // 3.判断是否创建成功
    if (!context) {
        NSLog(@"Create Context Failed");
        return;
    }
    
    // 4.设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set Current Context Failed");
        return;
    }
    
    // 5.将局部的context->全局的
    self.myContext = context;
}

#pragma mark - 3.清空缓存区
-(void)deleteBuffer
{
    /*
    可参考PPT
    buffer分为FrameBuffer 和 Render Buffer 2大类.
    frameBuffer(FBO) 相当于renderBuffer的管理者,
    
    renderBuffer又分为三类: colorBuffer,depthBuffer,stencilBuffer
    
    常用函数
    1.绑定buffer标识
    glGenBuffers(<#GLsizei n#>, <#GLuint *buffers#>)
    glGenRenderbuffers(<#GLsizei n#>, <#GLuint *renderbuffers#>)
    glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
    
    2.绑定空间
    glBindBuffer (GLenum target, GLuint buffer);
    glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
    glBindFramebuffer(<#GLenum target#>, <#GLuint framebuffer#>)
    
    3.删除缓存区空间
    glDeleteBuffers(1, &_myColorRenderBuffer);
    */
    
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;

}

#pragma mark - 4.设置RenderBuffer
-(void)setupRenderBuffer
{
    // 1.定义一个缓存区
    GLuint buffer;
    
    // 2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    // 3.
    self.myColorRenderBuffer = buffer;
   
    // 4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    // 5.分配空间
    // frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
    // 为color renderBuffer 分配空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];

}

#pragma mark - 5.设置FrameBuffer
-(void)setupFrameBuffer
{
    // 1.定义一个缓存区
    GLuint buffer;
    
    // 2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    
    // 3.
    self.myColorFrameBuffer = buffer;
   
    // 4.设置当前的framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    // 5.将_myColorRenderBuffer 装配到GL_COLOR_ATTACHMENT0 附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    // 接下来，可以调用OpenGL ES进行绘制处理，最后则需要在EGALContext的OC方法进行最终的渲染绘制。这里渲染的color buffer,这个方法会将buffer渲染到CALayer上。- (BOOL)presentRenderbuffer:(NSUInteger)target;
}

#pragma mark - 6.绘制
-(void)render
{
    // 1.准备好GLSL文件
    // Veterx Shader,Fragment Shader
    
    // 清屏颜色
    glClearColor(0, 0.0, 0, 1.0);// 设置清屏颜色
    glClear(GL_COLOR_BUFFER_BIT);// 清除颜色缓冲区的颜色
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    // 设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    // 2.获取顶点着色程序、片元着色器程序文件位置
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"GLSLTriangleShaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"GLSLTriangleShaderf" ofType:@"glsl"];
    
    // 判断self.myProgram是否存在，存在则清空其文件
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    // 加载程序到myProgram中来。
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    // 4.链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    // 获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        
        return ;
    } else {
        glUseProgram(self.myProgram);
    }
    
    // 创建绘制索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    // 判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    // 顶点数组
    // 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
    };
    
    //-----处理顶点数据-------
    
    // 将_myVertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    
    // 把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    // 将顶点数据通过myPrograme中的传递到顶点着色程序的position
    // 1.glGetAttribLocation,用来获取vertex attribute的入口的.2.告诉OpenGL ES,通过glEnableVertexAttribArray，3.最后数据是通过glVertexAttribPointer传递过去的。
    // 注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    // 3.设置读取方式
    // 参数1：index,顶点数据的索引
    // 参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    // 参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    // 参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    // 参数5：stride,连续顶点属性之间的偏移量，默认为0；
    // 参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    // 2.设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);

    //--------处理顶点颜色值-------
    // 1.glGetAttribLocation,用来获取vertex attribute的入口的.
    // 注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    
    // 3.设置读取方式
    // 参数1：index,顶点数据的索引
    // 参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    // 参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    // 参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    // 参数5：stride,连续顶点属性之间的偏移量，默认为0；
    // 参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
    // 2.设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    
    // 投影矩阵
    // 注意，想要获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    /*
     一个一致变量在一个图元的绘制过程中是不会改变的，所以其值不能在glBegin/glEnd中设置。一致变量适合描述在一个图元中、一帧中甚至一个场景中都不变的值。一致变量在顶点shader和片断shader中都是只读的。首先你需要获得变量在内存中的位置，这个信息只有在连接程序之后才可获得
     */
    // 找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;

    // 创建 4*4 矩阵
    KSMatrix4 _projectionMatrix;
    
    // 加载单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    
    // 计算纵横比例 = 长/宽
    float aspect = width / height; //长宽比

    // 获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     参考PPT
     */
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
    
    // 将矩阵传递到着色器中
    // 设置glsl里面的投影矩阵
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    // 开启剔除操作效果
    glEnable(GL_CULL_FACE);
    
    // 模型视图矩阵
    // 创建一个4 * 4 矩阵，模型视图
    KSMatrix4 _modelViewMatrix;
   
    // 获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
   
    // 平移，z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    
    // 创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
    // 初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);

    // 旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0);//绕Z轴
    
    // 把变换矩阵相乘，注意先后顺序 ，将平移矩阵与旋转矩阵相乘，结合到模型视图
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);

    // ksMatrixMultiply(&_modelViewMatrix, &_modelViewMatrix, &_rotationMatrix);
    
    // 将模型视图矩阵传到uniform GLSL
    // 加载模型视图矩阵 modelViewMatrixSlot
    // 设置glsl里面的投影矩阵
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    // 使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
        GL_POINTS
        GL_LINES
        GL_LINE_LOOP
        GL_LINE_STRIP
        GL_TRIANGLES
        GL_TRIANGLE_STRIP
        GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
        GL_BYTE
        GL_UNSIGNED_BYTE
        GL_SHORT
        GL_UNSIGNED_SHORT
        GL_INT
        GL_UNSIGNED_INT
     indices：绘制索引数组
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    // 要求本地窗口系统显示OpenGL ES渲染<目标>
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -- Shader
-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    // 创建2个临时的变量，verShader,fragShader
    GLuint verShader,fragShader;
    // 创建一个Program
    GLuint program = glCreateProgram();
    // 编译文件
    // 编译顶点着色程序、片元着色器程序
    // 参数1：编译完存储的底层地址
    // 参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    // 参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    // 创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    // 释放不需要的shader
    glDeleteProgram(verShader);
    glDeleteProgram(fragShader);
    
    return program;
}

/// 链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    // 读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    // 获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    // 获取一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    // 将顶点着色器源码附加到着色器对象上。
    // 参数1：shader,要编译的着色器对象 *shader
    // 参数2：numOfStrings,传递的源码字符串数量 1个
    // 参数3：strings,着色器程序的源码（真正的着色器程序源码）
    // 参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    // 把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

#pragma mark- XYZClick
- (void)xBtnClick {
    // 开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    // 更新的是X还是Y
    bX = !bX;
}

- (void)yBtnClick {
    // 开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    // 更新的是X还是Y
    bY = !bY;
}

- (void)zBtnClick {
    // 开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    // 更新的是X还是Y
    bZ = !bZ;
}

-(void)reDegree
{
    // 如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    // 更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    // 重新渲染
    [self render];
}

/* ************** SETUI ************** */

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

-(void)setup {
    self.xBtn.frame = CGRectMake(kWIDTH(100), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self addSubview:self.xBtn];
    
    self.yBtn.frame = CGRectMake(kMainScreenWidth/2-kWIDTH(22), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self addSubview:self.yBtn];

    self.zBtn.frame = CGRectMake(kMainScreenWidth-kWIDTH(100+44), kMainScreenHeight-kWIDTH(100), kWIDTH(44), kWIDTH(44));
    [self addSubview:self.zBtn];
}

#pragma mark - 懒加载
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
