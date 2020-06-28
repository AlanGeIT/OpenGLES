//
//  UserShaderLoadImageView.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//
/*
不采用GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
思路：
  1.创建图层
  2.创建上下文
  3.清空缓存区
  4.设置RenderBuffer
  5.设置FrameBuffer
  6.开始绘制
*/

#import "UserShaderLoadImageView.h"
#import <OpenGLES/ES2/gl.h>

@interface UserShaderLoadImageView()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic, strong)CAEAGLLayer *myEagLayer;
@property(nonatomic, strong)EAGLContext *myContext;
@property(nonatomic, assign)GLuint      myColorRenderBuffer;// 渲染缓冲区
@property(nonatomic, assign)GLuint      myColorFrameBuffer;

@property(nonatomic,assign)GLuint myPrograme;

@end

@implementation UserShaderLoadImageView

-(void)layoutSubviews
{
    //1.设置图层
    [self setUpLayer];
    
    //2.创建上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
    
}

// 6.开始绘制
-(void)renderLayer
{
    // 1.开始要写顶点着色器\片元着色器
    // Vertex Shader
    // Fragment Shaer
    
    // 已经写好了顶点shaderv.vsh\片元着色器shaderf.fsh
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 2.设置视口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    // 3.读取顶点\片元着色器程序
    // 获取存储路径
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"USLImgShaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"USLImgShaderf" ofType:@"fsh"];
    
    NSLog(@"vertFile : %@",vertFile);
    NSLog(@"fragFile : %@",fragFile);
    
    // 4.加载shader
    self.myPrograme = [self LoadShader:vertFile withFrag:fragFile];
    
    // 5.链接
    glLinkProgram(self.myPrograme);
    
    // 获取link的状态
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    
    // 判断link是否失败
    if (linkStatus == GL_FALSE) {
        
        // 获取失败信息
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        
        // 将C语言字符串->OC
        NSString *messageStr = [NSString stringWithUTF8String:message];
        
        NSLog(@"Program Link Error:%@",messageStr);
        return;
    }
    
    // 5.使用program
    glUseProgram(self.myPrograme);
    
    // 6.设置顶点
    // 前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, 1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, 1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
    };
    
    // --处理顶点数据---
    GLuint attrBuffer;
    // 申请一个缓存标记
    glGenBuffers(1, &attrBuffer);
    // 绑定缓存区
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    
    // 将顶点缓冲区的CPU内存复制到GPU内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    // 将数据传到shaderv.vsh的position
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    
    // 2.
    glEnableVertexAttribArray(position);
    
    // 3.设置读取方式
    // position:往哪个位置读取数据
    // 3：每次读取几个数据，表示x、y、z顶点数据
    // GL_FLOAT:数据类型
    // GL_FALSE：是否要做归一化
    // sizeof(GLfloat) * 5：步长，顶点数据3个，纹理数据2个
    // NULL：开始位置，NULL为从0开始读取
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    
    // 4.处理纹理数据
    // 下一次节从这个位置讲起!!!!!!
    // 1.获取纹理的位置-Program
    // GLuint：无符号整型
    // self.myPrograme：属性的位置
    // textCoordinate（纹理）：属性的名称，从shaderv.vsh复制过来，避免敲错
    GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    
    // 2.设置textCoor为可读
    glEnableVertexAttribArray(textCoor);
    
    // 3.设置读取方式
    // textCoor：索引，即从哪里获取
    // 2：大小，纹理为2维数据
    // GL_FLOAT：数据类型
    // GL_FALSE：是否要做归一化
    // sizeof(GLfloat) * 5：步长，顶点数据3个，纹理数据2个
    // (GLfloat *)NULL + 3:读取纹理，前面有三个是顶点，所以纹理位置为(GLfloat *)NULL + 3
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    // 加载纹理!!!
    // 通过一个自定义方法来解决加载纹理的方法
    [self setupTexture:@"timg-3"];
    
    
    // 1.直接用3D数学的公式来实现旋转
    // 2.Uniform
    
    // 旋转!!!矩阵->Uniform 传递到vsh,fsh
    
    // 需求:旋转10度->弧度?????
    // 旋转180度，解决倒置问题
    float radians = 180 * 3.141592f /180.0f;
    
    // 旋转的矩阵公式
    float s = sin(radians);
    float c = cos(radians);
    
    // 构建旋转矩阵--z轴旋转，这里用的是列矩阵
    GLfloat zRotation[16] = {
            c,-s,0,0,
            s,c,0,0,
            0,0,1.0,0,
            0,0,0,1.0,
        };
    
    // 获取位置
    // rotateMatrix:shaderv.vsh的旋转矩阵
    GLuint rotate = glGetUniformLocation(self.myPrograme, "rotateMatrix");
    
    // 将这旋转矩阵通过uniform传递进去
    // rotate：传到rotate
    // 1：传1个数据
    // GL_FALSE：不需要转置
    // (GLfloat *)&zRotation[0]：值在哪里 --> zRotation的首地址
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    // 绘制
    // GL_TRIANGLES：填充模式
    // 0：从哪里开始读取
    // 6：顶点数（两个三角形，所以是6个顶点）
    glDrawArrays(GL_TRIANGLES, 0, 6);

    // 渲染
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    // 根据这个案例写一个思维导图!
    // 1.回顾复习
    // 2.写成文章
    // 3.面试
}

// 5.设置frameBuffer
-(void)setupFrameBuffer
{
    // 1.定义一个缓存区标记
    GLuint buffer;
    
    // 2.
    glGenRenderbuffers(1, &buffer);
    
    // 3.
    self.myColorFrameBuffer = buffer;
    
    // 4.
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    // 5.将_myColorRenderBuffer 通过glFramebufferRenderbuffer 绑定到附着点上GL_COLOR_ATTACHMENT0(颜色附着点)
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    // 6.接下来可以使用prsentRenderBuffer 来进行最终的渲染
}


// 4.设置RenderBuffer
-(void)setupRenderBuffer
{
    // 1.定义缓存区
    GLuint buffer;
    
    //2.申请一个缓存区标记
    glGenRenderbuffers(1, &buffer);
    
    //3.
    self.myColorRenderBuffer = buffer;
    
    //4.将标识符绑定GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    // 5.分配空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
    
}

//3.清空缓存区
-(void)deleteRenderAndFrameBuffer
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
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//2.创建上下文
-(void)setupContext
{
    //1.指定API版本 1.0~3.0
    /*
     kEAGLRenderingAPIOpenGLES1 = 1,
     kEAGLRenderingAPIOpenGLES2 = 2,
     kEAGLRenderingAPIOpenGLES3 = 3,
     */
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    //2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    
    //3.判断是否创建成功
    if (context == NULL) {
        NSLog(@"Create Context Failed!!!!");
        return;
    }
    
    // 4.设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        
        NSLog(@"setCurrenContext failed!");
        return;
    }
    
    //5.将局部的context->全局的
    self.myContext = context;
}


// 1.设置图层
-(void)setUpLayer
{
    // 1.设置图层
    self.myEagLayer = (CAEAGLLayer *)self.layer;// 要重写+(Class)layerClass方法才有效
    
    // 2.设置比例因子
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    // 3.默认是透明的,如果想要其可见要设置为不透明
    self.myEagLayer.opaque = YES;
    
    // 4.描述属性
    /*
     kEAGLDrawablePropertyRetainedBacking
     表示绘图表面显示后,是否保留其内容,一般设置为false;
     它是一个key值,通过一个NSNumber包装bool值.
     kEAGLDrawablePropertyColorFormat:绘制对象内部的颜色缓存区格式
     kEAGLColorFormatRGBA8:32位RGBA的颜色, 4*8=32;
     kEAGLColorFormatRGB565:16位RGB的颜色
     kEAGLColorFormatSRGBA8:SRGB,
     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

+(Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark -- shader
-(GLuint)setupTexture:(NSString *)fileName {
    
    // 1.获取图片的CGImageRef（CoreGraphics框架）
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    // 2.判断这个图片是否获取成功
    if (spriteImage == nil) {
        NSLog(@"Failed to load image! %@",fileName);
        exit(0);// 退出
    }
    
    // 3.读取图片的大小,宽\高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    // 4.计算图片字节数 width * height * 4 (RGBA)
    // malloc calloc (C语言中空间开辟) alloc(oc)
    GLubyte *spriteData = calloc(width * height * 4, sizeof(GLubyte));
    
    // 5.创建上下文
    /*
     GBitmapContextCreate(void * __nullable data,
     size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow,
     CGColorSpaceRef cg_nullable space, uint32_t bitmapInfo)
     
     参数列表:
        1.data,要渲染的图像的内存地址              spriteData
        2.width,宽                             width
        3.height,高                            height
        4.bitsPerComponent,像素中颜色组件的位数   8
        5.bytesPerRow,一行需要占用多大的内存       width * 4
        6.space,颜色空间                        CGImageGetColorSpace(spriteImage)
        7.bitmapInfo                          kCGImageAlphaPremultipliedLast
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 6.绘图
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 使用默认方式绘制
    // spriteContext:图片的上下文
    // rect：位置
    // spriteImage:图片内容
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    // 绘制完释放
    CGContextRelease(spriteContext);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 设置纹理的相关参数
    // 参数不记得的同学,可以回顾一下OpenGL中的纹理课程
    // 放大过滤器,缩小过滤器
    // GL_TEXTURE_2D：设置为2维纹理
    // GL_TEXTURE_MAG_FILTER：放大过滤
    // GL_LINEAR：线性过滤
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // GL_TEXTURE_MIN_FILTER：缩小过滤
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    // x,y->s,t
    // 环绕方式
    // GL_TEXTURE_2D：设置为2维纹理
    // GL_TEXTURE_WRAP_S:设置S环绕方式
    // GL_TEXTURE_WRAP_T:设置T环绕方式
    // GL_CLAMP_TO_EDGE:超出纹理范围的坐标被截取成0和1，形成纹理边缘延伸的效果。
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 载入纹理
    /*
     glTexImage2D(<#GLenum target#>, <#GLint level#>, <#GLint internalformat#>, <#GLsizei width#>, <#GLsizei height#>, <#GLint border#>, <#GLenum format#>, <#GLenum type#>, <#const GLvoid *pixels#>)
     参数列表:
        1.target: GL_TEXTURE_1D\GL_TEXTURE_2D\GL_TEXTURE_3D
        2.level: 加载的层次,一般为0
        3.internalformat: 颜色组件
        4.width: 宽
        5.height: 高
        6.border: 宽度，0
        7.format: 格式
        8.type: 存储数据的类型
        9.pixels: 指向纹理数据的指针
     */
    float fw = width,fh = height;
    //                 1        2      3     4   5  6      7        8               9
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 释放
    free(spriteData);
    
    return 0;
}

// 加载shader
-(GLuint)LoadShader:(NSString *)vert withFrag:(NSString *)frag {
    
    // 1.定义2个临时着色器对象
    GLuint verShader,fragShader;
    
    GLuint program = glCreateProgram();
    
    // 2.编译shader
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    // 3.创建最终程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    // 4.释放已经使用完的verShader\fragShader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

// 编译shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    // 读取shader路径
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    // 将OC 字符串-> C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    // 2.创建shader
    *shader = glCreateShader(type);
    
    // 3.将着色器的代码附着到shader上
    glShaderSource(*shader, 1, &source, NULL);
    
    // 4.将着色器代码编译成目标代码
    glCompileShader(*shader);
}

@end
