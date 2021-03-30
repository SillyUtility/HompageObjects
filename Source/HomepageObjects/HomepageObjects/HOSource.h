//
//  HOSource.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HOConfig;

@interface HOSource : NSObject
- initWithPath:(NSString *)path config:(HOConfig *)config;

@property NSString *path;
@property HOConfig *config;

@property NSDictionary *properties;
@property NSString *HTML;

- (void)convert;

@end

/*
 * Takes a .org file, runs it through emacs, loads the .json dump,
 * then compiles it to HTML.
 */
@interface HOOrgSource : HOSource

@end

@interface HOMarkdownSource : HOSource
@end

NS_ASSUME_NONNULL_END
