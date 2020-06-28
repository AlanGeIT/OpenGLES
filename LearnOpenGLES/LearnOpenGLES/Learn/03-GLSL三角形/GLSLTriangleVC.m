//
//  GLSLTriangleVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "GLSLTriangleVC.h"
#import "GLSLTriangleView.h"

@interface GLSLTriangleVC ()
@property (nonatomic, strong) GLSLTriangleView        *triangleView;
@end

@implementation GLSLTriangleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"GLSL三角形";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.triangleView.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight);
    [self.view addSubview:self.triangleView];
}

- (GLSLTriangleView *)triangleView {
    if (_triangleView != nil) {
        return _triangleView;
    }
    
    _triangleView = [[GLSLTriangleView alloc] init];
    
    return _triangleView;
}

@end
