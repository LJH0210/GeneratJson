//
//  ViewController.h
//  BitchJson
//
//  Created by ND on 16/2/2.
//  Copyright © 2016年 LJH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (unsafe_unretained) IBOutlet NSTextView *inputJsonTextView;
@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSTextField *entityNameLabel;

@end

