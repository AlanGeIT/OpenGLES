//
//  PaintView.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "PaintView.h"
#import "debug.h"
#import "shaderUtil.h"
#import "fileUtil.h"


#define kBrushOpacity       (1.0 / 2.0) // 画笔透明度
#define kBrushPixelStep     2           // 画笔每一笔，有几个点！
#define kBrushScale         2           // 画笔的比例

enum {
    PROGRAM_POINT, // 0,
    NUM_PROGRAMS   // 1,有几个程序
};

// 通过UNIFORM传递数据
enum {
    UNIFORM_MVP,         // 0 模型视图变换
    UNIFORM_POINT_SIZE,  // 1 点的大小
    UNIFORM_VERTEX_COLOR,// 2 顶点颜色
    UNIFORM_TEXTURE,     // 3 纹理
    NUM_UNIFORMS         // 4 UNIFORM属性有几个
};

enum {
    ATTRIB_VERTEX,  //0 ATTRIB属性，即顶点属性
    NUM_ATTRIBS     //1 ATTRIB个数，即顶点个数
};

// 定义一个结构体
typedef struct {
    // vert,frag 指向顶点、片元着色器程序文件
    char *vert, *frag;
    // 创建uniform数组，4个元素，数量由你的着色器程序文件中uniform对象个数
    GLint uniform[NUM_UNIFORMS];
    
    GLuint id;
} programInfo_t;

// 注意数据结构
/*
  programInfo_t 结构体，相当于数据类型
  program 数组名，相当于变量名
  NUM_PROGRAMS 1,数组元素个数

  "point.vsh"和"point.fsh";2个着色器程序文件名是作为program[0]变量中
  vert,frag2个字符指针的值。
  uniform 和 id 是置空的。
 
 */
programInfo_t program[NUM_PROGRAMS] = {
    { "point.vsh",   "point.fsh" },
};


// 纹理
typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;


@implementation PaintPoint

- (instancetype)initWithCGPoint:(CGPoint)point {
    self = [super init];
    
    if (self) {
        // 类型转换
        self.mX = [NSNumber numberWithDouble:point.x];
        self.mY = [NSNumber numberWithDouble:point.y];
    }
    
    return self;
}

@end


@interface PaintView()
{
    // Render（渲染）缓冲区的像素尺寸
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    // 缓存区frameBuffer\renderBuffer
    GLuint viewRenderBuffer,viewFrameBuffer;
    
    
    // 画笔纹理,画笔颜色
    textureInfo_t brushTexture;
    GLfloat brushColor[4];
    
    // 是否第一次点击
    Boolean firstTouch;
    // 是否需要清屏
    Boolean needsErase;
    
    // shader object 顶点Shader、片元Shader、Program
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint shaderProgram;
    
    // VBO 顶点Buffer标记
    GLuint vboId;
    
    // 是否初始化
    BOOL initialized;
    
    // 顶点数组
    NSMutableArray *verticeArrM;
}

@end

@implementation PaintView

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        
        // 1.初始化CAEAGLLayer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        // 2.设置透明度
        eaglLayer.opaque = YES;
        
        // 3.设置eaglLayer描述属性
        /*
         1.kEAGLDrawablePropertyRetainedBacking
           表示绘图表面显示后，是否保留其内容，通过一个NSNumber 包装一个bool值。如果是NO,表示
         显示内容后，不能依赖于相同的内容；如果是YES，表示显示内容后不变，一般只有在需要内容保存不变的情况下才使用YES，设置为YES,会导致性能降低，内存使用量降低。一般设置为NO。
         
         2.kEAGLDrawablePropertyColorFormat
            表示绘制表面的内部颜色缓存区格式
         */
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        // 4.初始化上下文
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // 判断是否开辟成功以及设置到当前的Context
        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }
        
        // 设置视图的比例因子
        /*
         比例因子决定视图中的内容如何从逻辑坐标空间（以点测量）映射到设备坐标空间（以像素为单位）。此值通常为1或2。更高比例的因素表明视图中的每一个点由底层的多个像素表示。例如，如果缩放因子为2，并且视图框大小为50×50点，则用于显示内容的位图的大小为100×100像素。
         */
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        // 是否需要清屏，默认等于YES
        needsErase = YES;
    }
    return self;
}

// PaintView layOut
-(void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    
    // 判断是否初始化
    if (!initialized) {
        // 如果没有初始化则对OpenGL初始化
        initialized = [self initGL];
    }
    else {
        // 如果已经初始化则调整layer
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
    
    // 清除帧第一次分配
    if (needsErase) {
        [self erase];
        needsErase = NO;
    }
}

-(BOOL)initGL
{
    // 1.生成标识一个帧缓存对象和颜色渲染
    glGenFramebuffers(1, &viewFrameBuffer);
    glGenRenderbuffers(1, &viewRenderBuffer);
    
    // 2.绑定viewFrameBuffer 和 viewRenderBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    
    // 3.绑定一个Drawable对象存储到一个OpenGL ES渲染缓存对象。
    /*
     创建一个渲染，可以呈现到屏幕上，你将渲染然后分配共享存储通过调用此方法。这个方法的调用替换通常给glrenderbufferstorage。缓存的存储分配了这个方法以后可以显示一个回调presentrenderbuffer：
      为绘制缓冲区分配存储区，此处将CAEAGLLayer的绘制存储区作为绘制缓冲区的存储区
     参数1：OpenGL ES的结合点为当前绑定的渲染。这个参数的值必须gl_renderbuffer（或gl_renderbuffer_oes在OpenGL ES 1.1语境）
     参数2：对象管理数据存储区中的渲染。在iOS中，这个参数的值必须是一个CAEAGLLayer对象
     
     */
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
    
    // 4.将viewRenderBuffer 绑定到GL_COLOR_ATTACHMENT0
    // GL_COLOR_ATTACHMENT0：附着点
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
    
    // 5.获取绘制缓存区的像素宽度 --将绘制缓存区像素宽度存储在backingWidth
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    // 获取绘制缓存区的像素高度--将绘制缓存区像素高度存储在backingHeight
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    // 6.检查GL_FRAMEBUFFER缓存区状态
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Make complete framebuffer Object failed! %x",glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // 7.设置视口
    glViewport(0, 0, backingWidth, backingHeight);
    
    // 8.创建顶点缓冲对象来保存我们的数据
    glGenBuffers(1, &vboId);
    
    // 9.加载画笔纹理
    brushTexture = [self textureFromName:@"Particle.png"];
    
    // 10.加载shade
    [self setupShaders];
    
    // 11.点模糊效果，通过开启混合模式，并设置混合函数
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    // 12.回放录制的路径，这是“加油！”
    NSString *path = [[NSBundle mainBundle]pathForResource:@"abc" ofType:@"string"];
    // 将path 使用NSUTF8StringEncoding 编码
    NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    // 开辟数组空间-可变的
    verticeArrM = [NSMutableArray array];
    
    // 13.根据abc.string文件，将绘制点的数据，json解析到数组
    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    // 14.遍历jsonArr数组，将数据转为PaintPoint类型数据
    for (NSDictionary *dict in jsonArr) {
        PaintPoint *point = [PaintPoint new];
        point.mX = [dict objectForKey:@"mX"];
        point.mY = [dict objectForKey:@"mY"];
        
        // 将PaintPoint 对象添加到verticeArrM数组
        [verticeArrM addObject:point];
    }
    
    // 调用绘制方法：绘制abc.string 绘制的加油字样，延时5秒绘制！
    [self performSelector:@selector(paint) withObject:nil afterDelay:0.5];

    return YES;
}

#pragma mark - 调用绘制方法：绘制abc.string 绘制的加油字样，延时5秒绘制！
-(void)paint
{
    // 从0开始遍历顶点，步长为2
    /*
        为什么步长等于2?
        p1,p2,开始点，结束点！
     */
    for (int i = 0; i < verticeArrM.count - 1; i+= 2) {
        
        // 从verticeArrM数组中读取顶点 cp1,cp2
        PaintPoint *cp1 = verticeArrM[i];
        PaintPoint *cp2 = verticeArrM[i + 1];
       
        // 将PaintPoint对象 -> CGPoint对象
        CGPoint p1,p2;
        p1.x = cp1.mX.floatValue;
        p2.x = cp2.mX.floatValue;
        
        p1.y = cp1.mY.floatValue;
        p2.y = cp2.mY.floatValue;
        
        // 在用户触摸的地方绘制屏幕上的线条
        [self renderLineFromPoint:p1 toPoint:p2];
    }
}

#pragma mark - 在用户触摸的地方绘制屏幕上的线条
-(void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    // 将2个点绘制成线段
    // 顶点缓存区
    static GLfloat *vertexBuffer = NULL;
    
    // 顶点Max(暂时)
    static NSUInteger vertexMax = 64;
    
    // 顶点个数
    NSUInteger vertexCount = 0,count;
    
    // 从点到像素转换
    // 视图的比例因子
    CGFloat scale = self.contentScaleFactor;
    
    // 将每个顶点与scale 因子相乘
    start.x *= scale;
    start.y *= scale;
    
    end.x *= scale;
    end.y *= scale;
    
    // 开辟数组缓存区
    if (vertexBuffer == NULL) {
        // 开辟顶点地址空间
        vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    }
    
    /*
     通过把起点到终点的轨迹分解成若干个点，分别来绘制每个点，从而达到线的效果
     ceilf（）向上取整。不是四舍五入，而是判断后面有小数，去掉小数部分，整数部分加1.
     如：123.456 => 124
        123.001 => 124
     */
    
    // 向缓冲区添加点，所以每个像素都有绘图点
    // 求得start 和 end 2点间的距离
    float seq = sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y));
    
    /*
     向上取整，求得距离要产生多少个点？
     kBrushPixelStep,画笔像素步长
     修改kBrushPixelStep 的值，越大，笔触越细；越小，笔触越粗！
     */
    NSInteger pointCount = ceilf(seq / kBrushPixelStep);
    
    // 比较pointCount 是不是大于1，如果小于1,则count = 1,否则count = pointCount;
    count = MAX(pointCount, 1);
    
    //NSLog(@"Count = %ld",count);
    
    for (int i = 0; i < count; i++) {
        
        // 判断如果顶点数 > 设置顶点Max
        if (vertexCount == vertexMax) {
           
            // 扩容
            // 修改vertexMax 2倍增长
            vertexMax = 2 *vertexMax;
            
            // 增加空间开辟
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 *sizeof(GLfloat));
        }
        
        // 修改vertexBuffer数组的值
        // 将start 和 end 距离之间，计算出count个点，并存储在vertexBuffer数组中
        // x = start.x + (end.x - start.x) * (i/count);
        // y = start.y + (end.y - start.y) * (i/count);
        // vertexBuffer[0]->x
        // 2:包含xy，所以要乘以2
        vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i/(GLfloat)count);
        // vertextBuffer[1]->y
        vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i/(GLfloat)count);
        
        /*
        NSLog(@"X:%f",vertexBuffer[2 * vertexCount]);
        NSLog(@"Y:%f",vertexBuffer[2 * vertexCount + 1]);
        */
        
        // vertexCount 自增1
        vertexCount += 1;
    }
    
    // 加载数据到vertex Buffer对象中
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    
    // 将cpu存储的顶点数据->GPU中 复制顶点数组到缓冲中提供给OpenGL使用
    glBufferData(GL_ARRAY_BUFFER, vertexCount * 2 * sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
    
    // 顶点数据已经准备好
    /*
     链接顶点属性
     glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据
     参考课件：二、链接顶点属性
     */
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);// 最后那个0也可以用NULL
    
    // 绘制
    // 使用刚刚创建的program[0].id的program
    glUseProgram(program[PROGRAM_POINT].id);
    /*
     根据顶点绘制图形，
     参数1：绘制模型 连接线段，参考视觉班第一节课的课件
     参数2：起始点，0
     参数3：顶点个数
     */
    glDrawArrays(GL_POINTS, 0, (int)vertexCount);
    
    // 显示buffer
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 10.加载shade
// 1.将shader变成program
// 2.将属性/Uniform变量值传递到program
- (void)setupShaders
{
    // NUM_PROGRAMS顶点程序个数
    for (int i = 0; i < NUM_PROGRAMS; i++) {
        
        // 1.读取顶点shader\片元shader
        char *vsrc = readFile(pathForResource(program[i].vert));// point.vsh
        char *fsrc = readFile(pathForResource(program[i].frag));// point.fsh
        
        // 将char->NSString 对象，-1：C语言字符串有\0结尾，所以要减去"\0"
        NSString *vsrcStr = [[NSString alloc]initWithBytes:vsrc length:strlen(vsrc)-1 encoding:NSUTF8StringEncoding];
        NSString *fsrcStr = [[NSString alloc]initWithBytes:fsrc length:strlen(fsrc)-1 encoding:NSUTF8StringEncoding];
        
        // 2.打印着色程序中的代码
        NSLog(@"vsrc:%@",vsrcStr);
        NSLog(@"fsrc:%@",fsrcStr);
        
        // 3.属性 -- ATTRIBUTE
        // attribute
        GLsizei attribCt = 0;
        // 创建属性字符串数组【1】
        GLchar *attribUsed[NUM_ATTRIBS];
        // 属性的标记数组，其实这个案例等价于普通变量
        GLint attrib[NUM_ATTRIBS];
        
        // 属性名称数组
        // attribute 变量名称-inVertex(point.vsh）
        GLchar *attribName[NUM_ATTRIBS] = {
            "inVertex",
        };
        
        // uniform变量名称 "MVP", "pointSize", "vertexColor", "texture",
        const GLchar *uniformName[NUM_UNIFORMS] = {
            "MVP", "pointSize", "vertexColor", "texture",
        };
        
        // 遍历attribute
        for (int j = 0; j < NUM_ATTRIBS; j++)
        {
            // strstr(str1,str2) 函数用于判断字符串str2是否是str1的子串。如果是，则该函数返回str2在str1中首次出现的地址；否则，返回NULL。
            // 判断，attribute 变量，是否存在顶点着色器程序中。point.vsh
            if (strstr(vsrc, attribName[j]))
            {
                // attribute个数 a[0] = 1
                attrib[attribCt] = j;
                // 使用的attribute的名称
                attribUsed[attribCt++] = attribName[j];
            }
        }
        
        // 利用shaderUtil.c封装好的方法对programe 进行创建、链接、生成Programe
        /*
         参数1：vsrc,顶点着色器程序
         参数2：fsrc,片元着色器程序
         参数3：attribute变量个数
         参数4：attribute变量名称
         参数5：当前attribute位置
         参数6：uniform名字
         参数7：program的uniform地址
         参数8：program程序地址
         */
        glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0],
                          attrib,NUM_UNIFORMS,
                          &uniformName[0], program[i].uniform,
                          &program[i].id);
        
        // 释放vsrc,fsrc指针
        free(vsrc);
        free(fsrc);
        
        // 使用program
        // 设置常数、初始化Uniform
        // 当前的i == 0
        if (i == PROGRAM_POINT)
        {
            // 使用proram program[0].id 等价，以往课程例子中的GLuint program;
            glUseProgram(program[PROGRAM_POINT].id);
            
            // 为当前程序对象指定uniform变量值
            /*
             为当前程序对象指定uniform变量MVP赋值
             
             void glUniform1f(GLint location,  GLfloat v0);
             参数1:location，指明要更改的uniform变量的位置 MVP
             参数2：v0,指明在指定的uniform变量中要使用的新值
             
             program[0].uniform[3] = 0
             等价于，vsh顶点着色器程序中的uniform变量，MVP = 0;
             其实简单理解就是做了一次初始化，清空这个mat4矩阵
             */
            glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
            
            // 投影矩阵
            /*
             投影分为正射投影和透视投影，我们可以通过它来设置投影矩阵来设置视域，在OpenGL中，默认的投影矩阵是一个立方体，即x y z 分别是-1.0~1.0的距离，如果超出该区域，将不会被显示
             
             正射投影(orthographic projection)：GLKMatrix4MakeOrtho(float left, float righ, float bottom, float top, float nearZ, float farZ)，该函数返回一个正射投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个矩形视域。此时，视点与每个位置之间的距离对于投影将毫无影响。
             
             透视投影(perspective projection)：GLKMatrix4MakeFrustum(float left, float right,float bottom, float top, float nearZ, float farZ)，该函数返回一个透视投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个平截头体(椎体切去顶端之后的形状)视域。此时，视点与每个位置之间的距离越远，对象越小。
             
             在平面上绘制，只需要使正投影就可以了！！
             */
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);// Ortho:正投影
           
            // 模型矩阵，比如你要平移、旋转、缩放，就可以设置在模型矩阵上
            // 这里不需要这些变换，则使用单元矩阵即可，相当于1 * ？ = ？
            GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
            
            // 矩阵相乘，将2个矩阵的结果交给MVPMatrix
            GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            
            // 将矩阵传递到顶点着色器MVP
            /*
              void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
             功能：为当前程序对象指定uniform变量值
             参数1：location 指明要更改的uniform变量的位置 MVP
             参数2：count 指定将要被修改的矩阵的数量
             参数3：transpose 矩阵的值被载入变量时，是否要对矩阵进行变换，比如转置！
             参数4：value ，指向将要用于更新uniform变量MVP的数组指针
             */
            glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
            
            // 点的大小 pointSize
            /*
              为当前程序对象指定uniform变量pointSize赋值
               program[0].uniform[pointSize] = 纹理宽度/画笔比例
             */
             glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width / kBrushScale);
            
            
            // 笔刷颜色
            /*
             为当前程序对象指定uniform变量vertexColor赋值
             program[0].uniform[vertexColor] = 画笔颜色
             
             void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
             功能：为当前程序对象指定uniform变量值
             参数1：location 指明要更改的uniform变量的位置 vertexColor
             参数2：count 指定将要被修改的4分量的数量
             参数3：value ，指向将要用于更新uniform变量vertexColor的值

             */
            glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
        }
    }
    
    glError();
}


#pragma mark - 创建一个纹理图片
- (textureInfo_t)textureFromName:(NSString *)name
{
    
    CGImageRef brushImage;      // 图片
    CGContextRef brushContext;  // 上下文
    GLubyte *brushData;         // 位图数据
    size_t width,height;        // 图片的宽高
    GLuint texId;               // 纹理ID
    textureInfo_t texture;      // 纹理信息
    
    // 获取brushImage对象
    // 首先建立在图像文件的数据一个UIImage对象，然后提取核心图形图像
    brushImage = [UIImage imageNamed:name].CGImage;
    
    // 获取图片的宽和高
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    
    // 位图数据
    // 分配位图上下文所需的内存
    brushData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    // 图形上下文
    // 使用Core Graphics框架提供的bitmatp创造功能。
    /*
     CGContextRef CGBitmapContextCreate(
     void * data,
     size_t width,
     size_t height,
     size_t bitsPerComponent,
     size_t bytesPerRow,
     CGColorSpaceRef cg_nullable space,
     uint32_t bitmapInfo);
     
     Quartz创建一个位图绘制环境，也就是位图上下文。
     参数1：data,要渲染的绘制内容的地址
     参数2：位图的宽
     参数3：位图的高
     参数4：内存中像素的每个组件的位数，比如32位像素格式和RGB颜色空间。一般设置为8，8*4(rgba)=32
     参数5：位图每一行占有比特数
     参数5：颜色空间，通过CGImageGetColorSpace(图片）获取颜色空间
     参数6：颜色通道，RGBA = kCGImageAlphaPremultipliedLast
     */
    brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
    
    // 创建完context之后，可以在context上绘制图片
    /*
     void CGContextDrawImage(CGContextRef c, CGRect rect,
     CGImageRef image);
     参数1：位图上下文
     参数2：绘制的frame
     参数3：绘制的图片
     */
    CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0f, (CGFloat)width, (CGFloat)height), brushImage);
    
    // 接下来将不需要上下文，因此需要释放它以避免内存泄漏
    CGContextRelease(brushContext);
    
    // 纹理进行操作
    
    // 1.给纹理生成标记
    // 使用OpenGL ES生成纹理
    /*
     生成纹理的函数
     glGenTextures (GLsizei n, GLuint* textures)
     参数1：n,生成纹理个数
     参数2：存储纹理索引的第一个元素指针
     */
    glGenTextures(1, &texId);
    
    // 2.绑定纹理
    // 绑定纹理名称 允许建立一个绑定到目标纹理的有名称的纹理。
    glBindTexture(GL_TEXTURE_2D, texId);
    
    // 3.设置参数
    // 设置纹理参数使用缩小滤波器和线性滤波器（加权平均）--设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    // 4.指定2D纹理图像，为内存中的图像数据提供一个指针。
    /*
     功能：生成2D纹理
     glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels)；
     参数1：target,纹理目标，因为你使用的是glTexImage2D函数，所以必须设置为GL_TEXTURE_2D
     参数2：level,0，基本图像级别
     参数3：internalformat，颜色组件；GL_RGBA，GL_ALPHA，GL_RGBA
     参数4：width,纹理图像的宽度
     参数5：height,纹理图像的高度
     参数6：border,纹理边框的宽度,必须为0
     参数7：format,像素数据的颜色格式，可不与internalformat一致，可参考internalformat的值
     参数8：type,像素数据类型，GL_UNSIGNED_BYTE
     参数9：pixels，内存中指向图像数据的指针
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
    
    // 生成纹理之后，即可释放brushData数据
    free(brushData);
    
    // 补充自己定义的texture结构体中的内容
    // 纹理
    texture.id = texId;
    // 纹理宽度
    texture.width = (int)width;
    // 纹理高度
    texture.height = (int)height;
        
    // 返回纹理对象数据
    return texture;
}

#pragma mark - 调整图层
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    // 根据当前图层大小分配颜色缓冲区
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    
    // 绑定一个Drawable对象存储到一个OpenGL ES渲染缓存对象。
    /*
     创建一个渲染，可以呈现到屏幕上，你将渲染然后分配共享存储通过调用此方法。这个方法的调用替换通常给glrenderbufferstorage。缓存的存储分配了这个方法以后可以显示一个回调presentrenderbuffer：
     - (BOOL)renderbufferStorage:(NSUInteger)target fromDrawable:(id<EAGLDrawable>)drawable;
     为绘制缓冲区分配存储区，此处将CAEAGLLayer的绘制存储区作为绘制缓冲区的存储区
     参数1：OpenGL ES的结合点为当前绑定的渲染。这个参数的值必须gl_renderbuffer（或gl_renderbuffer_oes在OpenGL ES 1.1语境）
     参数2：对象管理数据存储区中的渲染。在iOS中，这个参数的值必须是一个CAEAGLLayer对象
     */
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 获取渲染缓存区的像素宽度 --将绘制缓存区像素宽度存储在backingWidth
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    // 获取渲染缓存区的像素高度--将绘制缓存区像素高度存储在backingHeight
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    // 检查GL_FRAMEBUFFER缓存区状态
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        
        NSLog(@"Make compelete framebuffer object failed!%x",glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // 更新投影矩阵、模型视图矩阵
    // 投影矩阵
    /*
     投影分为正射投影和透视投影，我们可以通过它来设置投影矩阵来设置视域，在OpenGL中，默认的投影矩阵是一个立方体，即x y z 分别是-1.0~1.0的距离，如果超出该区域，将不会被显示
     
     正射投影(orthographic projection)：GLKMatrix4MakeOrtho(float left, float righ, float bottom, float top, float nearZ, float farZ)，该函数返回一个正射投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个矩形视域。此时，视点与每个位置之间的距离对于投影将毫无影响。
     
     透视投影(perspective projection)：GLKMatrix4MakeFrustum(float left, float right,float bottom, float top, float nearZ, float farZ)，该函数返回一个透视投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个平截头体(椎体切去顶端之后的形状)视域。此时，视点与每个位置之间的距离越远，对象越小。
     
     在平面上绘制，只需要使正投影就可以了！！
     */
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    
    // 模型视图变换
    // 模型矩阵，比如你要平移、旋转、缩放，就可以设置在模型矩阵上
    // 这里不需要这些变换，则使用单元矩阵即可，相当于1 * ？ = ？
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    
    // 模型视图变换 与 投影矩阵相乘
    // 矩阵相乘，将2个矩阵相乘的结果交给MVPMatrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    /*
     void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
     功能：为当前程序对象指定uniform变量值
     参数1：location 指明要更改的uniform变量的位置 MVP
     参数2：count 指定将要被修改的矩阵的数量
     参数3：transpose 矩阵的值被载入变量时，是否要对矩阵进行变换，比如转置！
     参数4：value ，指向将要用于更新uniform变量MVP的数组指针
     */
    glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    // 更新视口
    glViewport(0, 0, backingWidth, backingHeight);
    
    return YES;
}

#pragma mark - 清空屏幕
-(void)erase
{
    //clear frameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 显示缓存区
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    
    // 逻辑判断
    // 清空verticeArrM
}

#pragma mark - 设置画笔颜色
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    // 更新画笔颜色 颜色 * 透明度
    brushColor[0] = red * kBrushOpacity;
    brushColor[1] = green * kBrushOpacity;
    brushColor[2] = green * kBrushOpacity;
    brushColor[3] = kBrushOpacity;
    
    NSLog(@"%f,%f,%f,%f",brushColor[0],brushColor[1],brushColor[2],brushColor[3]);
    NSLog(@"%f,%f,%f",red,green,blue);
    
    // 释放初始化
    if (initialized) {
        
        // 1.使用program[0].id
        glUseProgram(program[PROGRAM_POINT].id);
        // 2.将颜色值brushColor 传递到 vertexColor中
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

-(void)dealloc
{
    // 安全释放viewFrameBuffer、viewRenderBuffer、brushTexture、vboId、context
    if (viewFrameBuffer) {
        glDeleteFramebuffers(1, &viewFrameBuffer);
        viewFrameBuffer = 0;
    }
    
    if (viewRenderBuffer) {
        glDeleteRenderbuffers(1, &viewRenderBuffer);
        viewRenderBuffer = 0;
    }
    
    if (brushTexture.id) {
        glDeleteTextures(1, &brushTexture.id);
        brushTexture.id = 0;
    }
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark -- Touch Click
// 点击屏幕开始
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 获取绘制的bounds
    CGRect                bounds = [self bounds];
    // 获取当前的点击touch
    UITouch*            touch = [[event touchesForView:self] anyObject];
    // 设置为firstTouch -> yes
    firstTouch = YES;
    
    // 获取当前点击的位置信息，x,y
    _location = [touch locationInView:self];
    
    // y = height - y
    _location.y = bounds.size.height - _location.y;
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGRect bounds =  [self bounds];
    UITouch *touch = [[event touchesForView:self]anyObject];
    
    // 第一次点击
    if (firstTouch) {
        // 将firstTouch状态改为NO
        firstTouch = NO;
        // _previousLocation = 获取上一个顶点
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
    
    }else
    {
        _location = [touch locationInView:self];
        _location.y = bounds.size.height - _location.y;
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
    }
    
    // 获取_previousLocation 和 _location 2个顶点，绘制成线条
    [self renderLineFromPoint:_previousLocation toPoint:_location];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGRect bounds = [self bounds];
    UITouch *touch = [[event touchesForView:self]anyObject];
    
    // 判断是否为第一次触碰
    if (firstTouch) {
        firstTouch = NO;
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
        [self renderLineFromPoint:_previousLocation toPoint:_location];
    }
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touch Cancelled");
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
