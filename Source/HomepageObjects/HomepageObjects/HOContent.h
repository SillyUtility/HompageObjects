//
//  HOContent.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HOSite;

@interface HOContent : NSObject

- initWithSite:(HOSite *)site
    path:(NSString *)path
    subdirectory:(NSString *)subdir
    fileAttributes:(NSDictionary *)fileAttrs;

@property (readonly, weak) HOSite *site;

@property (readonly) NSString *path;
@property (readonly) NSString *subdirectory;
@property (readonly) NSString *name;
@property (readonly) NSString *title;

@property (readonly) NSDate *creationDate;
@property (readonly) NSDate *modificationDate;

@property (readonly) NSString *layout;

@property (readonly) NSString *destPath;

@property (readonly) BOOL isItem;
@property (readonly) BOOL isCollection;

@end

@interface HOContentItem : HOContent

@property (readonly) NSString *content;

@end

@interface HOContentCollection : HOContent

@property (readonly) NSArray *items;

@end

NS_ASSUME_NONNULL_END
