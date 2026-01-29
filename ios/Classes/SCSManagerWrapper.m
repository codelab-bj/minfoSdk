#import "SCSManagerWrapper.h"
#import "../Frameworks/SCSTB.framework/SCSManager.h"

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
        // Essayer d'abord l'initialisation standard
        SCSManager *manager = [[SCSManager alloc] init];
        [manager startSearching];
        NSLog(@"[SCSManagerWrapper] Démarrage réussi avec init");
    } @catch (NSException *exception) {
        NSLog(@"[SCSManagerWrapper] Erreur avec init: %@", exception.reason);
        // Fallback : essayer shared si init échoue
        @try {
            Class managerClass = NSClassFromString(@"SCSManager");
            if ([managerClass respondsToSelector:@selector(shared)]) {
                SCSManager *manager = [managerClass performSelector:@selector(shared)];
                [manager startSearching];
                NSLog(@"[SCSManagerWrapper] Démarrage réussi avec shared");
            } else {
                NSLog(@"[SCSManagerWrapper] Méthode shared non disponible");
            }
        } @catch (NSException *innerException) {
            NSLog(@"[SCSManagerWrapper] Erreur finale: %@", innerException.reason);
        }
    }
}

- (void)stopSearching {
    NSLog(@"[SCSManagerWrapper] Tentative d'arrêt...");
    @try {
        SCSManager *manager = [[SCSManager alloc] init];
        [manager stopSearching];
        NSLog(@"[SCSManagerWrapper] Arrêt réussi");
    } @catch (NSException *exception) {
        NSLog(@"[SCSManagerWrapper] Erreur: %@", exception.reason);
    }
}

@end
