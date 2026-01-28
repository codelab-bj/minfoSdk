#import <Foundation/Foundation.h>

@interface SCSManagerWrapper : NSObject

+ (instancetype)shared;
- (void)startSearching;
- (void)stopSearching;

@end
