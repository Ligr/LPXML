//
//  LPXML.h
//  LPXML
//
//  Created by Alex on 10/11/15.
//  Copyright © 2015 Home. All rights reserved.
//

@import Foundation;

@interface LPXML : NSObject

- (instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
- (instancetype)initWithHtmlData:(NSData *)data encoding:(NSStringEncoding)encoding;
- (instancetype)initWithString:(NSString *)str encoding:(NSStringEncoding)encoding;
- (instancetype)initWithHtmlString:(NSString *)str encoding:(NSStringEncoding)encoding;

- (NSArray<NSString *> *)contentForXpath:(NSString *)xpath;

@end
