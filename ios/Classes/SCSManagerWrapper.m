#import "SCSManagerWrapper.h"
#import "ResourceManager.h"
#import "../Frameworks/SCSManager.h"

@interface SCSManagerWrapper ()
@property (nonatomic, strong) SCSManager *manager;
@property (nonatomic, assign) BOOL isInitialized;
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [[SCSManager alloc] init];
        _isInitialized = NO;
        [self setupNotifications];
        [self initializeResources];
    }
    return self;
}

- (void)initializeResources {
    NSError *error = nil;
    if ([ResourceManager initializeCifrasoftPaths:&error]) {
        NSLog(@"[SCSManagerWrapper] ✅ Ressources initialisées");
        _isInitialized = YES;
    } else {
        NSLog(@"[SCSManagerWrapper] ❌ Erreur initialisation ressources: %@", error.localizedDescription);
        _isInitialized = NO;
    }
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDetectionResult:)
                                                 name:@"scsSearchManagerNotification"
                                               object:nil];
}

- (void)handleDetectionResult:(NSNotification *)notification {
    if (!notification.userInfo) return;

    // Ignorer les changements d'état technique
    if (notification.userInfo[@"scsSearchManagerNotificationStateChangeKey"]) return;

    NSNumber *resultStatus = notification.userInfo[@"scsSearchManagerNotificationResultKey"];

    if (resultStatus && resultStatus.intValue == 1) {
        NSNumber *band = notification.userInfo[@"scsSearchManagerNotificationBandKey"] ?: @0;
        NSNumber *offset = notification.userInfo[@"scsSearchManagerNotificationOffsetKey"] ?: @0;

        // Résolution logic: Calcul de l'ID selon le protocole Minfo
        NSInteger audioId = (band.integerValue * 1000) + offset.integerValue;
        long long timestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000);

        // Format identique à Android: [type, id, counter, timestamp]
        // 0 = SoundCode (Sons audibles)
        NSArray *detectedData = @[@0, @(audioId), @1, @(timestamp)];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MinfoDetectionForFlutter"
                                                            object:nil
                                                          userInfo:@{@"detectedData": detectedData}];
    }
}

- (void)prepareWithSettings {
    // Aligné sur les constantes Android (Activation/Decoding)
    scsSettingsStruct settings = {
            .userSearchInterval = 1.0f,
            .userLengthCounter = 1,
            .userPeriodIncrementCounter = 1,
            .userOffsetCounterAdjustment = 0,
            .userOffsetDelayAdjustment = 0.6f  // Calibrage identique à Android
    };

    [self.manager settingsSearching:&settings :&settings];
    NSLog(@"[SCSManagerWrapper] ✅ Moteur configuré");
}

- (void)startSearching {
    if (self.manager) {
        [self.manager startSearching];
        NSLog(@"[SCSManagerWrapper] 🚀 Décodage en cours...");
    }
}

- (void)stopSearching {
    [self.manager stopSearching];
    NSLog(@"[SCSManagerWrapper] Stop");
}

@end