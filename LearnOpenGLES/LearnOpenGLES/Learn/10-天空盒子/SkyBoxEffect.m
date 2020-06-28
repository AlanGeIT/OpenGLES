//
//  SkyBoxEffect.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/18.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "SkyBoxEffect.h"

// 立方体 2 * 6 顶点索引数 绘制立方体的三角形带索引
const static int  SkyboxNumVertexIndices = 14;

// 立方体有 8个角 * 3 = 24
const static int  SkyboxNumCoords = 24;

enum
{
    CCMVPMatrix,    //MVP变换矩阵
    CCSamplersCube, //立体纹理贴图
    CCNumUniforms   //Uniform数量
};

@interface SkyBoxEffect()
{
    GLuint vertexBufferID;          // 顶点缓存区的ID
    GLuint indexBufferID;           // 索引缓存区的ID
    GLuint program;                 // 程序
    GLuint vertexArrayID;           // 顶点数据ID
    GLint uniforms[CCNumUniforms];  // Uniform数组
}

// 加载Shader
- (BOOL)loadShaders;

// 编译Shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file;
// 链接Program
- (BOOL)linkProgram:(GLuint)prog;

// 验证Program
- (BOOL)validateProgram:(GLuint)prog;

@end


@implementation SkyBoxEffect

-(id)init
{
    self = [super init];
    if (self != nil) {
        
        // 初始化纹理
        _textureCubeMap = [[GLKEffectPropertyTexture alloc]init];
        
        // 是否使用原始纹理纹理
        _textureCubeMap.enabled = YES;
        
        // 该纹理阶段采样的纹理的OpenGL ES名称
        _textureCubeMap.name = 0;
        
        // 设置使用的纹理类型
        // 2D，立体贴图
        /*
         GLKTextureTarget2D  --2D纹理 等价于OpenGL 中的GL_TEXTURE_2D
         GLKTextureTargetCubeMa  --立方体贴图 等价于OpenGL 中的GL_TEXTURE_CUBE_MAP
         */
        _textureCubeMap.target = GLKTextureTargetCubeMap;
        
        // 纹理用于计算其输出片段颜色的模式,看GLKTextureEnvMode
        /*
         GLKTextureEnvModeReplace, 输出颜色由从纹理获取的颜色.忽略输入的颜色
         GLKTextureEnvModeModulate, 输出颜色是通过将纹理颜色与输入颜色来计算所得
         GLKTextureEnvModeDecal,输出颜色是通过使用纹理的alpha组件来混合纹理颜色和输入颜色来计算的。
         */
        _textureCubeMap.envMode = GLKTextureEnvModeReplace;
        
        _transform = [[GLKEffectPropertyTransform alloc]init];
        self.center = GLKVector3Make(0, 0, 0);
        self.xSize = 1.0f;
        self.ySize = 1.0f;
        self.zSize = 1.0f;
        
        // 立方体的8个角
        const float vertices[SkyboxNumCoords] = {
            -0.5, -0.5,  0.5,
            0.5, -0.5,  0.5,
            -0.5,  0.5,  0.5,
            0.5,  0.5,  0.5,
            -0.5, -0.5, -0.5,
            0.5, -0.5, -0.5,
            -0.5,  0.5, -0.5,
            0.5,  0.5, -0.5,
        };
        
        // VAO,VBO
        // 创建缓存对象,并返回缓存标识符-顶点
        glGenBuffers(1, &vertexBufferID);
        // 将缓存区绑定到相应的缓存区上-数组缓存区
        glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
        // 将数据拷贝到缓冲区上
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        
        // 绘制立方体的三角形带索引
        const GLubyte indices[SkyboxNumVertexIndices] = {
            1, 2, 3, 7, 1, 5, 4, 7, 6, 2, 4, 0, 1, 2
        };
        
        // 1.创建缓存对象,并返回缓存标识符-索引
        glGenBuffers(1, &indexBufferID);
        // 2.将缓存区绑定到相应的缓存区上-索引缓存区
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
        // 3.将数据拷贝到缓冲区上
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     sizeof(indices),
                     indices,
                     GL_STATIC_DRAW);
    }
    
    return self;
}

// 准备绘制
-(void)prepareToDraw
{
    if (program == 0) {
        
        // 加载你写的顶点\片元着色器程序
        [self loadShaders];
        
    }
    
    if (program != 0) {
        
        // 1.使用program
        glUseProgram(program);
        
        // 2.移动天空盒子的模型视图矩阵
        GLKMatrix4 skyboxModelView = GLKMatrix4Translate(self.transform.modelviewMatrix, self.center.x, self.center.y, self.center.z);
        
        // 3. 1:1:1 放大天空盒子模型视图矩阵
        skyboxModelView = GLKMatrix4Scale(skyboxModelView, self.xSize, self.ySize, self.zSize);
        
        // 将模型视图矩阵与投影矩阵组合
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, skyboxModelView);
        
        // 为当前程序对象指定Uniform变量的值
        /*
        什么叫MVPMatrix?
         MVPMatrix,本质上就是一个变换矩阵.用来把一个世界坐标系的点转换成裁剪空间的位置.在前面我说过,学过OpenGL 的人都知道.3D物体从建模到最终显示到屏幕上需要经历以下几个阶段:
            1.对象空间(Object space)
            2.世界空间(World Space)
            3.照相机空间(Camera Space/Eye Space)
            4.裁剪空间(Clipping Space)
            5.设备空间(normalized device space)
            6.视口空间(Viewport)
            
         从对象空间到世界空间的变换叫做Model-To-World变换,
         从世界空间到照相机空的变换叫做Worl-To-View变换,
         从照相机空间到裁剪空间变换叫做View-TO-Pojection变换.
         合起来,从对象空间-裁剪空间的这个过程就是我们所说的MVP变换.
         这里的每一个变换都是乘以一个矩阵,3个矩阵相乘最后还是一个矩阵.
         这就传递到顶点着色器中的MVPMatrix矩阵.
         
         gl_Position = u_mvpMatrix * vec4(a_position, 1.0);

         glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)
            参数1:location, 要更改的uniforms变量的位置
            参数2:cout, 更改矩阵的个数
            参数3:transpose, 指是否要转置矩阵,并将它作为uniform变量的值,必须为GL_FALSE
            参数4:value, 数据来源，指向count个数的元素指针.用来更新uniform变量的值.
         
         为当前程序对象指定Uniform变量的值
         */
        
        glUniformMatrix4fv(uniforms[CCMVPMatrix], 1, 0, modelViewProjectionMatrix.m);
  
        // 一个纹理采样均匀变量
        /*
         void glUniform1f(GLint location,  GLfloat v0);
         为当前程序对象指定Uniform变量的值
         location:指明要更改的uniform变量的位置
         v0:在指定的uniform变量中要使用的新值
         */
        glUniform1i(uniforms[CCSamplersCube], 0);
      
        
        // 顶点数组ID 如果等于0
        if (vertexArrayID == 0) {
            
            // OES 拓展类
            // 设置顶点属性指针
            // 为vertexArrayID 申请一个标记
            glGenVertexArraysOES(1, &vertexArrayID);
            // 绑定一块区域到vertexArrayID上
            glBindVertexArrayOES(vertexArrayID);
            
            // glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据。
            // 着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            // 将VertexArrayID 绑定是数组缓存区
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
            
            /*
             读取数据到顶点着色器
             参数1:读取到顶点中
             参数2:读取个数
             参数3:类型
             参数4:是否归一化
             参数5:从哪个位置开始读取
             */
            glVertexAttribPointer(GLKVertexAttribPosition,
                                  3,
                                  GL_FLOAT,
                                  GL_FALSE,
                                  0,
                                  NULL);
            
        } else {
           // 调用恢复所有先前编写的顶点属性指针与vertexarrayId
            glBindVertexArrayOES(vertexArrayID);
        }
        
        
        // 绑定索引ID
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
        
        // 如果绑定的纹理可用
        if (self.textureCubeMap.enabled) {
            // 绑定纹理
            // 参数1:纹理类型
            // 参数2:纹理名称
            glBindTexture(GL_TEXTURE_CUBE_MAP, self.textureCubeMap.name);
        }else {
            // 绑定一个空的
            glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
        }
    }
}

#pragma mark - 绘制
-(void)draw
{
    /*
     索引绘制方法
     glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
     参数列表:
        mode:指定绘制图元的类型,但是如果GL_VERTEX_ARRAY 没有被激活的话，不能生成任何图元。它应该是下列值之一: GL_POINTS, GL_LINE_STRIP,GL_LINE_LOOP,GL_LINES,GL_TRIANGLE_STRIP,GL_TRIANGLE_FAN,GL_TRIANGLES,GL_QUAD_STRIP,GL_QUADS,GL_POLYGON
        count:绘制图元的数量
        type 为索引数组(indices)中元素的类型，只能是下列值之一:GL_UNSIGNED_BYTE,GL_UNSIGNED_SHORT,GL_UNSIGNED_INT
        indices：指向索引数组的指针。
     */
    glDrawElements(GL_TRIANGLE_STRIP, SkyboxNumVertexIndices, GL_UNSIGNED_BYTE, NULL);
}

- (void)dealloc
{
    // 释放
    if(0 != vertexArrayID)
    {
        glDeleteVertexArraysOES(1, &vertexArrayID);
        vertexArrayID = 0;
    }
    if(0 != indexBufferID)
    {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glDeleteBuffers(1, &vertexBufferID);
    }
    if(0 != indexBufferID)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glDeleteBuffers(1, &indexBufferID);
    }
    if(0 != program)
    {
        glUseProgram(0);
        glDeleteProgram(program);
    }
}

#pragma mark -  OpenGL ES shader compilation
// 加载着色器
- (BOOL)loadShaders
{
    // 定义一个临时顶点着色器和一个临时片元着色器
    GLuint vertShader, fragShader;
    // 文件两个文件的路径
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // 1.创建一个program
    program = glCreateProgram();
    
    // 2.指定顶点着色器路径
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"SkyboxShader" ofType:@"vsh"];
    
    // 3.编译顶点着色器程序
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // 4.指定片元着色器路径
    fragShaderPathname = [[NSBundle mainBundle] pathForResource: @"SkyboxShader" ofType:@"fsh"];
    
    // 5.编译片元着色器程序
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    
    glAttachShader(program, vertShader);// 将顶点着色器附着到程序program上
    glAttachShader(program, fragShader);// 将片元着色器附着到程序program上
    
    // 绑定属性位置
    // 需要在链接之前完成
    glBindAttribLocation(program, GLKVertexAttribPosition, "a_position");
    
    // 链接程序
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        return NO;
    }
    
    // 获取uniform变量的位置
    uniforms[CCMVPMatrix] = glGetUniformLocation(program, "u_mvpMatrix");
    uniforms[CCSamplersCube] = glGetUniformLocation(program, "u_samplersCube");
    
    // 删除顶点和片元着色器shader
    if (vertShader)
    {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader)
    {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

// 编译着色器程序
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file
{
    // 状态
    GLint status;
    // 路径-C语言
    const GLchar *source;
    
    // 从OC字符串中获取C语言字符串
    // 获取路径
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    // 判断路径
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    // 创建shader-顶点\片元
    *shader = glCreateShader(type);
    
    // 绑定shader
    glShaderSource(*shader, 1, &source, NULL);
    
    // 完成Shader
    glCompileShader(*shader);
    
    // 获取加载Shader的日志信息
    // 日志信息长度
    GLint logLength;
    /*
    在OpenGL中有方法能够获取到 shader错误
    参数1:对象,从哪个Shader
    参数2:获取信息类别,
            GL_COMPILE_STATUS       // 编译状态
            GL_INFO_LOG_LENGTH      // 日志长度
            GL_SHADER_SOURCE_LENGTH // 着色器源文件长度
            GL_SHADER_COMPILER      // 着色器编译器
     参数3:获取长度
     */
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    // 判断日志长度 > 0
    if (logLength > 0)
    {
        // 创建日志字符串
        GLchar *log = (GLchar *)malloc(logLength);
        /*
         获取日志信息
         参数1:着色器
         参数2:日志信息长度
         参数3:日志信息长度地址
         参数4:日志存储的位置
         */
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        
        // 打印日志信息
        NSLog(@"Shader compile log:\n%s", log);
        
        // 释放日志字符串
        free(log);
        
        return NO;
    }
    
    return YES;
}

// 链接program
- (BOOL)linkProgram:(GLuint)prog
{
    // 状态
    GLint status;
    // 链接Programe
    glLinkProgram(prog);
    
    // 打印链接program的日志信息
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
        
        return NO;
    }
    
    return YES;
}

// 验证Program
- (BOOL)validateProgram:(GLuint)prog
{
    // 日志长度,验证状态
    GLint logLength, status;
    
    // 验证prgogram
    //http://www.dreamingwish.com/frontui/article/default/glvalidateprogram.html
    /*
     glValidateProgram 检测program中包含的执行段在给定的当前OpenGL状态下是否可执行。验证过程产生的信息会被存储在program日志中。验证信息可能由一个空字符串组成，或者可能是一个包含当前程序对象如何与余下的OpenGL当前状态交互的信息的字符串。这为OpenGL实现提供了一个方法来调查更多关于程序效率低下、低优化、执行失败等的信息。
     验证操作的结果状态值会被存储为程序对象状态的一部分。如果验证成功，这个值会被置为GL_TURE，反之置为GL_FALSE。调用函数 glGetProgramiv 传入参数 program和GL_VALIDATE_STATUS可以查询这个值。在给定当前状态下，如果验证成功，那么 program保证可以执行，反之保证不会执行
     
     GL_INVALID_VALUE 错误：如果 program 不是由 OpenGL生成的值.
     GL_INVALID_OPERATION 错误：如果 program 不是一个程序对象.
     */
    glValidateProgram(prog);
    
    // 获取验证的日志信息
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    // 获取验证的状态--验证结果
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    // 根据验证结果返回NO or YES
    if (status == 0)
    {
        return NO;
    }
    return YES;
}

@end
