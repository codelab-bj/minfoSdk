#import <Foundation/Foundation.h>

@interface SCSManagerWrapper : NSObject

+ (nonnull instancetype)shared;
- (void)prepareWithSettings;
- (void)startSearching;
- (void)stopSearching;

@end