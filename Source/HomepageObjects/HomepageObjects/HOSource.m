//
//  HOSource.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOSource.h"
#import "HOConfig.h"

@implementation HOSource

- initWithPath:(NSString *)path config:(HOConfig *)config
{
    if (!(self = [super init]))
        return self;

    _path = path;
    _config = config;

    return self;
}

- (void)convert {}

@end


@implementation HOOrgSource {
    NSString *_jsonPath;
}

- (void)convert
{
    NSError *err;
    NSTask *task;
    NSFileHandle *stdIn, *stdOut, *stdErr;
    NSString *orgPath, *jsonPath, *emacsInitFile;
    NSString *srcFile;
    NSMutableArray *pathComponents;

    orgPath = self.path;

    // replace $CONTENT_DIR/ with ../$CACHE_DIR/
    // replace .org with .json
    pathComponents = orgPath.pathComponents.mutableCopy;
    if (pathComponents.count > 0) {
        [pathComponents removeObjectAtIndex:0];
        [pathComponents insertObject:@".." atIndex:0];
        [pathComponents insertObject:self.config.cacheRoot atIndex:1];
    }
    [pathComponents removeLastObject];
    srcFile = self.path.lastPathComponent;
    srcFile = srcFile.stringByDeletingPathExtension;
    srcFile = [srcFile stringByAppendingPathExtension:@"json"];
    [pathComponents addObject:srcFile];
    jsonPath = [NSString pathWithComponents:pathComponents];

    // TODO: make directory

    emacsInitFile = self.config[@"emacsInitFile"];
    emacsInitFile = emacsInitFile.stringByExpandingTildeInPath;
    emacsInitFile = emacsInitFile.stringByStandardizingPath;

    stdIn = NSFileHandle.fileHandleWithStandardInput;
    stdOut = NSFileHandle.fileHandleWithStandardOutput;
    stdErr = NSFileHandle.fileHandleWithStandardError;

    task = NSTask.new;
    task.arguments = @[
        @"emacs",
        orgPath,
        @"--batch",
        @"-l",
        emacsInitFile,
        @"--eval",
        [NSString stringWithFormat:
            @"\"(org-export-to-file 'json \\\"%@\\\")\"",
            jsonPath
        ],
    ];
    task.standardInput = stdIn;
    task.standardOutput = stdOut;
    task.standardError = stdErr;

    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&err];
    } else {
        [task launch];
    }
    [task waitUntilExit];

    if (err) {
        fprintf(stderr, "failed to convert %s\n", self.path.UTF8String);
    }

    if (task.terminationStatus != 0) {
        fprintf(stderr, "failed to convert %s\n", self.path.UTF8String);
        fprintf(stderr, "emacs: %s %s\n",
            [[NSString alloc] initWithData:stdOut.readDataToEndOfFile encoding:NSUTF8StringEncoding].UTF8String,
            [[NSString alloc] initWithData:stdErr.readDataToEndOfFile encoding:NSUTF8StringEncoding].UTF8String
        );
        return;
    }
}

@end

@implementation HOMarkdownSource
@end
