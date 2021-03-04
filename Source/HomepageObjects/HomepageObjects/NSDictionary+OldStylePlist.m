//
//  NSDictionary+OldStylePlist.m
//  
//
//  Created by Eddie Hillenbrand on 3/3/21.
//

#import "NSDictionary+OldStylePlist.h"

@implementation NSDictionary (OldStylePlist)

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
