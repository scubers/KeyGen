//
//  TestTT.m
//  KeyGen_Example
//
//  Created by Jrwong on 2019/7/31.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

#import "TestTT.h"
#import "KeyGen_Example-Swift.h"
@import KeyGen;

@implementation TestTT

+ (void)load {
    NSLog(@"%@", [KGKeyStore get:@"secret"]);
}

@end
