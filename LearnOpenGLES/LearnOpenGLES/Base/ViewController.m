//
//  ViewController.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "ViewController.h"
#import "LoadImageVC.h"             // 01-使用OpenGLES加载图片
#import "UserShaderLoadImageVC.h"   // 02-使用着色器加载图片
#import "GLSLTriangleVC.h"          // 03-GLSL三角形
#import "GlkitPyramidVC.h"          // 04-GLKit金字塔
#import "DrawingBoardVC.h"          // 05-OpenGLES画板
#import "EarthAndMoonVC.h"          // 06-地球月亮渲染
#import "LightVC.h"                 // 07-光照
#import "CarBumpVC.h"               // 08-汽车碰撞
#import "MakeSkyBoxImageVC.h"       // 09-天空盒子图片处理
#import "SkyBoxVC.h"                // 10-天空盒子
#import "ParticleSystemVC.h"        // 11-粒子系统


typedef NS_ENUM(NSInteger, CellType) {
    CellTypeUnknown,
    CellTypeLoadImge,           // 01-使用OpenGLES加载图片
    CellTypeShaderLoadImge,     // 02-使用着色器加载图片
    CellTypeGLSLTriangle,       // 03-GLSL三角形
    CellTypeGlkitPyramid,       // 04-GLKit金字塔
    CellTypeDrawingBoard,       // 05-OpenGLES画板
    CellTypeEarthAndMoon,       // 06-地球月亮渲染
    CellTypeLight,              // 07-光照
    CellTypeCarBump,            // 08-汽车碰撞
    CellTypeSkyBox,             // 09-天空盒子图片处理
    CellTypeSkyBoxImage,        // 10-天空盒子切图
    CellTypeParticleSystem,     // 11-粒子系统
};

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray     *dataArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"LearnOpenGLES";
    
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:self.tableView];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.textLabel.text = self.dataArr[indexPath.row][@"title"];
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0001f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CellType cellType = [self.dataArr[indexPath.row][@"cellType"] integerValue];
    switch (cellType) {
        case CellTypeLoadImge:          // 01-使用OpenGLES加载图片
        {
            LoadImageVC *vc = [[LoadImageVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeShaderLoadImge:    // 02-使用着色器加载图片
        {
            UserShaderLoadImageVC *vc = [[UserShaderLoadImageVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeGLSLTriangle:      // 03-GLSL三角形
        {
            GLSLTriangleVC *vc = [[GLSLTriangleVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeGlkitPyramid:      // 04-GLKit金字塔
        {
            GlkitPyramidVC *vc = [[UIStoryboard storyboardWithName:@"GlkitPyramid" bundle:nil] instantiateViewControllerWithIdentifier:@"GlkitPyramidVC"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeDrawingBoard:       // 05-OpenGLES画板
        {
            DrawingBoardVC *vc = [[UIStoryboard storyboardWithName:@"DrawingBoard" bundle:nil] instantiateViewControllerWithIdentifier:@"DrawingBoard"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeEarthAndMoon:       // 06-地球月亮渲染
        {
            EarthAndMoonVC *vc = [[UIStoryboard storyboardWithName:@"EarthAndMoon" bundle:nil] instantiateViewControllerWithIdentifier:@"EarthAndMoon"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeLight:              // 07-光照
        {
            LightVC *vc = [[UIStoryboard storyboardWithName:@"Light" bundle:nil] instantiateViewControllerWithIdentifier:@"Light"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeCarBump:           // 08-汽车碰撞
        {
            CarBumpVC *vc = [[UIStoryboard storyboardWithName:@"CarBump" bundle:nil] instantiateViewControllerWithIdentifier:@"CarBump"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeSkyBoxImage:        // 09-天空盒子图片处理
        {
            MakeSkyBoxImageVC *vc = [[MakeSkyBoxImageVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeSkyBox:            // 10-天空盒子
        {
            SkyBoxVC *vc = [[UIStoryboard storyboardWithName:@"SkyBox" bundle:nil] instantiateViewControllerWithIdentifier:@"SkyBox"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case CellTypeParticleSystem:           // 11-粒子系统
        {
            ParticleSystemVC *vc = [[UIStoryboard storyboardWithName:@"ParticleSystem" bundle:nil] instantiateViewControllerWithIdentifier:@"ParticleSystem"];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (UITableView *)tableView {
    if (_tableView != nil) {
        return _tableView;
    }
    
    _tableView                 = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource      = self;
    _tableView.delegate        = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.rowHeight       = 44;
    _tableView.separatorColor  = [UIColor lightGrayColor];
    _tableView.separatorInset  = UIEdgeInsetsZero;
    
    return _tableView;
}

- (NSArray *)dataArr {
    if (_dataArr != nil) {
        return _dataArr;
    }

    _dataArr = @[@{@"title":@"01-使用OpenGLES加载图片",@"cellType":@(CellTypeLoadImge)},
                 @{@"title":@"02-使用着色器加载图片",   @"cellType":@(CellTypeShaderLoadImge)},
                 @{@"title":@"03-GLSL三角形",         @"cellType":@(CellTypeGLSLTriangle)},
                 @{@"title":@"04-GLKit金字塔",        @"cellType":@(CellTypeGlkitPyramid)},
                 @{@"title":@"05-OpenGLES画板",       @"cellType":@(CellTypeDrawingBoard)},
                 @{@"title":@"06-地球月亮渲染",        @"cellType":@(CellTypeEarthAndMoon)},
                 @{@"title":@"07-光照",               @"cellType":@(CellTypeLight)},
                 @{@"title":@"08-汽车碰撞",            @"cellType":@(CellTypeCarBump)},
                 @{@"title":@"09-天空盒子图片处理",         @"cellType":@(CellTypeSkyBoxImage)},
                 @{@"title":@"10-天空盒子",            @"cellType":@(CellTypeSkyBox)},
                 @{@"title":@"11-粒子系统",            @"cellType":@(CellTypeParticleSystem)}
                ];
    
    return _dataArr;
}

@end
