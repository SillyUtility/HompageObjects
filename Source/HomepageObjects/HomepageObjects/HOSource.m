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
    _properties = NSMutableDictionary.dictionary;

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

- (void)emitSection:(NSDictionary<NSString *, id> *)properties
{
    NSNumber *level;
    NSString *ident, *title;

    level = properties[@"level"];
    ident = [self makeIdentifier:properties[@"raw-value"]];
    title = [self parseMarkupList:properties[@"title"]];

    [_html appendString:@"<section><header>"];
    [_html appendFormat:@"<h%@ id=\"%@\">%@</h%@>",
        level, ident, title, level];
    [_html appendString:@"</header>"];
}

- (void)emitTable:(NSDictionary<NSString *, id> *)properties
{
    NSString *name, *attrs;

    attrs = [self parseAttributes:properties[@"attr_html"]];

    if (properties[@"name"]) {
        name = [self makeIdentifier:properties[@"name"]];
        [_html appendFormat:@"<table id=\"%@\"%@", name, attrs];
    } else
        [_html appendFormat:@"<table%@>", attrs];

    if (properties[@"caption"])
        [_html appendFormat:@"<caption>%@</caption>",
            [self parseMarkupList:properties[@"caption"]]];
}

- (void)emitLatex:(NSDictionary<NSString *, id> *)properties
{
    NSString *name, *attrs;

    attrs = [self parseAttributes:properties[@"attr_html"]];

    if (properties[@"name"]) {
        name = [self makeIdentifier:properties[@"name"]];
        [_html appendFormat:@"<figure id=\"%@\"%@>", name, attrs];
    } else
        [_html appendFormat:@"<figure%@>", attrs];

    if (properties[@"caption"])
        [_html appendFormat:@"<figcaption>%@</figcaption>",
            [self parseMarkupList:properties[@"caption"]]];

    [_html appendString:properties[@"value"]];
    [_html appendString:@"</figure>"];
}

- (void)emitFigure:(NSDictionary<NSString *, id> *)properties
{
    NSString *name, *attrs;

    attrs = [self parseAttributes:properties[@"attr_html"]];

    if (properties[@"name"]) {
        name = [self makeIdentifier:properties[@"name"]];
        [_html appendFormat:@"<figure id=\"%@\"%@>", name, attrs];
    } else
        [_html appendFormat:@"<figure%@>", attrs];

    if (properties[@"caption"])
        [_html appendFormat:@"<figcaption>%@</figcaption>",
            [self parseMarkupList:properties[@"caption"]]];
}

- (void)emitExample:(NSDictionary<NSString *, id> *)properties
{
    [_html appendFormat:@"<pre>%@", enc(properties[@"value"])];
}

- (void)emitSource:(NSDictionary<NSString *, id> *)properties
{
    [_html appendFormat:@"<pre>%@", enc(properties[@"value"])];
}

- (void)emitFooter:(NSDictionary<NSString *, id> *)properties
{
    NSNumber *level;
    NSString *ident, *title;

    level = properties[@"level"];
    ident = [self makeIdentifier:properties[@"raw-value"]];
    title = [self parseMarkupList:properties[@"title"]];

    [_html appendString:@"<footer>"];
    [_html appendFormat:@"<h%@ id=\"%@\">%@</h%@>",
        level, ident, title, level];
    [_html appendString:@"<ul>"];
}

- (void)emitLink:(NSDictionary<NSString *,id> *)properties
{
    if ([properties[@"type"] hasPrefix:@"http"]) {
        [_html appendFormat:@"<a href=\"%@\">",
            properties[@"raw-link"]];
        if ([properties[@"format"] isEqualToString:@"plain"])
            [_html appendString:properties[@"raw-link"]];
    }

    if ([properties[@"type"] isEqualToString:@"file"]) {
        if ([properties[@"is-inline-image"] boolValue]) {
            [_html appendFormat:@"<img src=\"%@\">",
                properties[@"raw-link"]];
        }
    }

    if ([properties[@"type"] isEqualToString:@"fuzzy"]) {
        [_html appendFormat:@"<a href=\"#%@\">",
            [self makeIdentifier:properties[@"raw-link"]]];
    }

    if ([properties[@"type"] isEqualToString:@"radio"]) {
        [_html appendFormat:@"<a href=\"#%@\">",
            [self makeIdentifier:properties[@"raw-link"]]];
    }
}

- (void)parser:(HOOrgParser *)parser
    didStartNode:(NSString *)nodeType
    reference:(NSString *)ref
    properties:(NSDictionary<NSString *, id> *)properties
{
    log_indent(_depth++, "node start %s\n", nodeType.UTF8String);

    // bold
    if ([nodeType isEqualToString:@"bold"])
        [_html appendString:@"<b>"];

    // center-block
    if ([nodeType isEqualToString:@"center-block"])
        [_html appendString:@"<center>"];

    // clock

    // code
    if ([nodeType isEqualToString:@"code"])
        [_html appendFormat:@"<code>%@", enc(properties[@"value"])];

    // description-list
    if ([nodeType isEqualToString:@"description-list"])
        [_html appendString:@"<dl>"];

    // description-term
    if ([nodeType isEqualToString:@"description-term"])
        [_html appendFormat:@"<dt>%@</dt><dd>",
            [self parseMarkupList:properties[@"tag"]]];

    // drawer
    // dynamic-block

    // entity
    if ([nodeType isEqualToString:@"entity"])
        [_html appendString:properties[@"html"]];

    // example-block
    if ([nodeType isEqualToString:@"example-block"])
        [self emitExample:properties];

    // export-block
    if ([nodeType isEqualToString:@"export-block"])
        if ([properties[@"type"] isEqualToString:@"HTML"])
            [_html appendString:properties[@"value"]];

    // export-snippet

    // figure
    if ([nodeType isEqualToString:@"figure"])
        [self emitFigure:properties];

    // fixed-width
    if ([nodeType isEqualToString:@"fixed-width"])
        [_html appendFormat:@"<pre>%@</pre>", enc(properties[@"value"])];

    // footnote-headline
    if ([nodeType isEqualToString:@"footnote-headline"]) {
        [self emitFooter:properties];
    }

    // footnote-definition
    if ([nodeType isEqualToString:@"footnote-definition"])
        [_html appendFormat:@"<li id=\"fn:%@\">[%@] ",
            properties[@"label"],
            properties[@"label"]];

    // footnote-reference
    if ([nodeType isEqualToString:@"footnote-reference"])
        [_html appendFormat:@"[<a href=\"#fn:%@\">%@</a>]",
            properties[@"label"],
            properties[@"label"]];

    // headline
    if ([nodeType isEqualToString:@"headline"])
        [self emitSection:properties];

    // horizontal-rule
    if ([nodeType isEqualToString:@"horizontal-rule"])
        [_html appendString:@"<hr>"];

    // inline-src-block
    if ([nodeType isEqualToString:@"inline-src-block"])
        [_html appendFormat:@"<code>%@</code>", enc(properties[@"value"])];

    // inlinetask
    // inner-template

    // italic
    if ([nodeType isEqualToString:@"italic"])
        [_html appendString:@"<i>"];

    // item
    if ([nodeType isEqualToString:@"item"])
        [_html appendString:@"<li>"];

    // keyword
    if ([nodeType isEqualToString:@"keyword"]) {
        if ([properties[@"key"] hasPrefix:@"HTML_HEAD"]) {
            if (self.properties[properties[@"key"]]) {
                self.properties[properties[@"key"]] =
                    [self.properties[properties[@"key"]]
                        stringByAppendingFormat:@"\n%@",
                        properties[@"value"]
                    ];
            } else {
                self.properties[properties[@"key"]] = properties[@"value"];
            }
        } else {
            if ([properties[@"key"] isEqualToString:@"HTML"])
                [_html appendFormat:@"\n%@", properties[@"value"]];
            else
                self.properties[properties[@"key"]] = properties[@"value"];
        }
    }

    // latex-environment
    if ([nodeType isEqualToString:@"latex-environment"])
        [self emitLatex:properties];

    // latex-fragment
    if ([nodeType isEqualToString:@"latex-fragment"])
        [_html appendString:properties[@"value"]];

    // line-break
    if ([nodeType isEqualToString:@"line-break"])
        [_html appendString:@"<br>"];

    // link
    if ([nodeType isEqualToString:@"link"]) {
        [self emitLink:properties];
    }

    // node-property

    // ordered-list
    if ([nodeType isEqualToString:@"ordered-list"])
        [_html appendString:@"<ol>"];

    // paragraph
    if ([nodeType isEqualToString:@"paragraph"])
        [_html appendString:@"<p>"];

    // plain-list
    // plain-text
    // planning
    // property-drawer

    // quote-block
    if ([nodeType isEqualToString:@"quote-block"])
        [_html appendString:@"<blockquote>"];

    // radio-target
    if ([nodeType isEqualToString:@"radio-target"])
        [_html appendFormat:@"<a id=\"%@\">",
            [self makeIdentifier:properties[@"value"]]];

    // section

    // special-block
    if ([nodeType isEqualToString:@"special-block"])
        [_html appendFormat:@"<%@>", properties[@"type"]];

    // src-block
    if ([nodeType isEqualToString:@"src-block"])
        [self emitSource:properties];

    // statistics-cookie

    // strike-through
    if ([nodeType isEqualToString:@"strikethrough"])
        [_html appendString:@"<s>"];

    // subscript
    if ([nodeType isEqualToString:@"subscript"])
        [_html appendString:@"<sub>"];

    // superscript
    if ([nodeType isEqualToString:@"superscript"])
        [_html appendString:@"<sup>"];

    // table
    if ([nodeType isEqualToString:@"table"])
        [self emitTable:properties];

    // table-cell
    if ([nodeType isEqualToString:@"table-cell"])
        [_html appendString:@"<td>"];

    // table-row
    if ([nodeType isEqualToString:@"table-row"])
        [_html appendString:@"<tr>"];

    // target
    if ([nodeType isEqualToString:@"target"])
        [_html appendFormat:@"<a id=\"%@\">",
            [self makeIdentifier:properties[@"value"]]];

    // template
    // timestamp

    // underline
    if ([nodeType isEqualToString:@"underline"])
        [_html appendString:@"<u>"];

    // unordered-list
    if ([nodeType isEqualToString:@"unordered-list"])
        [_html appendString:@"<ul>"];

    // verbatim
    if ([nodeType isEqualToString:@"verbatim"])
        [_html appendFormat:@"<code>%@", enc(properties[@"value"])];

    // verse-block
    if ([nodeType isEqualToString:@"verse-block"])
        [_html appendString:@"<blockquote><pre>"];
}

- (void)parser:(HOOrgParser *)parser
    didEndNode:(NSString *)nodeType
    trailingSpace:(BOOL)space
    properties:(nonnull NSDictionary<NSString *,id> *)properties
{
    log_indent(--_depth, "node end %s\n", nodeType.UTF8String);

    // bold
    if ([nodeType isEqualToString:@"bold"])
        [_html appendString:@"</b>"];

    // center-block
    if ([nodeType isEqualToString:@"center-block"])
        [_html appendString:@"</center>"];

    // clock

    // code
    if ([nodeType isEqualToString:@"code"])
        [_html appendString:@"</code>"];

    // description-list
    if ([nodeType isEqualToString:@"description-list"])
        [_html appendString:@"</dl>"];

    // description-term
    if ([nodeType isEqualToString:@"description-term"])
        [_html appendString:@"</dd>"];

    // drawer
    // dynamic-block
    // entity

    // example-block
    if ([nodeType isEqualToString:@"example-block"])
        [_html appendString:@"</pre>"];

    // export-block
    // export-snippet

    // figure
    if ([nodeType isEqualToString:@"figure"])
        [_html appendString:@"</figure>"];

    // fixed-width

    // footnote-definition
    
    // footnote-headline
    if ([nodeType isEqualToString:@"footnote-headline"])
        [_html appendString:@"</ul></footer>"];

    // footnote-reference
    if ([nodeType isEqualToString:@"footnote-definition"])
        [_html appendFormat:@"</li>"];

    // headline
    if ([nodeType isEqualToString:@"headline"])
        [_html appendFormat:@"</section>\n"];

    // horizontal-rule
    // inline-src-block
    // inlinetask
    // inner-template

    // italic
    if ([nodeType isEqualToString:@"italic"])
        [_html appendString:@"</i>"];

    // item
    if ([nodeType isEqualToString:@"item"])
        [_html appendString:@"</li>"];

    // keyword

    // latex-environment
    // latex-fragment
    // line-break

    // link
    if ([nodeType isEqualToString:@"link"])
        [_html appendString:@"</a>"];

    // node-property

    // ordered-list
    if ([nodeType isEqualToString:@"ordered-list"])
        [_html appendString:@"</ol>"];

    // paragraph
    if ([nodeType isEqualToString:@"paragraph"])
        [_html appendString:@"</p>"];

    // plain-list
    // plain-text
    // planning
    // property-drawer

    // quote-block
    if ([nodeType isEqualToString:@"quote-block"])
        [_html appendString:@"</blockquote>"];

    // radio-target
    if ([nodeType isEqualToString:@"radio-target"])
        [_html appendString:@"</a>"];

    // section

    // special-block
    if ([nodeType isEqualToString:@"special-block"])
        [_html appendFormat:@"</%@>", properties[@"type"]];

    // src-block
    if ([nodeType isEqualToString:@"src-block"])
        [_html appendString:@"</pre>"];

    // statistics-cookie

    // strike-through
    if ([nodeType isEqualToString:@"strikethrough"])
        [_html appendString:@"</s>"];

    // subscript
    if ([nodeType isEqualToString:@"subscript"])
        [_html appendString:@"</sub>"];

    // superscript
    if ([nodeType isEqualToString:@"superscript"])
        [_html appendString:@"</sup>"];

    // table
    if ([nodeType isEqualToString:@"table"])
        [_html appendString:@"</table>"];

    // table-cell
    if ([nodeType isEqualToString:@"table-cell"])
        [_html appendString:@"</td>"];

    // table-row
    if ([nodeType isEqualToString:@"table-row"])
        [_html appendString:@"</tr>"];

    // target
    if ([nodeType isEqualToString:@"target"])
        [_html appendString:@"</a>"];

    // template
    // timestamp

    // underline
    if ([nodeType isEqualToString:@"underline"])
        [_html appendString:@"</u>"];

    // unordered-list
    if ([nodeType isEqualToString:@"unordered-list"])
        [_html appendString:@"</ul>"];

    // verbatim
    if ([nodeType isEqualToString:@"verbatim"])
        [_html appendString:@"</code>"];

    // verse-block
    if ([nodeType isEqualToString:@"verse-block"])
        [_html appendString:@"</pre></blockquote>"];

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

- (NSString *)makeIdentifier:(NSString *)str
{
    NSMutableString *ident;
    NSUInteger i;
    unichar c;
    NSCharacterSet *wsSet;

    ident = NSMutableString.string;
    wsSet = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    str = [str
        stringByApplyingTransform:NSStringTransformToLatin
        reverse:NO
    ];

    // TODO: allow URLFragmentAllowedCharacterSet or at least the
    // following set of characters  :  -  _  ~  .  +

    for (i = 0; i < str.length; i++) {
        c = [str characterAtIndex:i];
        if ([wsSet characterIsMember:c])
            c = '-';
        else if (isalpha(c))
            c = tolower(c);
        else
            continue;
        [ident appendFormat:@"%c", c];
    }
    return ident;
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

- (NSString *)parseAttributes:(NSArray *)attrs
{
    NSMutableString *ret;
    NSString *attrStr, *attr;
    NSArray *attrComponents;
    BOOL open = NO;

    ret = NSMutableString.string;
    for (attrStr in attrs) {
        attrComponents = [attrStr componentsSeparatedByCharactersInSet:
            NSCharacterSet.whitespaceCharacterSet];
        for (attr in attrComponents) {
            if ([attr hasPrefix:@":"]) {
                [ret appendFormat:@"%@ %@=\"",
                    open ? @"\"" : @"",
                    [attr substringFromIndex:1]
                ];
                open = YES;
            } else
                [ret appendFormat:@" %@", attr];
        }
        if (open)
            [ret appendString:@"\" "];
        open = NO;
    }

    return ret;
}

- (NSString *)HTML
{
    return (NSString *)_html;
}

@end

@implementation HOMarkdownSource
@end
