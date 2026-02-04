#import <Foundation/Foundation.h>
#import "SCSSettings.h"

@interface SCSManager : NSObject

+(SCSManager*) sharedManager;

-(void) startSearching;
-(void) singleSearching;
-(void) pauseSearching;
-(void) stopSearching;
-(void) resetSearching;
-(void) settingsSearching:(scsSettingsStruct*) scsSettingsLO :(scsSettingsStruct*) scsSettingsHI;
-(NSString*) getVersionName;

@end

