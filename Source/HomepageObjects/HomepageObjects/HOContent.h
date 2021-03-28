//
//  HOContent.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

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

@protocol HOContentItemExports <JSExport>
@property (readonly) NSString *source;
@property (readonly) NSArray<NSString *> *layouts;
@property (readonly) NSDictionary *args;
@property NSString *rendered;
@end

@interface HOContentItem : HOContent <HOContentItemExports>

@property (readonly) NSString *content;

@property (readonly) NSString *source;
@property (readonly) NSArray<NSString *> *layouts;
@property (readonly) NSDictionary *args;
@property NSString *rendered;

- (void)writeToDestination;

@end

@interface HOContentCollection : HOContent

@property (readonly) NSArray *items;

- (void)createDirectoryIfNeeded;

@end

NS_ASSUME_NONNULL_END
