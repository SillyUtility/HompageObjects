//
//  HOConfig.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/2/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOConfig.h"

@implementation HOConfig {
    NSMutableDictionary *_config;
}

- initWithPath:(NSString *)path
{
    NSFileManager *fm;
    NSString *siteRoot;

    if (!(self = [super init]))
        return self;

    fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:path]) {
        fprintf(stderr, "Config.plist not found at %s", path.UTF8String);
        return nil;
    }

    _config = [NSMutableDictionary dictionaryWithContentsOfFile:path];

    siteRoot = [path stringByDeletingLastPathComponent];
    siteRoot = [siteRoot stringByAppendingPathComponent:_config[@"siteDirectory"]];
    siteRoot = [siteRoot stringByStandardizingPath];
    _config[@"siteRoot"] = siteRoot;

    return self;
}

+ (instancetype)configAtPath:(NSString *)path
{
    return [[HOConfig alloc] initWithPath:path];
}

+ (NSURL *)URLForDefaultConfigTemplate
{
    NSBundle *bundle;
    bundle = [NSBundle bundleForClass:self];

#ifdef DEBUG
    NSLog(@"bundle %@", bundle);
    NSLog(@"infoDictionary %@", bundle.infoDictionary);
    NSLog(@"resourceURL %@", bundle.resourceURL);
#endif

    return [bundle URLForResource:@"Config" withExtension:@"plist"];
}

- init
{
    NSURL *configTemplateURL;
    NSDictionary *config;

    if (!(self = [super init]))
        return self;

    configTemplateURL = [self.class URLForDefaultConfigTemplate];
    config = [NSDictionary dictionaryWithContentsOfURL:configTemplateURL];

#ifdef DEBUG
    NSLog(@"configTemplateURL %@", configTemplateURL);
    NSLog(@"config %@", config);
#endif

    return self;
}

- (id)objectForKeyedSubscript:(id<NSCopying>)key
{
    return _config[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    _config[key] = obj;
}

- (NSString *)contentRoot
{
    return [self[@"siteRoot"] stringByAppendingPathComponent:self[@"contentDirectory"]];
}

- (NSString *)buildRoot
{
    return [self[@"siteRoot"] stringByAppendingPathComponent:self[@"buildDirectory"]];
}

- (NSDictionary *)dictionary
{
    return _config.copy;
}

@end
