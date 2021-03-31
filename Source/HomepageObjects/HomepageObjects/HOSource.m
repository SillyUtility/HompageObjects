//
//  HOSource.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOSource.h"
#import "HOConfig.h"

#import "NSFileManager+HOAdditons.h"

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
    NSPipe *pipeIn, *pipeOut, *pipeErr;
    NSFileHandle *stdIn, *stdOut, *stdErr;
    NSString *outStr, *outErr;
    NSString *orgPath, *relPath, *jsonPath,
        *emacsPath, *emacsInitFile;
    NSString *cacheDir, *cwd, *srcFile;
    NSMutableArray *pathComponents;

    orgPath = self.path;
    //fprintf(stderr, "convert %s to ", orgPath.UTF8String);

    // replace $CONTENT_DIR/ with ../$CACHE_DIR/
    // replace .org with .json
    pathComponents = orgPath.pathComponents.mutableCopy;
    if (pathComponents.count > 0) {
        [pathComponents removeObjectAtIndex:0];
        [pathComponents insertObject:self.config.cacheRoot atIndex:0];
    }
    [pathComponents removeLastObject];
    cacheDir = [NSString pathWithComponents:pathComponents];

    srcFile = self.path.lastPathComponent;
    srcFile = srcFile.stringByDeletingPathExtension;
    srcFile = [srcFile stringByAppendingPathExtension:@"json"];
    [pathComponents addObject:srcFile];
    relPath = [NSString pathWithComponents:pathComponents];

    cwd = NSFileManager.defaultManager.currentDirectoryPath;
    [pathComponents insertObject:cwd atIndex:0];
    jsonPath = [NSString pathWithComponents:pathComponents];

    //fprintf(stderr, "%s\n", relPath.UTF8String);

    err = [NSFileManager makeDirectoryAtPath:cacheDir];
    if (err) {
        fprintf(stderr, "dir error %s %s\n",
            cacheDir.UTF8String,
            err.localizedDescription.UTF8String);
        return;
    }

    emacsPath = self.config[@"emacsPath"];
    emacsInitFile = self.config[@"emacsInitFile"];
    emacsInitFile = emacsInitFile.stringByExpandingTildeInPath;
    emacsInitFile = emacsInitFile.stringByStandardizingPath;

    //fprintf(stderr, "%s %s\n", emacsPath.UTF8String,
    //    emacsInitFile.UTF8String);

    pipeIn = NSPipe.pipe;
    pipeOut = NSPipe.pipe;
    pipeErr = NSPipe.pipe;

    task = NSTask.new;
    task.executableURL = [NSURL fileURLWithPath:emacsPath];
    task.arguments = @[
        orgPath,
        @"--batch",
        @"-l",
        emacsInitFile,
        @"--eval",
        [NSString stringWithFormat:
            @"(org-export-to-file 'json \"%@\")",
            jsonPath
        ],
    ];
    task.standardInput = pipeIn;
    task.standardOutput = pipeOut;
    task.standardError = pipeErr;

    stdIn = [task.standardInput fileHandleForWriting];
    stdOut = [task.standardOutput fileHandleForReading];
    stdErr = [task.standardError fileHandleForReading];

    //fprintf(stderr, "task.arguments %s\n",
    //    task.arguments.description.UTF8String);

    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&err];
    } else {
        [task launch];
    }
    [task waitUntilExit];

    outStr = [[NSString alloc]
        initWithData:stdOut.readDataToEndOfFile
        encoding:NSUTF8StringEncoding
    ];
    outErr = [[NSString alloc]
        initWithData:stdErr.readDataToEndOfFile
        encoding:NSUTF8StringEncoding
    ];

    if (err) {
        fprintf(stderr, "failed to convert %s %s\n",
            self.path.UTF8String,
            err.localizedDescription.UTF8String);
        fprintf(stderr, "emacs: %s %s\n",
            outStr.UTF8String, outErr.UTF8String);
        return;
    }

    if (task.terminationStatus != 0) {
        fprintf(stderr, "failed to convert %s\n", self.path.UTF8String);
        fprintf(stderr, "emacs: %s %s\n",
            outStr.UTF8String, outErr.UTF8String);
        return;
    }

    /* [HOOrgParser parseJSONAtPath:jsonPath] */
}

@end

@implementation HOMarkdownSource
@end
