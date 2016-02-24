//
//  GeneratorProtrol.h
//  BitchJson
//
//  Created by LJH on 16/2/25.
//  Copyright © 2016年 LJH. All rights reserved.
//

@protocol GeneratorProtrol <NSObject>

/**
 *  生成单文件model
 */
- (void) generatSingleFile:(id)obj fileKey:(NSString *)fileKey;
/**
 *  生成多文件Model
 */
- (void)generatMutliFile:(id)obj key:(NSString *)objKey fileKey:(NSString *)fileKey;
@end
