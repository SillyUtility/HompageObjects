//
//  HOContent.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOContent.h"
#import "HOSite.h"
#import "HOConfig.h"

@interface HOContent ()
@property NSArray<NSString *> *layoutOrder;
@end

@implementation HOContent {
    NSMutableArray *_layoutOrder;
    NSDictionary<NSFileAttributeKey, id> *_fileAttributes;
}

- initWithSite:(HOSite *)site
    path:(NSString *)path
    subdirectory:(NSString *)subdir
    fileAttributes:(NSDictionary *)fileAttrs
{
    if (!(self = [super init]))
        return self;

    _site = site;

    _path = path;
    _subdirectory = subdir;
    _fileAttributes = fileAttrs;

    _name = path.lastPathComponent.stringByDeletingPathExtension;
    _title = path.lastPathComponent.stringByDeletingPathExtension;

    _creationDate = _fileAttributes[NSFileCreationDate];
    _modificationDate = _fileAttributes[NSFileModificationDate];

    _layout = path.lastPathComponent.stringByDeletingPathExtension;

    _layoutOrder = NSMutableArray.array;
    [_layoutOrder addObject:@"base"]; // if exists
    [_layoutOrder addObject:_layout]; // if exists, or default

    _destPath = [NSString pathWithComponents:@[
        _site.config.buildRoot,
        _subdirectory,
        _name
    ]];

    return self;
}

- (BOOL)isItem
{
    return NO;
}

- (BOOL)isCollection
{
    return NO;
}

@end

@implementation HOContentItem

- (BOOL)isItem
{
    return YES;
}

- (NSString *)destPath
{
    if ([self.name isEqualToString:@"index"])
        return [super.destPath stringByAppendingPathExtension:@"html"];
    else
        return [super.destPath stringByAppendingPathComponent:@"index.html"];
}

/* JSExport */
- (NSString *)source
{
    NSString *src;
    NSError *err;

    src = [NSString stringWithContentsOfFile:self.path
        encoding:NSUTF8StringEncoding
        error:&err
    ];
    if (err)
        fprintf(stderr, "source err %s %s\n",
            self.path.UTF8String,
            err.localizedDescription.UTF8String);

    // TODO: convert .org to HTML
    // TODO: convert .md to HTML

    return src;
}

- (NSArray<NSString *> *)layouts
{
    NSMutableArray *layoutSources;
    NSFileManager *fm;
    NSString *layoutPath;
    NSString *src;
    NSError *err;

    layoutSources = NSMutableArray.array;
    fm = NSFileManager.defaultManager;

    for (NSString *layout in self.layoutOrder) {
        layoutPath = self.site.config.layoutRoot;
        layoutPath = [layoutPath stringByAppendingPathComponent:
            [layout stringByAppendingPathExtension:@"html"]];
        if (![fm fileExistsAtPath:layoutPath])
            continue;
        src = [NSString stringWithContentsOfFile:layoutPath
            encoding:NSUTF8StringEncoding
            error:&err
        ];
        if (err)
            fprintf(stderr, "layout err %s %s\n",
                layoutPath.UTF8String,
                err.localizedDescription.UTF8String);
        [layoutSources addObject:src];
    }

    return layoutSources;
}

- (NSDictionary *)args
{
    return @{
        //@"Config": self.site.config.dictionary,
        @"Site": @{
            @"title": self.site.config[@"title"],
        },
        @"Page": @{
            @"path": self.path,
            @"name": self.name,
            @"title": self.title,
        }
    };
}

- (void)writeToDestination
{
    NSError *err;
    NSFileManager *fm;
    NSString *dir;

    fm = NSFileManager.defaultManager;
    dir = self.destPath.stringByDeletingLastPathComponent;
    [fm createDirectoryAtPath:dir
        withIntermediateDirectories:YES
        attributes:nil
        error:&err
    ];
    if (err)
        fprintf(stderr, "dest dir error %s %s\n",
            dir.UTF8String,
            err.localizedDescription.UTF8String);

    [self.rendered writeToFile:self.destPath
        atomically:YES
        encoding:NSUTF8StringEncoding
        error:&err
    ];
    if (err)
        fprintf(stderr, "write err %s %s\n",
            self.destPath.UTF8String,
            err.localizedDescription.UTF8String);
}

@end

@implementation HOContentCollection

- (BOOL)isCollection
{
    return YES;
}

- (void)createDirectoryIfNeeded
{
    NSFileManager *fm;
    NSError *err;
    fm = NSFileManager.defaultManager;
    [fm createDirectoryAtPath:self.destPath
        withIntermediateDirectories:YES
        attributes:nil
        error:&err
    ];
    if (err)
        fprintf(stderr, "dir error %s %s\n",
            self.destPath.UTF8String,
            err.localizedDescription.UTF8String);
}

@end
