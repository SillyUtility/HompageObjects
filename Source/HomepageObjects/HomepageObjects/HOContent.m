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

@end

@implementation HOContentCollection

- (BOOL)isCollection
{
    return YES;
}

@end
