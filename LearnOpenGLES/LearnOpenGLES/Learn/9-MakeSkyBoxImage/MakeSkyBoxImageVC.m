//
//  MakeSkyBoxImageVC.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/19.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "MakeSkyBoxImageVC.h"

@interface MakeSkyBoxImageVC ()

@property(nonatomic,strong)UIImageView *CCImageView;

@end

@implementation MakeSkyBoxImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 显示图片
    // 1.创建一个宽100,长100 * 6 的图片的View(天空盒子的图片大小,100 * 100 ,6张)
    self.CCImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 100 * 6)];
    
    // 2.获取图片
    UIImage *CImage = [UIImage imageNamed:@"skybox1.png"];
    
    // 3.加载图片
    [self.CCImageView setImage:CImage];
    
    // 4.
    [self.view addSubview:self.CCImageView];
    
    // 处理图片
    // 1.获取图片的长度?
    long length = CImage.size.width / 4;
    
    // 2.图片顶点索引 x,y,z轴方式
    long indices[] = {
        // right
        length * 2,length,
        // left
        0,length,
        // top
        length,0,
        // bottom
        length,length * 2,
        // front
        length,length,
        // back
        length * 3,length
    };
    
    // 3.指定图片的个数，除以2：因为包含xy
    long faceCount = sizeof(indices)/sizeof(indices[0])/2;
    
    // 4.获取图片大小,单个图片大小 length * length,组合起来:length,length * faceCount
    CGSize imageSize= {length,length * faceCount};
    
    //5.创建基于位图的图形上下文,并且使得其作为当前的上下文
    UIGraphicsBeginImageContext(imageSize);
    
    for (int i = 0; i + 2 <= faceCount * 2; i += 2) {
     
        // 创建图片
        CGImageRef CGImage = CGImageCreateWithImageInRect(CImage.CGImage, CGRectMake(indices[i], indices[i+1], length, length));
        
        // CGImage 转为 UImage
        UIImage *tmp = [UIImage imageWithCGImage:CGImage];
        
        // 绘制图片
        [tmp drawInRect:CGRectMake(0, length * i / 2, length, length)];
    
    }
    
    // 6.获取处理好的图片
    UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
    
    // 7.保存图片到沙盒
    // 1.指定图片路径
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"CCImage.png"];
    
    // 2.打印路径
    NSLog(@"image path:%@",path);
    
    // 获取图片的数据
    NSData *cImageData = UIImagePNGRepresentation(finalImg);
    
    // 将数据写入到文件
    BOOL writeStatus = [cImageData writeToFile:path atomically:YES];
    
    if (writeStatus) {
        NSLog(@"处理图片成功!");
    } else {
        NSLog(@"处理图片失败!");
    }
    
    // 显示结果
    [self.CCImageView setImage:finalImg];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
