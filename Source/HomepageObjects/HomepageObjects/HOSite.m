//
//  HOSite.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOSite.h"
#import "NSFileManager+HOAdditons.h"

@implementation HOSite

+ newSiteWithTitle:(NSString *)title
    inDirectory:(NSString *)dir error:(NSError * _Nullable *)error
{
    NSFileManager *fm;
    NSError *err;
    BOOL isDir;

    fprintf(stderr, "Create \"%s\" at %s\n", title.UTF8String, dir.UTF8String);

    fm = NSFileManager.defaultManager;

    if ([fm fileExistsAtPath:dir isDirectory:&isDir]) {
        if (!isDir) {
            fprintf(stderr, "%s is a file\n", dir.UTF8String);
            return nil;
        }
        if (![fm isEmptyDirectoryAtPath:dir]) {
            fprintf(stderr, "%s is not empty\n", dir.UTF8String);
            return nil;
        }
    } else {
        [fm createDirectoryAtPath:dir
            withIntermediateDirectories:YES
            attributes:nil
            error:&err
        ];
        if (err) {
            *error = err;
            return nil;
        }
    }

    // TODO: populate directory

    return nil;
}

@end
