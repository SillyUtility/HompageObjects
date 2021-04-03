//
//  HOSource.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOSource.h"
#import "HOConfig.h"
#import "HOOrgParser.h"
#import "HOUtils.h"

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
- (void)parse {}

@end


@implementation HOOrgSource {
    NSString *_jsonPath;
    HOOrgParser *_parser;
    NSUInteger _depth;
    NSMutableString *_html;
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

    _jsonPath = relPath;

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
        task.executableURL = [NSURL fileURLWithPath:emacsPath];
        [task launchAndReturnError:&err];
    } else {
        task.launchPath = emacsPath;
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

- (void)parse
{
    _html = NSMutableString.string;
    _parser = [[HOOrgParser alloc] initWithJSONAtPath:_jsonPath];
    _parser.delegate = self;
    [_parser parse];
}

- (void)parserDidStartDocument:(HOOrgParser *)parser
{
    log_indent(_depth++, "org doc start\n", "");
}

- (void)parserDidEndDocument:(HOOrgParser *)parser
{
    log_indent(--_depth, "org doc end\n", "");
}

- (void)parser:(HOOrgParser *)parser
    parseDocumentProperties:(NSDictionary<NSString *, id> *)properties
{
    log_indent(_depth, "props %s\n", properties.description.UTF8String);
    [self.properties addEntriesFromDictionary:properties];
}

- (void)parser:(HOOrgParser *)parser didStartNode:(NSString *)nodeType
    reference:(NSString *)ref
    properties:(NSDictionary<NSString *, id> *)properties
{
    log_indent(_depth++, "node start %s\n", nodeType.UTF8String);
    if ([nodeType isEqualToString:@"headline"]) {
        [_html appendFormat:@"<section>\n\t<header>\n\t\t<h%@>%@</h%@>\n\t</header>\n",
            properties[@"level"],
            [self parseMarkupList:properties[@"title"]],
            properties[@"level"]
        ];
    }
    if ([nodeType isEqualToString:@"paragraph"])
        [_html appendString:@"<p>"];
    if ([nodeType isEqualToString:@"italic"])
        [_html appendString:@"<i>"];
    if ([nodeType isEqualToString:@"bold"])
        [_html appendString:@"<b>"];
    if ([nodeType isEqualToString:@"underline"])
        [_html appendString:@"<u>"];
    if ([nodeType isEqualToString:@"strikethrough"])
        [_html appendString:@"<s>"];
    if ([nodeType isEqualToString:@"subscript"])
        [_html appendString:@"<sub>"];
    if ([nodeType isEqualToString:@"superscript"])
        [_html appendString:@"<sup>"];
    if ([nodeType isEqualToString:@"verbatim"])
        [_html appendFormat:@"<code>%@", enc(properties[@"value"])];
    if ([nodeType isEqualToString:@"code"])
        [_html appendFormat:@"<code>%@", enc(properties[@"value"])];
    if ([nodeType isEqualToString:@"src-block"])
        [_html appendFormat:@"<pre>%@", enc(properties[@"value"])];
    if ([nodeType isEqualToString:@"table"]) {
        // properties[@"name"]
        // properties[@"attr_html"]
        [_html appendString:@"<table>"];
        if (properties[@"caption"])
            [_html appendFormat:@"<caption>%@</caption>",
                [self parseMarkupList:properties[@"caption"]]];
    }
    if ([nodeType isEqualToString:@"table-row"])
        [_html appendString:@"<tr>"];
    if ([nodeType isEqualToString:@"table-cell"])
        [_html appendString:@"<td>"];
    if ([nodeType isEqualToString:@"entity"])
        [_html appendString:properties[@"html"]];
    if ([nodeType isEqualToString:@"ordered-list"])
            [_html appendString:@"<ol>"];
    if ([nodeType isEqualToString:@"unordered-list"])
            [_html appendString:@"<ul>"];
    if ([nodeType isEqualToString:@"item"])
        [_html appendString:@"<li>"];
    if ([nodeType isEqualToString:@"description-list"])
        [_html appendString:@"<dl>"];
    if ([nodeType isEqualToString:@"description-term"])
        [_html appendFormat:@"<dt>%@</dt><dd>",
            [self parseMarkupList:properties[@"tag"]]];
}

- (void)parser:(HOOrgParser *)parser
    didEndNode:(NSString *)nodeType
    trailingSpace:(BOOL)space
{
    log_indent(--_depth, "node end %s\n", nodeType.UTF8String);
    if ([nodeType isEqualToString:@"headline"]) {
        [_html appendFormat:@"</section>\n"];
    }
    if ([nodeType isEqualToString:@"paragraph"])
        [_html appendString:@"</p>"];
    if ([nodeType isEqualToString:@"italic"])
        [_html appendString:@"</i>"];
    if ([nodeType isEqualToString:@"bold"])
        [_html appendString:@"</b>"];
    if ([nodeType isEqualToString:@"underline"])
        [_html appendString:@"</u>"];
    if ([nodeType isEqualToString:@"strikethrough"])
        [_html appendString:@"</s>"];
    if ([nodeType isEqualToString:@"subscript"])
        [_html appendString:@"</sub>"];
    if ([nodeType isEqualToString:@"superscript"])
        [_html appendString:@"</sup>"];
    if ([nodeType isEqualToString:@"verbatim"])
        [_html appendString:@"</code>"];
    if ([nodeType isEqualToString:@"code"])
        [_html appendString:@"</code>"];
    if ([nodeType isEqualToString:@"src-block"])
        [_html appendString:@"</pre>"];
    if ([nodeType isEqualToString:@"table"])
        [_html appendString:@"</table>"];
    if ([nodeType isEqualToString:@"table-row"])
        [_html appendString:@"</tr>"];
    if ([nodeType isEqualToString:@"table-cell"])
        [_html appendString:@"</td>"];
    if ([nodeType isEqualToString:@"ordered-list"])
            [_html appendString:@"</ol>"];
    if ([nodeType isEqualToString:@"unordered-list"])
            [_html appendString:@"</ul>"];
    if ([nodeType isEqualToString:@"item"])
        [_html appendString:@"</li>"];
    if ([nodeType isEqualToString:@"description-list"])
        [_html appendString:@"</dl>"];
    if ([nodeType isEqualToString:@"description-term"])
        [_html appendString:@"</dd>"];

    if (space)
        [_html appendString:@" "];
}

- (void)parser:(HOOrgParser *)parser parseString:(NSString *)str
{
    log_indent(_depth, "%s\n", str.UTF8String);
    // TODO: process "\-", "--", "---", and "..."
    [_html appendString:str];
}

- (void)parser:(HOOrgParser *)parser parseError:(NSString *)message
{

}

NSString *enc(NSString *s)
{
    NSString *r = s;
    r = [r stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    r = [r stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    r = [r stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    r = [r stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    r = [r stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    return r;
}

- (NSString *)parseMarkupList:(NSArray *)markup
{
    NSMutableString *ret;
    ret = NSMutableString.string;
    for (id node in markup) {
        if ([node isKindOfClass:NSString.class]) {
            [ret appendString:node];
            continue;
        }
        if ([node isKindOfClass:NSDictionary.class]) {
            [ret appendString:[self parseMarkupNode:node]];
            continue;
        }
        if ([node isKindOfClass:NSArray.class]) {
            [ret appendString:[self parseMarkupList:node]];
            continue;
        }
    }
    return (NSString *)ret;
}

- (NSString *)parseMarkupNode:(NSDictionary *)node
{
    NSMutableString *ret;
    ret = NSMutableString.string;
    if ([node[@"type"] isEqualToString:@"italic"]) {
        [ret appendFormat:@"<i>%@</i>",
            [self parseMarkupList:node[@"contents"]]];
    }
    if ([node[@"type"] isEqualToString:@"bold"]) {
        [ret appendFormat:@"<b>%@</b>",
            [self parseMarkupList:node[@"contents"]]];
    }
    if ([node[@"type"] isEqualToString:@"underline"]) {
        [ret appendFormat:@"<u>%@</u>",
            [self parseMarkupList:node[@"contents"]]];
    }
    if ([node[@"type"] isEqualToString:@"strikethrough"]) {
        [ret appendFormat:@"<s>%@</s>",
            [self parseMarkupList:node[@"contents"]]];
    }
    return (NSString *)ret;
}

- (NSString *)HTML
{
    return (NSString *)_html;
}

@end

@implementation HOMarkdownSource
@end
