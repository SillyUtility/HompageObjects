//
//  HOConfig.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/2/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOConfig.h"

@implementation HOConfig

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
@end
