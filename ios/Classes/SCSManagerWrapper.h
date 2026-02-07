#import <Foundation/Foundation.h>

@interface SCSManagerWrapper : NSObject

+ (instancetype)shared;
- (void)ensureConfigured;
- (void)startSearching;
- (void)stopSearching;

@end
