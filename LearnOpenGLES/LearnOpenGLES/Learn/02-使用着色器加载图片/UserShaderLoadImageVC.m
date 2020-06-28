//
//  UserShaderLoadImageVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "UserShaderLoadImageVC.h"
#import "UserShaderLoadImageView.h"

@interface UserShaderLoadImageVC ()

@property(nonatomic, strong) UserShaderLoadImageView *myView;

@end

@implementation UserShaderLoadImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"使用着色器加载图片";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.myView.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight);
    [self.view addSubview:self.myView];
}


- (UserShaderLoadImageView *)myView {
    if (_myView != nil) {
        return _myView;
    }
    
    _myView = [[UserShaderLoadImageView alloc] init];
    
    return _myView;
}
@end
