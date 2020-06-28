//
//  CarBumpVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/17.
//  Copyright © 2020 AlanGe. All rights reserved.
//
// 《3D数学基础：图形与游戏开发》

#import "CarBumpVC.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "SceneCar.h"
#import "SceneCarModel.h"
#import "SceneRinkModel.h"

@interface CarBumpVC ()

@property(nonatomic,strong)GLKBaseEffect *baseFffect;
//汽车model
@property(nonatomic,strong)SceneModel *carModel;
//场景model
@property(nonatomic,strong)SceneModel *rinkModel;
//是否使用第一人视野
@property(nonatomic,assign)BOOL shouldUseFirstPersonPOV;
@property(nonatomic,assign)GLfloat pointOfViewAnimationCountDown;
//第一视角观察位置
@property(nonatomic,assign)GLKVector3 eyePosition;
@property(nonatomic,assign)GLKVector3 lookAtPosition;
//第三人称视角
@property (nonatomic, assign) GLKVector3 targetEyePosition;
@property (nonatomic, assign) GLKVector3 targetLookAtPosition;

@property(nonatomic,strong)NSMutableArray *cars;

//场景box
@property (nonatomic, assign, readwrite) SceneAxisAllignedBoundingBox rinkBoundingBox;
@property (weak, nonatomic) IBOutlet UILabel *myBounceLabel;
@property (weak, nonatomic) IBOutlet UILabel *myVelocityLabel;

@end

//POV场景动画秒数
static const int SceneNumberOfPOVAnimationSeconds = 2.0f;

@implementation CarBumpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUp];
    
}
#pragma mart - setUp
-(void)setUp
{
   //1.新建OpenGL ES 上下文
    EAGLContext *mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    [EAGLContext setCurrentContext:view.context];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    
    _cars = [[NSMutableArray alloc]init];
    self.baseFffect = [[GLKBaseEffect alloc]init];
    self.baseFffect.light0.enabled = GL_TRUE;
    self.baseFffect.light0.ambientColor = GLKVector4Make(0.6f, 0.6f, 0.6f, 1.0f);
    
    self.baseFffect.light0.position = GLKVector4Make(1.0f, 0.8f, 0.4f, 0.0f);
    
    
    self.carModel = [[SceneCarModel alloc]init];
    self.rinkModel = [[SceneRinkModel alloc]init];
    
    /*场地
     min = ([0] = -5.05000019, [1] = -0.00499999989, [2] = -5.05000019)
     max = ([0] = 5.05000019, [1] = 0.5, [2] = 5.05000019)
    */
    self.rinkBoundingBox = self.rinkModel.axisAlignedBoundingBox;
    
    //创建4辆汽车
    //绿色汽车，A
    // 参数1：汽车模型
    // 参数2：汽车初始位置
    // 参数3：速度
    // 参数4：颜色
    SceneCar *newCar = [[SceneCar alloc]
                        initWithModel:self.carModel
                        position:GLKVector3Make(1.0f, 0.0f, 1.0f)
                        velocity:GLKVector3Make(1.5f, 0.0f, 1.5f)
                        color:GLKVector4Make(0.0f, 0.5f, 0.0f, 1.0f)];
    newCar.mCarID = 1;
    [_cars addObject:newCar];
    
    //红色汽车,B
    newCar =[[SceneCar alloc]
             initWithModel:self.carModel
             position:GLKVector3Make(1.0f, 0.0f, -1.0f)
             velocity:GLKVector3Make(-1.5f, 0.0f, -1.5f)
             color:GLKVector4Make(0.5f, 0.0f, 0.0f, 1.0f)];
    newCar.mCarID = 2;
    [_cars addObject:newCar];
    
    //蓝色汽车,C
    newCar =[[SceneCar alloc]
             initWithModel:self.carModel
             position:GLKVector3Make(2.0f, 0.0f, -2.0f)
             velocity:GLKVector3Make(-1.5f, 0.0f, -0.5f)
             color:GLKVector4Make(0.0f, 0.0f, 0.5f, 1.0f)];
    newCar.mCarID = 3;
    [_cars addObject:newCar];
    
    //黄色汽车,D
    newCar =[[SceneCar alloc]
             initWithModel:self.carModel
             position:GLKVector3Make(5.0f, 0.0f, -5.0f)
             velocity:GLKVector3Make(2.0f, 0.0f, -1.0f)
             color:GLKVector4Make(1.0f, 1.0f, 0.0f, 1.0f)];
    newCar.mCarID = 4;
    [_cars addObject:newCar];

  
    //eyePosition，表示当前eye所在位置
    self.eyePosition = GLKVector3Make(10.5f, 5.0f, 0.0f);
    self.lookAtPosition = GLKVector3Make(0.0f, 0.5f, 0.0f);
    
    //targetEyePosition 表示eye最终目标的位置
    /*
        之所以需要设置一个目标位置，是为了在视角切换，通过高通滤波器函数SceneVector3FastLowPassFilter和低通滤波器函数SceneVector3SlowLowPassFilter，实现视角平滑过渡。
     */
    
}
#pragma mark - Update
-(void)update
{
    
    if (self.pointOfViewAnimationCountDown > 0) {
        
     self.pointOfViewAnimationCountDown -= self.timeSinceLastUpdate;
    
     self.eyePosition = SceneVector3SlowLowPassFilter(self.timeSinceLastUpdate,
                                                     self.targetEyePosition, self.eyePosition);
    
     self.lookAtPosition = SceneVector3SlowLowPassFilter(
                                                        self.timeSinceLastUpdate, self.targetLookAtPosition, self.lookAtPosition);
        
    }else
    {
     self.eyePosition = SceneVector3FastLowPassFilter(
                                                      self.timeSinceLastUpdate,
                                                      self.targetEyePosition,
                                                      self.eyePosition);
     self.lookAtPosition = SceneVector3FastLowPassFilter(
                                                         self.timeSinceLastUpdate, self.targetLookAtPosition, self.lookAtPosition);
    }
    
    //每辆汽车更新car的位置、偏航角和速度
    [_cars makeObjectsPerformSelector:@selector(updateWithController:) withObject:self];
    
    [self updatePointOfView];
    
    
    
    
}

-(void)updatePointOfView
{
    if (!self.shouldUseFirstPersonPOV) {
        self.targetEyePosition = GLKVector3Make(10.5f, 5.0f, 0.0f);
        self.targetLookAtPosition = GLKVector3Make(0.0f, 0.5f, 0.0f);
        
    }else
    {
        SceneCar *viewCar = [_cars lastObject];
        self.targetEyePosition = GLKVector3Make(viewCar.position.x, viewCar.position.y + 0.45f, viewCar.position.z);
        self.targetLookAtPosition =GLKVector3Add(_eyePosition, viewCar.velocity);
        
    }
}

#pragma mark - DrawInRect
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    self.baseFffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
    //设置投影矩阵-透视投影
    //1.纵横比
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth /(GLfloat)view.drawableHeight;
    
    // 变换管道
    self.baseFffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(35.0f), aspectRatio, 0.1f, 25.0f);
    
    // 设置模型矩阵
    /*
     GLKMatrix4 GLKMatrix4MakeLookAt(float eyeX,
                                    float eyeY,
                                    float eyeZ,
                                    float centerX,
                                    float centerY,
                                    float centerZ,
                                    float upX,
                                    float upY,
                                    float upZ)
    返回一个4x4矩阵变换的世界坐标系坐标
    摄像机位置，目标点位置以及UP向量
    参数列表
     eyeX 眼睛（观察者）位置的x坐标
     eyeY 眼睛（观察者）位置的y坐标
     eyeZ 眼睛（观察者）位置的z坐标
     centerX 目标点位置，x
     centerY 目标点位置，y
     centerZ 目标点位置，z
     upX UP向量x
     upY UP向量y
     upZ UP向量z
     
     源码解析参考：
     https://www.cnblogs.com/calence/p/6645299.html
     */
    self.baseFffect.transform.modelviewMatrix =
                            GLKMatrix4MakeLookAt(self.eyePosition.x,
                                                 self.eyePosition.y,
                                                 self.eyePosition.z,
                                                 self.lookAtPosition.x,
                                                 self.lookAtPosition.y,
                                                 self.lookAtPosition.z,
                                                 0, 1, 0);
 
    //绘制场景
    [self.baseFffect prepareToDraw];
    [self.rinkModel draw];
    
    //绘制汽车
    [_cars makeObjectsPerformSelector:@selector(drawWithBaseEffect:) withObject:self.baseFffect];
    
    //碰撞次数
    self.myBounceLabel.text = [NSString stringWithFormat:@"%ld",[SceneCar getBounceCount]];
    
    SceneCar *viewCar = [_cars lastObject];
    self.myVelocityLabel.text = [NSString stringWithFormat:@"%.1f",GLKVector3Length(viewCar.velocity)];
    
}

//横屏方向问题
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            interfaceOrientation !=
            UIInterfaceOrientationPortrait);
}

#pragma mark - Button Click
//减速
- (IBAction)onSlow:(id)sender {
    
    SceneCar *car = [_cars lastObject];
    [car onSpeedChange:YES];
}

//加速
- (IBAction)onFast:(id)sender {
    
    SceneCar *car = [_cars lastObject];
    [car onSpeedChange:NO];
    
}

//修改视角
- (IBAction)takeShouldUseFirstPersonPOVFrom:(UISwitch *)sender {
    
    self.shouldUseFirstPersonPOV = [sender isOn];
    
    //POV场景动画秒数
    _pointOfViewAnimationCountDown = SceneNumberOfPOVAnimationSeconds;
    
  
}



@end
