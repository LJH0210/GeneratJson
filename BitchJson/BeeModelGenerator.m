//
//  BeeModelGenerator.m
//  BitchJson
//
//  Created by LJH on 16/2/25.
//  Copyright © 2016年 LJH. All rights reserved.
//

#import "BeeModelGenerator.h"

@interface BeeModelGenerator (){
    NSString *_docKey;
    NSString *_fileKey;
    NSMutableArray *_sigleHArray;
    NSMutableArray *_sigleMArray;
    NSMutableArray *_sigleClassNameArray;
    NSString *_lastPath;
    NSString *_lastHFile;
}

@end

@implementation BeeModelGenerator

#pragma mark  生成单文件model
- (void) generatSingleFile:(id)obj fileKey:(NSString *)fileKey{
    
    _docKey = @"JsonGenerator";
    _fileKey = fileKey;
    _sigleMArray = [NSMutableArray new];
    _sigleHArray = [NSMutableArray new];
    _sigleClassNameArray = [NSMutableArray new];
    
    dispatch_queue_t serialQueue=dispatch_queue_create("serial", NULL);
    //将读取plist文档的线程加入串行线程队列serialQueue中并执行
    dispatch_async(serialQueue, ^{
        [self iterationSingleBeeObj:obj key:nil];
        
    });
    //将通过url加载图片的线程加入串行线程队列serialQueue中，并等在这前一个加入串行线程队列的读取plist文档线程执行完毕后执行
    dispatch_async(serialQueue, ^{
        NSMutableString *hstring = [[NSMutableString alloc] initWithString:@"#import <Foundation/Foundation.h>\n#import <beeFramework060/Bee.h>"];
        NSMutableString *mstring = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"\n#import \"%@.h\"",_sigleClassNameArray.lastObject]];
        for (int i = 0; i<_sigleHArray.count; i++) {
            [hstring appendString:_sigleHArray[i]];
        }
        for (int i = 0 ; i<_sigleMArray.count; i++) {
            [mstring appendString:_sigleMArray[i]];
        }
        
        NSString *testDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:_docKey] stringByAppendingPathComponent:_fileKey];
        [[NSFileManager defaultManager] removeItemAtPath:testDirectory error:nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath:testDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _lastPath = [NSString stringWithString:testDirectory];
        NSString *hfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",_sigleClassNameArray.lastObject]];
        NSString *mfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",_sigleClassNameArray.lastObject]];
        
        [[[self headerAnnotation] stringByAppendingString:hstring] writeToFile:hfilepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [mstring writeToFile:mfilepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        
    });
}

//生成单文件jsonmodel，并添加进退列
- (void)iterationSingleBeeObj:(id)obj key:(NSString *)objKey{
    if (_fileKey.length < 1) {
        _fileKey = @"NACommonModel";
    }
    
    NSString *naClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@",_fileKey]);
    
    
    NSMutableArray *needImportFileName = [NSMutableArray new];
    
    
    NSMutableString *generatorString = [NSMutableString new];
    [generatorString appendFormat:@"\n@interface %@ : BeeModel",naClassName];
    
    NSMutableString *mGeneratorString = [NSMutableString new];
    [mGeneratorString appendFormat:@"\n@implementation %@",naClassName];
    
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        for (id key in [obj allKeys]) {
            
            id value = [obj objectForKey:key];
            
            if ([value isKindOfClass:[NSDictionary class]] ) {
                [generatorString appendFormat:@"\n@property (retain, nonatomic) %@%@ *%@;",_fileKey,[key capitalizedString],key];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@%@.h\"",_fileKey,[key capitalizedString]]];
                [self iterationSingleBeeObj:value key:[NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]]];
            }else if ([value isKindOfClass:[NSArray class]]){
                if ([[value firstObject] isKindOfClass:[NSDictionary class]]) {
                    
                    NSString *nextClassName = [NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]];
                    
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *%@;",key];
                    [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                    [self iterationSingleBeeObj:[value firstObject] key:nextClassName];
                }else{
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *%@;",key];
                }
            }else{
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSString *%@;",key];
                
            }
        }
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        //第一层
        if (!objKey) {
            //            [generatorString appendFormat:@"@property (retain, nonatomic) NSArray *items;\n"];
            if ([[obj firstObject] isKindOfClass:[NSDictionary class]]) {
                
                NSString *nextClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@Items",_fileKey]);
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *items;"];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                [self iterationSingleBeeObj:[obj firstObject] key:nextClassName];
            }
        }else{
            //第二层
            [generatorString appendFormat:@"@property (retain, nonatomic) NSArray *%@;",objKey];
        }
    }
    
    
    [generatorString appendFormat:@"\n@end"];
    [mGeneratorString appendString:@"\n@end"];
    
    [_sigleHArray addObject:generatorString];
    [_sigleMArray addObject:mGeneratorString];
    [_sigleClassNameArray addObject:naClassName];
    
}

#pragma mark  生成多文件Model

- (void)generatMutliFile:(id)obj key:(NSString *)objKey fileKey:(NSString *)fileKey{
    
    _docKey = @"JsonGenerator";
    if(fileKey)_fileKey = fileKey;
    _sigleMArray = [NSMutableArray new];
    _sigleHArray = [NSMutableArray new];
    _sigleClassNameArray = [NSMutableArray new];
    
    NSString *naClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@",_fileKey]);
    
    
    NSMutableArray *needImportFileName = [NSMutableArray new];
    
    NSMutableString *generatorString = [NSMutableString new];
    [generatorString appendFormat:@"\n@interface %@ : BeeModel",naClassName];
    
    NSMutableString *mGeneratorString = [NSMutableString new];
    [mGeneratorString appendFormat:@"\n@implementation %@",naClassName];
    
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        for (id key in [obj allKeys]) {
            
            id value = [obj objectForKey:key];
            
            if ([value isKindOfClass:[NSDictionary class]] ) {
                [generatorString appendFormat:@"\n@property (retain, nonatomic) %@%@ *%@;",_fileKey,[key capitalizedString],key];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@%@.h\"",_fileKey,[key capitalizedString]]];
                [self generatMutliFile:value key:[NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]] fileKey:nil];
            }else if ([value isKindOfClass:[NSArray class]]){
                if ([[value firstObject] isKindOfClass:[NSDictionary class]]) {
                    
                    NSString *nextClassName = [NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]];
                    
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *%@;",key];
                    [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                    [self generatMutliFile:[value firstObject] key:nextClassName fileKey:nil];
                }else{
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *%@;",key];
                }
            }else{
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSString *%@;",key];
                
            }
        }
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        //第一层
        if (!objKey) {
            if ([[obj firstObject] isKindOfClass:[NSDictionary class]]) {
                
                NSString *nextClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@Items",_fileKey]);
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *items;"];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                [self generatMutliFile:[obj firstObject] key:nextClassName fileKey:nil];
            }
        }else{
            //第二层
            [generatorString appendFormat:@"@property (retain, nonatomic) NSArray *%@;",objKey];
        }
    }
    
    
    [generatorString appendFormat:@"\n@end"];
    [mGeneratorString appendString:@"\n@end"];
    
    NSString *testDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:_docKey] stringByAppendingPathComponent:_fileKey];
    _lastPath = [NSString stringWithString:testDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:testDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *hfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",naClassName]];
    NSString *mfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",naClassName]];
    
    NSString *importHString = @"";;
    if (![NSString stringWithContentsOfFile:hfilepath encoding:NSUTF8StringEncoding error:nil]) {
        importHString = [importHString stringByAppendingString:@"#import <Foundation/Foundation.h>\n#import <beeFramework060/Bee.h>"];
        for (NSString *im in needImportFileName) {
            importHString = [importHString stringByAppendingString:im];
        }
    }
    importHString = [importHString stringByAppendingString:generatorString];
    [[[self headerAnnotation] stringByAppendingString:importHString ] writeToFile:hfilepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSString *importMString = @"";
    if (![NSString stringWithContentsOfFile:mfilepath encoding:NSUTF8StringEncoding error:nil]) {
        importMString = [importMString stringByAppendingString:[NSString stringWithFormat:@"#import \"%@.h\"",naClassName]];
        
    }
    importMString = [importMString stringByAppendingString:mGeneratorString];
    [importMString writeToFile:mfilepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(NSString *)headerAnnotation{
    return @"\n//\n//  实体类\n//\n//\n//  Created by 实体类生成器.BitchJson\n//  Copyright © 2016年 LJH. All rights reserved.\n//";
    
}

@end
