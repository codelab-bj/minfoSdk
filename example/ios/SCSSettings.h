#import     <UIKit/UIKit.h>

#define SCS_MANAGER_NOTIFICATION                            @"scsManagerNotification"
#define SCS_MANAGER_NOTIFICATION_STATE_KEY                  @"scsManagerNotificationStateKey"

#define SCS_AUDIO_MANAGER_NOTIFICATION						@"scsAudioManagerNotification"
#define SCS_AUDIO_MANAGER_NOTIFICATION_ERROR_KEY			@"scsAudioManagerNotificationErrorKey"
#define SCS_AUDIO_MANAGER_NOTIFICATION_STATE_CHANGE_KEY		@"scsAudioManagerNotificationStateChangeKey"

#define SCS_SEARCH_MANAGER_NOTIFICATION						@"scsSearchManagerNotification"
#define SCS_SEARCH_MANAGER_NOTIFICATION_ERROR_KEY			@"scsSearchManagerNotificationErrorKey"
#define SCS_SEARCH_MANAGER_NOTIFICATION_BAND_KEY			@"scsSearchManagerNotificationBandKey"
#define SCS_SEARCH_MANAGER_NOTIFICATION_RESULT_KEY			@"scsSearchManagerNotificationResultKey"
#define SCS_SEARCH_MANAGER_NOTIFICATION_OFFSET_KEY			@"scsSearchManagerNotificationOffsetKey"
#define SCS_SEARCH_MANAGER_NOTIFICATION_STATE_CHANGE_KEY	@"scsSearchManagerNotificationStateChangeKey"

#define SCS_SEARCH_INTERVAL_DEFAULT                         1.0f
#define SCS_COUNTER_LENGTH_LO                               1
#define SCS_COUNTER_INCREMENT_LO                            1
#define SCS_COUNTER_OFFSET_VALUE_LO                         0
#define SCS_DELAY_OFFSET_ADJUSTMENT_LO                      +0.0f
#define SCS_COUNTER_LENGTH_HI                               1
#define SCS_COUNTER_INCREMENT_HI                            1
#define SCS_COUNTER_OFFSET_VALUE_HI                         0
#define SCS_DELAY_OFFSET_ADJUSTMENT_HI                      +0.0f

typedef struct scsSettingsStruct {
    float                           userSearchInterval;
    int                             userLengthCounter;
    int                             userPeriodIncrementCounter;
    int                             userOffsetCounterAdjustment;
    float                           userOffsetDelayAdjustment;
} scsSettingsStruct;


typedef enum SCSManagerState: NSUInteger {
    SCSManagerEventErrorLocalSearchFileServiceUnavailable,
    SCSManagerEventUpdateLocalSearchFile,
    SCSManagerEventNoUpdateLocalSearchFile,
    SCSManagerEventCheckLocalSearchFileHash
} SCSManagerState;

typedef enum SCSAudioManagerState: NSUInteger {
	SCSAudioManagerStateUninitialized,
    SCSAudioManagerStateRecording,
    SCSAudioManagerStatePaused,
    SCSAudioManagerStateStopped,
    SCSAudioManagerStateError,
    SCSAudioManagerStatePermDenied
} SCSAudioManagerState;

typedef enum SCSSearchManagerState: NSUInteger {
	SCSSearchManagerStateUninitialized,
    SCSSearchManagerStateSearching,
    SCSSearchManagerStateSingleSearching,
    SCSSearchManagerStatePaused,
    SCSSearchManagerStateStopped
} SCSSearchManagerState;

typedef enum SCSSearchManagerResult: int64_t {
    SCSSearchManagerResultNotFound,
    SCSSearchManagerResultFound,
} SCSSearchManagerResult;

typedef enum SCSSearchManagerError: NSUInteger {
    SCSSearchManagerErrorInitialization,
} SCSSearchManagerError;
