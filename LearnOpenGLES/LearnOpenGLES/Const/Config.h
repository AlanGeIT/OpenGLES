//
//  Config.h
//  LearnOpenGLES
//
//  Created by Alan Ge on 2020/6/16.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#ifndef Config_h
#define Config_h

/*********************** 打印宏 ******************************/
#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\t%s line %d:\t%s\t\n",__TIME__,[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif

#endif /* Config_h */
