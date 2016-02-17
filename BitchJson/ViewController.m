//
//  ViewController.m
//  BitchJson
//
//  Created by ND on 16/2/2.
//  Copyright © 2016年 LJH. All rights reserved.
//

#import "ViewController.h"

enum Bean_TYPE{
    JsonModelBean = 1,
    BeeModelBean = 2
};

enum File_TYPE{
    SingleModelBean = 1,
    MutliModelBean = 2
};

@interface ViewController () <NSTextViewDelegate>{
    NSString *_docKey;
    NSString *_fileKey;
    NSMutableArray *_sigleHArray;
    NSMutableArray *_sigleMArray;
    NSMutableArray *_sigleClassNameArray;
    enum Bean_TYPE _beanType;
    enum File_TYPE _fileType;
    NSString *_lastPath;
    NSString *_lastHFile;
}

@property (weak) IBOutlet NSPopUpButton *typeButton;
@property (weak) IBOutlet NSSegmentedControl *SingleMutli;

@end




@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _inputJsonTextView.delegate = self;
    if (_typeButton.selectedItem.tag == 1) {
        _beanType = JsonModelBean;
    }else{
        _beanType = BeeModelBean;
    }
    long clickedSegmentTag = [[_SingleMutli cell] tagForSegment:[_SingleMutli selectedSegment]];
    if (clickedSegmentTag == 1) {
        _fileType = SingleModelBean;
    }else{
        _fileType = MutliModelBean;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (IBAction)showinfinder:(id)sender {
    NSString *testDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:_docKey] stringByAppendingPathComponent:_fileKey];
//    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL URLWithString:testDirectory]]];
    [[NSWorkspace sharedWorkspace] openFile:testDirectory withApplication:@"Finder"];
}

- (IBAction)copyResult:(id)sender {
}


- (IBAction)chooseModelType:(NSPopUpButton *)sender {
    if (sender.selectedItem.tag == 1) {
        _beanType = JsonModelBean;
    }else{
        _beanType = BeeModelBean;
    }
}
- (IBAction)SingleMutliClick:(id)sender {
    long clickedSegmentTag = [[sender cell] tagForSegment:[sender selectedSegment]];
    if (clickedSegmentTag == 1) {
        _fileType = SingleModelBean;
    }else{
        _fileType = MutliModelBean;
    }
}

- (IBAction)generator:(id)sender {
    _infoLabel.stringValue = @"正在解析......";
    _docKey = @"JsonGenerator";
    _sigleMArray = [NSMutableArray new];
    _sigleHArray = [NSMutableArray new];
    _sigleClassNameArray = [NSMutableArray new];
    
    if (_inputJsonTextView.string) {
        NSData *jsonData = [_inputJsonTextView.string dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *error;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingAllowFragments
                                                              error:&error];
            
            if (jsonObject != nil){
                if ([jsonObject isKindOfClass:[NSDictionary class]] || [jsonObject isKindOfClass:[NSArray class]] || [jsonObject isKindOfClass:[NSMutableDictionary class]] || [jsonObject isKindOfClass:[NSMutableArray class]]) {
                    
                    
                    if (_beanType == JsonModelBean) {
                        if (_fileType == SingleModelBean) {
                            [self generSingle:jsonObject];
                        }else{
                            [self iterationMutliJsonModelObj:jsonObject key:nil];
                        }
                    }else{
                        if (_fileType == SingleModelBean) {
                            [self generBeeSingle:jsonObject];
                        }else{
                            [self iterationMutliBeeObj:jsonObject key:nil];
                        }
                    }
                    
                }else{
                    // 解析错误
                    _infoLabel.stringValue = @"Json格式出错......";
                }
            }else{
                // 解析错误
                _infoLabel.stringValue = @"Json格式出错......";
            }
        }
    }
}

#pragma mark 头文件注释
-(NSString *)headerAnnotation{
    return @"\n//\n//  实体类\n//\n//\n//  Created by 实体类生成器.BitchJson\n//  Copyright © 2016年 LJH. All rights reserved.\n//";
    
}

#pragma mark JsonModel
//拼装单文件json串
- (void)generSingle:(id)obj{
    dispatch_queue_t serialQueue=dispatch_queue_create("serial", NULL);
    //将读取plist文档的线程加入串行线程队列serialQueue中并执行
    dispatch_async(serialQueue, ^{
        [self iterationSingleJsonModelObj:obj key:nil];
        
    });
    //将通过url加载图片的线程加入串行线程队列serialQueue中，并等在这前一个加入串行线程队列的读取plist文档线程执行完毕后执行
    dispatch_async(serialQueue, ^{
        NSMutableString *hstring = [[NSMutableString alloc] initWithString:@"#import <Foundation/Foundation.h>\n#import \"JSONModelLib.h\""];
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

//生成单文件jsonmodel
- (void)iterationSingleJsonModelObj:(id)obj key:(NSString *)objKey{
    _fileKey = _entityNameLabel.stringValue;
    if (!_entityNameLabel.stringValue || [_entityNameLabel.stringValue isEqualToString:@""]) {
        _fileKey = @"NACommonModel";
    }
    
    NSString *naClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@",_fileKey]);
    
    
    NSMutableArray *needImportFileName = [NSMutableArray new];
    
    NSMutableString *protrolString = [NSMutableString new];
    [protrolString appendFormat:@"\n@protocol %@ \n@end",naClassName ];
    
    NSMutableString *generatorString = [NSMutableString new];
    [generatorString appendFormat:@"\n@interface %@ : JSONModel",naClassName];
    
    NSMutableString *mGeneratorString = [NSMutableString new];
    [mGeneratorString appendFormat:@"\n@implementation %@",naClassName];
    
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        for (id key in [obj allKeys]) {
            
            id value = [obj objectForKey:key];
            
            if ([value isKindOfClass:[NSDictionary class]] ) {
                [generatorString appendFormat:@"\n@property (retain, nonatomic) %@%@ *%@;",_fileKey,[key capitalizedString],key];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@%@.h\"",_fileKey,[key capitalizedString]]];
                [self iterationSingleJsonModelObj:value key:[NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]]];
            }else if ([value isKindOfClass:[NSArray class]]){
                if ([[value firstObject] isKindOfClass:[NSDictionary class]]) {
                    
                    NSString *nextClassName = [NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]];
                    
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray<%@> *%@;",nextClassName,key];
                    [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                    [self iterationSingleJsonModelObj:[value firstObject] key:nextClassName];
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
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray<%@> *items;",nextClassName];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                [self iterationSingleJsonModelObj:[obj firstObject] key:nextClassName];
            }
        }else{
            //第二层
            [generatorString appendFormat:@"@property (retain, nonatomic) NSArray *%@;",objKey];
        }
    }
    
    
    [generatorString appendFormat:@"\n@end"];
    [mGeneratorString appendString:@"\n@end"];
    
    [_sigleHArray addObject:protrolString];
    [_sigleHArray addObject:generatorString];
    [_sigleMArray addObject:mGeneratorString];
    [_sigleClassNameArray addObject:naClassName];
    
}

//生成多文件jsonmodel
- (void)iterationMutliJsonModelObj:(id)obj key:(NSString *)objKey{
    
    _fileKey = _entityNameLabel.stringValue;
    if (!_entityNameLabel.stringValue || [_entityNameLabel.stringValue isEqualToString:@""]) {
        _fileKey = @"NACommonModel";
    }
    
    NSString *naClassName = (objKey ? objKey : [NSString stringWithFormat:@"%@",_fileKey]);
    
    
    NSMutableArray *needImportFileName = [NSMutableArray new];
    
    NSMutableString *protrolString = [NSMutableString new];
    [protrolString appendFormat:@"\n@protocol %@ \n@end",naClassName ];
    
    NSMutableString *generatorString = [NSMutableString new];
    [generatorString appendFormat:@"\n@interface %@ : JSONModel",naClassName];
    
    NSMutableString *mGeneratorString = [NSMutableString new];
    [mGeneratorString appendFormat:@"\n@implementation %@",naClassName];
    
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        for (id key in [obj allKeys]) {
            
            id value = [obj objectForKey:key];
            
            if ([value isKindOfClass:[NSDictionary class]] ) {
                [generatorString appendFormat:@"\n@property (retain, nonatomic) %@%@ *%@;",_fileKey,[key capitalizedString],key];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@%@.h\"",_fileKey,[key capitalizedString]]];
                [self iterationMutliJsonModelObj:value key:[NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]]];
            }else if ([value isKindOfClass:[NSArray class]]){
                if ([[value firstObject] isKindOfClass:[NSDictionary class]]) {
                    
                    NSString *nextClassName = [NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]];
                    
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray<%@> *%@;",nextClassName,key];
                    [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                    [self iterationMutliJsonModelObj:[value firstObject] key:nextClassName];
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
                [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray<%@> *items;",nextClassName];
                [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                [self iterationMutliJsonModelObj:[obj firstObject] key:nextClassName];
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
    [[NSFileManager defaultManager] removeItemAtPath:testDirectory error:nil];
    if (![[NSFileManager defaultManager] fileExistsAtPath:testDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *hfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",naClassName]];
    NSString *mfilepath = [testDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",naClassName]];
    
    NSString *importHString = @"";;
    if (![NSString stringWithContentsOfFile:hfilepath encoding:NSUTF8StringEncoding error:nil]) {
        importHString = [importHString stringByAppendingString:@"#import <Foundation/Foundation.h>\n#import \"JSONModelLib.h\""];
        for (NSString *im in needImportFileName) {
            importHString = [importHString stringByAppendingString:im];
        }
        importHString = [importHString stringByAppendingString:protrolString];
        
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

#pragma mark BeeModel
//拼装单文件json串
- (void)generBeeSingle:(id)obj{
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

//生成单文件jsonmodel
- (void)iterationSingleBeeObj:(id)obj key:(NSString *)objKey{
    _fileKey = _entityNameLabel.stringValue;
    if (!_entityNameLabel.stringValue || [_entityNameLabel.stringValue isEqualToString:@""]) {
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

//生成多文件jsonmodel
- (void)iterationMutliBeeObj:(id)obj key:(NSString *)objKey{
    
    _fileKey = _entityNameLabel.stringValue;
    if (!_entityNameLabel.stringValue || [_entityNameLabel.stringValue isEqualToString:@""]) {
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
                [self iterationMutliBeeObj:value key:[NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]]];
            }else if ([value isKindOfClass:[NSArray class]]){
                if ([[value firstObject] isKindOfClass:[NSDictionary class]]) {
                    
                    NSString *nextClassName = [NSString stringWithFormat:@"%@%@",_fileKey,[key capitalizedString]];
                    
                    [generatorString appendFormat:@"\n@property (retain, nonatomic) NSArray *%@;",key];
                    [needImportFileName addObject:[NSString stringWithFormat:@"\n#import \"%@.h\"",nextClassName]];
                    [self iterationMutliBeeObj:[value firstObject] key:nextClassName];
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
                [self iterationMutliBeeObj:[obj firstObject] key:nextClassName];
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
    [[NSFileManager defaultManager] removeItemAtPath:testDirectory error:nil];
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

@end
