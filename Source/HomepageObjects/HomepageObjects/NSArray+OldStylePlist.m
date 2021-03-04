//
//  NSArray+OldStylePlist.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/3/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "NSArray+OldStylePlist.h"

@implementation NSArray (OldStylePlist)

- (BOOL)writeOldStylePlistToURL:(NSURL *)url
    error:(NSError * _Nullable *)error;
{
    return [self.description
        writeToURL:url
        atomically:YES
        encoding:NSUTF8StringEncoding
        error:error
    ];
}

@end
