//
//  NSFileManager+HOAdditons.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/5/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "NSFileManager+HOAdditons.h"

@implementation NSFileManager (HOAdditons)

+ (NSError *)makeDirectoryAtPath:(NSString *)dir
{
    NSError *err = NULL;
    [self.defaultManager createDirectoryAtPath:dir
        withIntermediateDirectories:YES
        attributes:nil
        error:&err
    ];
    return err;
}

- (BOOL)isEmptyDirectoryAtPath:(NSString *)dir
{
    while ([self enumeratorAtPath:dir].nextObject)
        return NO;
    return YES;
}

@end
