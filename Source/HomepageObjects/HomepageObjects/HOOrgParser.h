//
//  HOOrgParser.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/31/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HOOrgParserDelegate;

/*
 * The Emacs Org-mode parser.
 */
@interface HOOrgParser : NSObject

- initWithJSONAtPath:(NSString *)path;

@property (nullable, assign) id <HOOrgParserDelegate> delegate;

- (BOOL)parse;
- (void)abortParsing;

@property (nullable, readonly, copy) NSError *parserError;

@end


/*
 * The methods a delegate may implement to respond to Org-mode parse
 * events.
 */
@protocol HOOrgParserDelegate <NSObject>
@optional

- (void)parserDidStartDocument:(HOOrgParser *)parser;
- (void)parserDidEndDocument:(HOOrgParser *)parser;

- (void)parser:(HOOrgParser *)parser
    parseDocumentProperties:(NSDictionary<NSString *, id> *)properties;

- (void)parser:(HOOrgParser *)parser didStartNode:(NSString *)nodeType
    reference:(NSString *)ref
    properties:(NSDictionary<NSString *, id> *)properties;
- (void)parser:(HOOrgParser *)parser didEndNode:(NSString *)nodeType;

- (void)parser:(HOOrgParser *)parser parseString:(NSString *)str;

- (void)parser:(HOOrgParser *)parser parseError:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
