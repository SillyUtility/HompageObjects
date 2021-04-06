//
//  HOOrgParser.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/31/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOOrgParser.h"
#import "HOUtils.h"

@implementation HOOrgParser {
    id _document;
}

- initWithJSONAtPath:(NSString *)path
{
    NSError *err;
    NSData *documentData;

    if (!(self = [super init]))
        return self;

    documentData = [NSData
        dataWithContentsOfFile:path
        options:0
        error:&err
    ];
    _document = [NSJSONSerialization
        JSONObjectWithData:documentData
        options:NSJSONReadingFragmentsAllowed
        error:&err
    ];

    return self;
}

- (BOOL)parse
{
    if (![_document isKindOfClass:NSDictionary.class])
        return NO;

    if ([_document[@"$$data_type"] isEqualToString:@"org-document"]) {
        [self.delegate parserDidStartDocument:self];
        if (![self parseDocument:_document])
            return NO;
        [self.delegate parserDidEndDocument:self];
        return YES;
    }

    return NO;
}

/*
{
  "$$data_type": "org-document",
  "title": [
    "Home"
  ],
  "file_tags": {
  },
  "author": [
    "Eddie Hillenbrand"
  ],
  "creator": "Emacs 27.1 (Org mode 9.3)",
  "date": [
    "2021-03-05"
  ],
  "description": [],
  "email": "eddie@Graphdyne-MacBookPro0.local",
  "language": "en",

  ...

}
*/
- (BOOL)parseDocument:(NSDictionary *)doc
{
    NSArray *nodes;
    NSMutableDictionary *properties;

    properties = NSMutableDictionary.dictionary;

    // for each key that is not $$data_type or contents
    for (NSString *key in doc) {
        if ([key isEqualToString:@"$$data_type"])
            continue;
        if ([key isEqualToString:@"contents"])
            continue;
        properties[key] = [doc[key] copy];
    }

    [self.delegate parser:self parseDocumentProperties:properties];

    nodes = doc[@"contents"];
    if (!nodes)
        return YES;

    return [self parseNodes:nodes];
}

- (BOOL)parseNodes:(NSArray *)nodes
{
    for (NSDictionary *node in nodes)
        if (![self parseNode:node])
            return NO;
    return YES;
}

- (BOOL)parseNode:(id)node
{
    if ([node isKindOfClass:NSString.class]) {
        [self.delegate parser:self parseString:(NSString *)node];
        return YES;
    }
    if ([node isKindOfClass:NSDictionary.class])
        return [self parseDictionaryNode:(NSDictionary *)node];
    return NO;
}

- (BOOL)parseDictionaryNode:(NSDictionary *)node
{
    NSString *ref, *type;
    NSMutableDictionary *properties;
    BOOL space;

    ref = [node[@"ref"] copy];
    type = [node[@"type"] copy];
    properties = NSMutableDictionary.dictionary;

    for (NSString *key in node[@"properties"]) {
        if ([key isEqualToString:@"$$data_type"])
            continue;
        properties[key] = [node[@"properties"][key] copy];
    }
    space = [properties[@"post-blank"] boolValue];

    if ([properties[@"type"] isEqualToString:@"ordered"])
        type = @"ordered-list";
    if ([properties[@"type"] isEqualToString:@"unordered"])
        type = @"unordered-list";
    if ([properties[@"type"] isEqualToString:@"descriptive"])
        type = @"description-list";
    if ([type isEqualToString:@"item"])
        if ([properties[@"tag"] count] > 0)
            type = @"description-term";

    if ([type isEqualToString:@"headline"])
        if ([properties[@"footnote-section-p"] boolValue])
            type = @"footnote-headline";

    // type `paragraph' prop `name' and `caption'
    // content[0].properties.inline-image
    // => figure figcaption img
    if ([self nodeIsFigure:node])
        type = @"figure";

    [self.delegate parser:self
        didStartNode:type
        reference:ref
        properties:properties
    ];
    if (![self parseNodes:node[@"contents"]])
        return NO;
    [self.delegate parser:self
        didEndNode:type
        trailingSpace:space
    ];

    return YES;
}

- (BOOL)nodeIsFigure:(NSDictionary *)node
{
    if ([node[@"type"] isEqualToString:@"paragraph"]) {
        if ([node[@"contents"] count] > 0)
            if ([node[@"contents"][0] isKindOfClass:NSDictionary.class])
                if ([[node[@"contents"][0] valueForKeyPath:@"properties.is-inline-image"] boolValue])
                    return YES;
    }
    return NO;
}

- (void)abortParsing
{

}

@end
