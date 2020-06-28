//
//  SoundEffect.m
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "SoundEffect.h"

@implementation SoundEffect


// 从指定的声音文件中创建系统声音效果对象
+(id)soundEffectWithContentsOfFile:(NSString *)aPath
{
    if (aPath) {
        return [[SoundEffect alloc]initWithContentsOfFile:aPath];
    }
    return nil;
}

// 用指定的声音文件的内容初始化声音效果对象
-(id)initWithContentsOfFile:(NSString *)path
{
    self = [super init];
    
    if (self != nil) {
    
        // 1.获取声音文件路径
        NSURL *aFileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
        // 2.判断声音文件是否存在
        if (aFileURL != nil) {
        
            // 定义SystemSoundID
            SystemSoundID aSoundID;
            
            // 允许应用程序指定由系统声音服务器播放的音频文件。
            /*
             参数1：A CFURLRef for an AudioFile ，一个CFURLRef类型的音频文件
             参数2：Returns a SystemSoundID，返回一个SystemSoundID
             */
            OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)aFileURL, &aSoundID);
            // 判断error 是否等于无错误！
            if (error == kAudioServicesNoError) {
                // 赋值：
                _soundID = aSoundID;
            } else {
                NSLog(@"Error :loading sound path,%d,%@",(int)error,path);
                self = nil;
            }
        } else {
            NSLog(@"URL is nil for path %@",path);
            self = nil;
        }
        
    }
    
    return self;
}

-(void)dealloc
{
    // 可以清除你的声音，该操作可以释放声音对象以及相关的所有资源
    AudioServicesDisposeSystemSoundID(_soundID);
}

-(void)play
{
    // 播放设置的系统音频
    AudioServicesPlaySystemSound(_soundID);
}


@end
