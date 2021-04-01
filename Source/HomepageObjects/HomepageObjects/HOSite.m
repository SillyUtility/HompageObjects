//
//  HOSite.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

#import "HOSite.h"
#import "HOConfig.h"
#import "HOContent.h"
#import "HOUtils.h"

#import "NSFileManager+HOAdditons.h"

@implementation HOSite {
    JSContext *_ctx;
}

- initWithConfig:(HOConfig *)config
{
    if (!(self = [super init]))
        return self;

    _config = config;

    return self;
}

+ (instancetype)newSiteWithTitle:(NSString *)title
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

    [self initializeSiteDirectory:dir withTemplate:@"DefaultSite"];

    return nil;
}

+ (NSString *)siteTemplatePathForTemplateName:(NSString *)templateName
{
    NSString *realativeResourcePath;
    NSBundle *bundle;

    realativeResourcePath = [NSString stringWithFormat:@"Templates/%@",
        templateName];
    bundle = [NSBundle bundleForClass:self];

    return [bundle pathForResource:realativeResourcePath ofType:@""];
}

+ (NSString *)scriptPathForScriptName:(NSString *)scriptName
{
    NSString *realativeResourcePath;
    NSBundle *bundle;

    realativeResourcePath = [NSString stringWithFormat:@"Scripts/%@",
        scriptName];
    bundle = [NSBundle bundleForClass:self];

    return [bundle pathForResource:realativeResourcePath ofType:@"js"];
}

+ (void)initializeSiteDirectory:(NSString *)siteDirectory
    withTemplate:(NSString *)template
{
    NSString *templatePath;

    fprintf(stderr, "Initializing %s\n", siteDirectory.UTF8String);
    templatePath = [self siteTemplatePathForTemplateName:template];
    [self copyConentsAtPath:templatePath toPath:siteDirectory];
}

+ (void)copyConentsAtPath:(NSString *)srcPath toPath:(NSString *)destPath
{
    NSFileManager *fm;
    NSDirectoryEnumerator *enumerator;
    NSString *path, *newDir,
        *fullSrcPath, *fullDestPath;
    BOOL isDir;
    NSError *err;

    fm = NSFileManager.defaultManager;
    enumerator = [fm enumeratorAtPath:srcPath];

    while ((path = enumerator.nextObject)) {
        fullSrcPath = [srcPath stringByAppendingPathComponent:path];

        if (![fm fileExistsAtPath:fullSrcPath isDirectory:&isDir])
            continue;

        if (isDir) {
            log_indent(enumerator.level, "mkdir %s\n", path.UTF8String);
            newDir = [destPath stringByAppendingPathComponent:path];
            // TODO: allow directory renames
            [fm createDirectoryAtPath:newDir
                withIntermediateDirectories:YES
                attributes:nil
                error:&err
            ];
            if (err) {
                fprintf(stderr, "failed to create %s\n", newDir.UTF8String);
                return;
            }
            continue;
        }

        log_indent(enumerator.level, "cp %s\n", path.UTF8String);
        fullDestPath = [destPath stringByAppendingPathComponent:path];
        // TODO: process files (something like replace $$VAR_NAME$$)
        [fm copyItemAtPath:fullSrcPath toPath:fullDestPath error:&err];
        if (err) {
            fprintf(stderr, "failed to copy %s\n", path.UTF8String);
            return;
        }
    }
}

+ (instancetype)siteAtPath:(NSString *)path error:(NSError * _Nullable *)error
{
    NSFileManager *fm;
    BOOL isDir;
    NSString *configPath;
    HOConfig *config;

    fprintf(stderr, "siteRoot is %s\n", path.UTF8String);

    fm = NSFileManager.defaultManager;

    if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
        if (!isDir) {
            fprintf(stderr, "%s is a file\n", path.UTF8String);
            return nil;
        }
    } else {
        fprintf(stderr, "%s does not exist\n", path.UTF8String);
        return nil;
    }

    configPath = [path stringByAppendingPathComponent:@"Config.plist"];
    config = [HOConfig configAtPath:configPath];

    return [[HOSite alloc] initWithConfig:config];
}

- (void)buildAndReturnError:(NSError * _Nullable *)error
{
    NSString *contentRoot;

    contentRoot = self.config.contentRoot;

    fprintf(stderr, "Build with config %s\n",
        self.config.dictionary.description.UTF8String);
    fprintf(stderr, "Processing content in %s\n", contentRoot.UTF8String);

    // create JSContext
    if (!_ctx)
        _ctx = JSContext.new;

    // load default scripts
    NSString *scriptPath;
    NSString *scriptSrc;
    scriptPath = [self.class scriptPathForScriptName:@"Template"];
    scriptSrc = [NSString stringWithContentsOfFile:scriptPath
        encoding:NSUTF8StringEncoding
        error:NULL
    ];
    [self loadScript:scriptSrc withName:@"Template"];

    scriptPath = [self.class scriptPathForScriptName:@"Build"];
    scriptSrc = [NSString stringWithContentsOfFile:scriptPath
        encoding:NSUTF8StringEncoding
        error:NULL
    ];
    [self loadScript:scriptSrc withName:@"Build"];

    // load layouts, templates, partials and so on

    // load custom scripts
#if 0
    if (self.config.hasCustomScript) {
        NSString *customScriptPath;
        NSString *customScriptSrc;
        NSURL *customScriptURL;
        [_ctx evaluateScript:customScriptSrc withSourceURL:customScriptURL];
    }
#endif

    [self buildContentDirectory:contentRoot];
}

- (void)loadScript:(NSString *)script withName:(NSString *)name
{
    NSString *urlStr;
    NSURL *scriptURL;

    urlStr = [NSString stringWithFormat:@"ho-builtin://%@.js", name];
    scriptURL = [NSURL URLWithString:urlStr];
    [_ctx evaluateScript:script withSourceURL:scriptURL];
}

- (void)buildContentDirectory:(NSString *)contentDir
{
    NSFileManager *fm;
    NSDirectoryEnumerator *enumerator;
    NSString *path;
    NSString *subdir;
    NSString *fullSrcPath;
    HOContentItem *item;
    HOContentCollection *collection;
    BOOL isDir;

    fm = NSFileManager.defaultManager;
    enumerator = [fm enumeratorAtPath:contentDir];

    while ((path = enumerator.nextObject)) {
        subdir = [path stringByDeletingLastPathComponent];
        fullSrcPath = [contentDir stringByAppendingPathComponent:path];

        if (![fm fileExistsAtPath:fullSrcPath isDirectory:&isDir])
            continue;

        if (isDir) {
            log_indent(enumerator.level, "collection %s ‣ ", path.UTF8String);
            collection = [[HOContentCollection alloc]
                initWithSite:self
                path:fullSrcPath
                subdirectory:subdir
                fileAttributes:enumerator.fileAttributes
            ];
            fprintf(stderr, "%s\n", collection.destPath.UTF8String);
            [collection createDirectoryIfNeeded];
            continue;
        }

        if (![path.pathExtension isEqualToString:@"org"]) {
            log_indent(enumerator.level, "skip %s\n", path.UTF8String);
            continue;
        }

        log_indent(enumerator.level, "item %s ‣ ", path.UTF8String);
        item = [[HOContentItem alloc]
            initWithSite:self
            path:fullSrcPath
            subdirectory:subdir
            fileAttributes:enumerator.fileAttributes
        ];
        fprintf(stderr, "%s\n", item.destPath.UTF8String);

        [self buildItem:item withContext:_ctx];
        [item writeToDestination];
    }
}

- (void)buildItem:(HOContentItem *)item withContext:(JSContext *)ctx
{
    JSValue *buildItemFn = ctx[@"buildItem"];
    [buildItemFn callWithArguments:@[item]];
}

@end
