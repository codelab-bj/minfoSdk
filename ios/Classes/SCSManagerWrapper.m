#import "SCSManagerWrapper.h"
#import "../Frameworks/SCSTB.framework/SCSManager.h"
#import "../Frameworks/SCSTB.framework/SCSSettings.h"

@implementation SCSManagerWrapper {
    SCSManager *_manager;
    BOOL _configured;
}

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
        _manager = nil;
        _configured = NO;
    }
    return self;
}

- (void)ensureConfigured {
    NSLog(@"[SCSManagerWrapper] ✅ EXECUTION NOTRE CODE: ensureConfigured");
    if (_configured && _manager != nil) return;

    // Même configuration que l'app principale (AppDelegate.swift)
    scsSettingsStruct scsSettingsLO;
    scsSettingsLO.userSearchInterval = SCS_SEARCH_INTERVAL_DEFAULT;
    scsSettingsLO.userLengthCounter = SCS_COUNTER_LENGTH_LO;
    scsSettingsLO.userPeriodIncrementCounter = SCS_COUNTER_INCREMENT_LO;
    scsSettingsLO.userOffsetCounterAdjustment = SCS_COUNTER_OFFSET_VALUE_LO;
    scsSettingsLO.userOffsetDelayAdjustment = SCS_DELAY_OFFSET_ADJUSTMENT_LO;

    scsSettingsStruct scsSettingsHI;
    scsSettingsHI.userSearchInterval = SCS_SEARCH_INTERVAL_DEFAULT;
    scsSettingsHI.userLengthCounter = SCS_COUNTER_LENGTH_HI;
    scsSettingsHI.userPeriodIncrementCounter = SCS_COUNTER_INCREMENT_HI;
    scsSettingsHI.userOffsetCounterAdjustment = SCS_COUNTER_OFFSET_VALUE_HI;
    scsSettingsHI.userOffsetDelayAdjustment = SCS_DELAY_OFFSET_ADJUSTMENT_HI;

    _manager = [[SCSManager alloc] init];
    [_manager settingsSearching:&scsSettingsLO :&scsSettingsHI];
    _configured = YES;
    NSLog(@"[SCSManagerWrapper] SCSManager configuré (même settings que l'app principale)");
}

- (void)startSearching {
    NSLog(@"[SCSManagerWrapper] ✅ EXECUTION NOTRE CODE: startSearching");
    [self ensureConfigured];
    [_manager startSearching];
    NSLog(@"[SCSManagerWrapper] start recording ...");
}

- (void)stopSearching {
    NSLog(@"[SCSManagerWrapper] stopSearching");
    if (_manager != nil) {
        [_manager stopSearching];
        NSLog(@"[SCSManagerWrapper] stopped recording");
    }
}

@end