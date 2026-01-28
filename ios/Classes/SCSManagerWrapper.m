#import "SCSManagerWrapper.h"

// Forward declaration pour éviter les imports
@interface SCSManager : NSObject
+ (SCSManager*)sharedManager;
- (void)startSearching;
- (void)stopSearching;
@end

@implementation SCSManagerWrapper

+ (instancetype)shared {
    static SCSManagerWrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCSManagerWrapper alloc] init];
    });
    return sharedInstance;
}

- (void)startSearching {
    NSLog(@"[SCSManagerWrapper] Tentative de démarrage...");
    @try {
        SCSManager *manager = [SCSManager sharedManager];
        [manager startSearching];
        NSLog(@"[SCSManagerWrapper] Démarrage réussi");
    } @catch (NSException *exception) {
        NSLog(@"[SCSManagerWrapper] Erreur: %@", exception.reason);
    }
}

- (void)stopSearching {
    NSLog(@"[SCSManagerWrapper] Tentative d'arrêt...");
    @try {
        SCSManager *manager = [SCSManager sharedManager];
        [manager stopSearching];
        NSLog(@"[SCSManagerWrapper] Arrêt réussi");
    } @catch (NSException *exception) {
        NSLog(@"[SCSManagerWrapper] Erreur: %@", exception.reason);
    }
}

@end
