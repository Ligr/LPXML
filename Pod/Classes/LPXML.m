//
//  LPXML.m
//  LPXML
//
//  Created by Alex on 10/11/15.
//  Copyright © 2015 Home. All rights reserved.
//

#import "LPXML.h"

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface LPXML () {
	xmlDocPtr _doc;
	NSStringEncoding _encoding;
}

@end

@implementation LPXML

- (instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
	self = [super init];
	if (self) {
		_encoding = encoding;
		_doc = xmlReadMemory([data bytes], (int)[data length], "", [[self nameForStringEncoding:_encoding] UTF8String], XML_PARSE_RECOVER);
	}
	return self;
}

- (instancetype)initWithHtmlData:(NSData *)data encoding:(NSStringEncoding)encoding {
	self = [super init];
	if (self) {
		_encoding = encoding;
		_doc = htmlReadMemory([data bytes], (int)[data length], "", [[self nameForStringEncoding:_encoding] UTF8String], HTML_PARSE_NOBLANKS | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING | HTML_PARSE_NONET | HTML_PARSE_NOIMPLIED);
	}
	return self;
}

- (void)dealloc
{
    xmlFreeDoc(_doc);
}

- (instancetype)initWithString:(NSString *)str encoding:(NSStringEncoding)encoding {
	NSData *data = [str dataUsingEncoding:encoding];
	return [self initWithData:data encoding:encoding];
}

- (instancetype)initWithHtmlString:(NSString *)str encoding:(NSStringEncoding)encoding {
	NSData *data = [str dataUsingEncoding:encoding];
	return [self initWithHtmlData:data encoding:encoding];
}

- (NSArray<NSString *> *)contentForXpath:(NSString *)xpath; {
    xmlXPathObjectPtr xpathObject = [self performXpathQuery:xpath doc:_doc];
	xmlNodeSetPtr xpathResult = xpathObject->nodesetval;
    NSMutableArray<NSString *> *results = [NSMutableArray new];
	if (xpathResult) {
		for (NSInteger i = 0; i < xpathResult->nodeNr; i++) {
			xmlNodePtr xmlNode = xpathResult->nodeTab[i];
			xmlBufferPtr buff = xmlBufferCreate();
			int level = 0;
			int format = 0;
			int result = xmlNodeDump(buff, _doc, xmlNode, level, format);
			NSString *xmlNodeStr = nil;
			if (result > -1) {
				xmlNodeStr = [[NSString alloc] initWithBytes:(xmlBufferContent(buff)) length:(NSUInteger)(xmlBufferLength(buff)) encoding:NSUTF8StringEncoding];
				NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
				xmlNodeStr = [xmlNodeStr stringByTrimmingCharactersInSet:ws];
			}
			xmlBufferFree(buff);
			if (xmlNodeStr) {
                [results addObject:xmlNodeStr];
			}
		}
	}
    xmlXPathFreeObject(xpathObject);
	return results;
}

#pragma mark - Private

- (NSString *)nameForStringEncoding:(NSStringEncoding)encoding {
	if (encoding == NSUTF8StringEncoding) {
		return @"utf-8";
	} else if (encoding == NSWindowsCP1251StringEncoding) {
		return @"windows-1251";
	} else {
		NSLog(@"[LPXML][ERROR]: unsupported encoding '%@', using UNF-8", @(encoding));
		return @"utf-8";
	}
}

- (NSString *)contentFromDictionary:(NSDictionary *)dict {
	NSMutableString *content = [dict[@"nodeContent"] mutableCopy] ? : [NSMutableString new];
	NSArray *childNodes = dict[@"nodeChildArray"];
	if (childNodes && childNodes.count > 0) {
		for (NSInteger i = 0; i < childNodes.count; i++) {
			NSDictionary *childNode = childNodes[i];
			[content appendString:[self contentFromDictionary:childNode]];
		}
	}
	return content;
}

- (xmlXPathObjectPtr)performXpathQuery:(NSString *)query doc:(xmlDocPtr)doc {
	xmlXPathContextPtr xpathCtx;
	xmlXPathObjectPtr xpathObj;
 
	/* Create XPath evaluation context */
	xpathCtx = xmlXPathNewContext(doc);
	if(xpathCtx == NULL) {
		NSLog(@"Unable to create XPath context.");
		return nil;
	}
	
	/* Evaluate XPath expression */
	xmlChar *queryString = (xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding];
	xpathObj = xmlXPathEvalExpression(queryString, xpathCtx);

    xmlXPathFreeContext(xpathCtx);
	return xpathObj;
}

@end
