//
//  AMZRecorder.m
//  AMZRecorder
//
//  Created by Admin on 1/13/17.
//  Copyright © 2017 Admin. All rights reserved.
//

#import "AMZRecorder.h"
#import <UIKit/UIKit.h>

@implementation AMZRecorder

-(void) disableIdleTimer:(BOOL)flag {
    [UIApplication sharedApplication].idleTimerDisabled = flag;
}

/*
 Initialize the Audio Recorder
 */
- (id) initAudioRecorder {
    self = [self init];
    
    // Clear the previously saved audio files in the custom directory
    [self ClearCache];
    
    // Initializ the playing session
    [self initPlayerSession];
    
    // Name the file with a unique UUID String
    FileName=[[NSUUID UUID] UUIDString];
    
    // Set the initial flag of the temporary recorder as paused to be able to know if the original recorder is recording or the temporary recorder is recording.
    isTempRecordingPaused = YES;
    
    // Create the Path and FileName where the original recorder will start recording
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [cacheDir stringByAppendingPathComponent:@"/AudioFiles"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    {
        NSError *error=nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSString *path = [NSString stringWithFormat:@"%@.m4a",FileName];
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               dataPath,
                               path,
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithFloat:16000.0], AVSampleRateKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    nil];
    
    
    NSError *error = nil;
    
    recorder = [[AVAudioRecorder alloc]
                initWithURL:outputFileURL
                settings:recordSettings
                error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [recorder prepareToRecord];
    }
    
    // Initialize the temporary recorder file settings to be later saved with a unique name of the current timestamp.
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"ddMMyyyyHHmmss"];
    
    NSDate *now = [[NSDate alloc] init];
    NSString *dateString = [format stringFromDate:now];
    NSString *tempPath = [NSString stringWithFormat:@"%@.m4a",dateString];
    
    NSArray *tempPathComponents = [NSArray arrayWithObjects:
                                   dataPath,
                                   tempPath,
                                   nil];
    NSURL *tempOutputFileURL = [NSURL fileURLWithPathComponents:tempPathComponents];
    
    
    tempRecorder = [[AVAudioRecorder alloc] initWithURL:tempOutputFileURL settings:recordSettings error:NULL];
    tempRecorder.delegate = self;
    tempRecorder.meteringEnabled = YES;
    [tempRecorder prepareToRecord];
    
    return self;
}

// Initializing the playing session
- (void) initPlayerSession {
    playingSession = [AVAudioSession sharedInstance];
    [playingSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [playingSession setActive: YES error:nil];
    [playingSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
}

// Calculate the remaining time before the recorder reaches its limits.
- (int) remainingTimeForRecord {
    int maxLimit = maxRecordTime;
    
    return maxLimit - (int)(ceil(totalRecordTime));
}

// Set the maximum recording time using the property
- (void)setMaxRecordingTime:(int)maxTime
{
    maxRecordTime = maxTime;
}

// Check if the user has granted permissions for the app to record.
- (void) GrantPermission:(BOOL) startOver
{
    self.isInBackground = NO;
    
    // Start Over Flag is used only when the user wants to replace the old recording with a new one.
    if(startOver) {
        
        // Reset all the recorder properties to its original state.
        originalRecordExist = NO;
        tempRecordExist = NO;
        totalRecordTime = 0;
        originalRecordDuration = 0;
        newRecordDuration = 0;
        tempRecordURL = nil;
    }
    
    // If the user has exceeded the maximum recording time, stop.
    else if([self remainingTimeForRecord] <= 0)
        return;
    
    // If the user hasn't recorded anything yet, use the original recorder to record, then set the flag to YES.
    if(!originalRecordExist) {
        [recorder record];
        originalRecordExist = YES;
    }
    // If the user has already recorded a recording and wishes to continue, use the secondary recorder, and set the flag that a new recording exists, and that the secondary recording is not paused.
    else {
        [tempRecorder record];
        isTempRecordingPaused = NO;
        tempRecordExist = YES;
    }
    
    // Call the delegate method to notify that the recorder has started recording.
    [self.delegate AMZAudioDidStartRecording];
    
    // Use a record timer to update the recording time for UI purpose.
    recordTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    // Disable the idle timer in order to keep the screen on while recording.
    [self disableIdleTimer:YES];
    
    // Stop the recording when the recording reaches its maximum limit.
    [self performSelector:@selector(stopAudio:) withObject:nil afterDelay:[self remainingTimeForRecord]];
}

// If the user denies giving permissions for the app to use the microphone.
- (void) DenyPermission
{
    recorder=nil;
    NSLog(@"%@",[NSError errorWithDomain:@"Permission to microphone denied" code:109 userInfo:nil]);
}


- (void)recordAudio:(BOOL) startOver {
    
    // If the audio player is playing or it is paused, stop the audio player.
    if (player.playing || isPlayerPaused)
    {
        isPlayerPaused = NO;
        [player stop];
    }
    
    else if (!recorder.isRecording) {
        
        [playingSession setCategory :AVAudioSessionCategoryPlayAndRecord error:nil];
        [playingSession setActive:YES error:nil];
        
        switch ([[AVAudioSession sharedInstance] recordPermission]) {
            case AVAudioSessionRecordPermissionGranted:
            {
                [self GrantPermission:startOver];
                break;
            }
            case AVAudioSessionRecordPermissionDenied:
            {
                [self DenyPermission];
                break;
            }
            case AVAudioSessionRecordPermissionUndetermined:
            {
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                    if(granted)
                        [self GrantPermission:startOver];
                    else
                        [self DenyPermission];
                }];
                break;
            }
            default:
                break;
        }
        
    }
    else
        [self stopAudio:^(BOOL success) {}];
}

// Get the recorded audio length in seconds.
- (double) getAudioLength {
    NSError *error;
    
    // This is the original recording time, when the user first starts recording.
    oldPlayerSavedTime = [recorder currentTime];
    
    // The current recording time is the summation of the original recorder and the secondary recorder, while recording the audio
    newPlayerCurrentTime = oldPlayerSavedTime + [tempRecorder currentTime];
    
    // if the duration hasn't been calculated yet, so it is the first time the length is requested.
    if(originalRecordDuration == 0) {
        AVAudioPlayer *originalplayer = [[AVAudioPlayer alloc]
                                         initWithContentsOfURL:recorder.url
                                         error:&error];
        
        originalplayer.delegate = self;
        originalRecordDuration = [originalplayer duration];
    }
    
    // If there is a new recording that has been added to the old record, calculate the new audio length
    if(tempRecordURL!=nil) {
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc]
                                    initWithContentsOfURL:tempRecordURL
                                    error:&error];
        newPlayer.delegate = self;
        if([newPlayer duration] > 0) {
            newRecordDuration = [newPlayer duration];
        }
    }
    
    // If there is a new record duration value from the latter, then
    // totalRecordTime is equal to the new record duration of the secondary recorder + the current recording time while recording
    if(newRecordDuration > 0) {
        totalRecordTime = newRecordDuration + newPlayerCurrentTime;
        
        return totalRecordTime;
    }
    else {
        // totalRecordTime is equal to the original recording time + the current recording time while recording from any of the two recorders.
        totalRecordTime = originalRecordDuration + [recorder currentTime] + [tempRecorder currentTime];
        return totalRecordTime;
    }
}

- (void)playAudio {
    
    // If the original recorder is recording, stop
    if (recorder.isRecording)
        [recorder stop];
    
    // If the secondary recorder is recording, stop
    else if(tempRecorder.isRecording)
        [tempRecorder stop];
    
    // If the player is not playing
    if (!player.playing) {
        
        //if it is paused, resume
        if(isPlayerPaused) {
            [player play];
            recordTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            [self.delegate AMZAudioDidStartPlaying];
            return;
        }
        NSError *error;
        
        // if there is a combined new recording file
        if(tempRecordURL!=nil)
            player = [[AVAudioPlayer alloc]
                      initWithContentsOfURL:tempRecordURL
                      error:&error];
        
        else
            player = [[AVAudioPlayer alloc]
                      initWithContentsOfURL:recorder.url
                      error:&error];
        
        player.delegate = self;
        
        if (error) {
            NSLog(@"Error: %@",[error localizedDescription]);
        }
        else {
            [player play];
            recordTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            [self.delegate AMZAudioDidStartPlaying];
        }
        
        
    }
    // If it is playing, pause it
    else {
        [self pauseAudio];
    }
}

// Set when the app enters the background
- (void)setIsInBackground:(BOOL)isInBackground {
    appInBackground = isInBackground;
}

// Stop the audio recorder or the audio player
- (void)stopAudio:(void(^)(BOOL success))completionHandler {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopAudio:)
                                               object:nil];
    // this flag is used only when the app enters foreground when was in background
    shouldSave = NO;
    
    // Update the recording new length
    newRecordDuration += newPlayerCurrentTime;
    
    // If the original recorder is recording
    if (recorder.isRecording)
    {
        [self.delegate AMZAudioDidPauseRecording];
        [self.delegate AMZAudioDidSaveRecord:YES error:nil];
        [recorder stop];
        [playingSession setActive:NO error:nil];
        [self disableIdleTimer:NO];
        shouldSave = YES;
        if(completionHandler != nil)
            completionHandler(YES);
    }
    // If the secondary recorder was recording
    else if(!isTempRecordingPaused) {
        isTempRecordingPaused = YES;
        [tempRecorder stop];
        [playingSession setActive:NO error:nil];
        [self disableIdleTimer:NO];
        [self.delegate AMZAudioDidPauseRecording];
        shouldSave = YES;
        
        // If the app is in the foreground, combine the old recordings with the new one
        if(!appInBackground)
            [self saveRecordAndContinue:^(BOOL success) {
                if(completionHandler != nil)
                    completionHandler(success);
            }];
        
    }
    
    // If the audio player was playing or paused, stop
    else if (player.playing || isPlayerPaused) {
        isPlayerPaused = NO;
        [self.delegate AMZAudioDidStopPlaying];
        [self.delegate AMZAudioDidSaveRecord:YES error:nil];
        [player stop];
        [playingSession setActive:NO error:nil];
        [self disableIdleTimer:NO];
        if(completionHandler != nil)
            completionHandler(YES);
    }
    else
        if(completionHandler != nil)
            completionHandler(YES);
}

// Pause the audio player
- (void) pauseAudio {
    if(player.isPlaying) {
        isPlayerPaused = YES;
        [self.delegate AMZAudioDidPausePlaying];
        [player pause];
    }
    
}

// Used to control the offset from where the player should play the voice, if the user implemented a seek forward functionality
- (void) setPlayDuration:(NSTimeInterval)PlayDuration
{
    [player setCurrentTime:PlayDuration];
}

// Get the Record Length in seconds
- (NSTimeInterval) RecordDuration
{
    return [self getAudioLength];
}

// Check if the recorder is recording
- (BOOL) isRecording
{
    if(tempRecorder.isRecording || recorder.isRecording)
        return YES;
    else
        return NO;
}

// Check if the audio is playing
- (BOOL) isPlaying
{
    return player.isPlaying;
}

// Check if the audio player is paused
- (BOOL) isPaused {
    
    return isPlayerPaused;
}

// Return the Recorded File Data
- (NSData*) FileData
{
    if(!tempRecorder.isRecording && !recorder.isRecording) {
        if(tempRecordURL != nil) {
            NSError* error = nil;
            NSData* data = [NSData dataWithContentsOfURL:tempRecordURL options:NSDataReadingUncached error:&error];
            if (!error)
                return data;
        }
        else if(originalRecordExist) {
            NSError* error = nil;
            NSData* data = [NSData dataWithContentsOfURL:recorder.url options:NSDataReadingUncached error:&error];
            if (!error)
                return data;
        }
    }
    return nil;
}

// Get the audio player current playing time
- (NSTimeInterval) PlayDuration
{
    return [player currentTime];
}

// The function takes the time in seconds and returns a string showing the recorded time or playing time, i.e 01:24
- (NSString*) GetTime:(double) time
{
    int minutes=time/60;
    int seconds=(int)time%60;
    return [NSString stringWithFormat:@"%@:%@",[self GetTimeNumber:[NSNumber numberWithInt:minutes]],[self GetTimeNumber:[NSNumber numberWithInt:seconds]]];
}

// This function keeps updating the delegates of the current state of the recorder or the audio player
- (void)updateTime {
    if(!recorder.isRecording && !tempRecorder.isRecording && !player.isPlaying) {
        [self.delegate AMZAudioRecordingTime:player.currentTime totalRecordedTime:totalRecordTime];
        [recordTimer invalidate];
    }
    
    
    if(recorder.isRecording) {
        [self.delegate AMZAudioRecordingTime:oldPlayerSavedTime totalRecordedTime:totalRecordTime];
        
    }
    else if(tempRecorder.isRecording) {
        [self.delegate AMZAudioRecordingTime:newPlayerCurrentTime totalRecordedTime:totalRecordTime];
    }
    
    else if(player.isPlaying) {
        [self.delegate AMZAudioRecordingTime:(player.currentTime+0.25) totalRecordedTime:totalRecordTime];
    }
}

// Combines the old record file with the new one, the new record file contains the previous recordings with the new one.
- (void) saveRecordAndContinue:(void(^)(BOOL success))completionHandler {
    // Generate a composition of the two audio assets that will be combined into
    // a single track
    AVMutableComposition* composition = [AVMutableComposition composition];
    AVMutableCompositionTrack* audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // grab the two audio assets as AVURLAssets according to the file paths
    AVURLAsset* masterAsset;
    if(tempRecordURL != nil)
        masterAsset = [[AVURLAsset alloc] initWithURL:tempRecordURL options:nil];
    else
        masterAsset = [[AVURLAsset alloc] initWithURL:recorder.url options:nil];
    
    AVURLAsset* activeAsset = [[AVURLAsset alloc] initWithURL:tempRecorder.url options:nil];
    
    NSError* error = nil;
    
    // grab the portion of interest from the master asset
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, masterAsset.duration)
                        ofTrack:[[masterAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];
    if (error)
    {
        // report the error
        return;
    }
    
    // append the entirety of the active recording
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, activeAsset.duration)
                        ofTrack:[[activeAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                         atTime:masterAsset.duration
                          error:&error];
    
    if (error)
    {
        // report the error
        return;
    }
    
    // now export the two files
    // create the export session
    // no need for a retain here, the session will be retained by the
    // completion handler since it is referenced there
    
    AVAssetExportSession* exportSession = [AVAssetExportSession
                                           exportSessionWithAsset:composition
                                           presetName:AVAssetExportPresetAppleM4A];
    if (nil == exportSession)
    {
        // report the error
        return;
    }
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [cacheDir stringByAppendingPathComponent:@"/AudioFiles"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    {
        NSError *error=nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"ddMMyyyyHHmmss"];
    
    NSDate *now = [[NSDate alloc] init];
    NSString *dateString = [format stringFromDate:now];
    NSString* path = [NSString stringWithFormat:@"%@.m4a",dateString];// create a new file for the combined file
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               dataPath,
                               path,
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // configure export session  output with all our parameters
    exportSession.outputURL = outputFileURL; // output path
    exportSession.outputFileType = AVFileTypeAppleM4A; // output file type
    tempRecordURL = outputFileURL;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = exportSession.error;
        // export status changed, check to see if it's done, errored, waiting, etc
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exportSession.status)
            {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed: %@", error);
                    [self.delegate AMZAudioDidSaveRecord:NO error:error];
                    completionHandler(NO);
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    [self.delegate AMZAudioDidSaveRecord:YES error:nil];
                    completionHandler(YES);
                    break;
                case AVAssetExportSessionStatusUnknown:
                    NSLog (@"AVAssetExportSessionStatusUnknown");
                    [self.delegate AMZAudioDidSaveRecord:NO error:error];
                    completionHandler(NO);
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog (@"AVAssetExportSessionStatusExporting");
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog (@"AVAssetExportSessionStatusCancelled");
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog (@"AVAssetExportSessionStatusWaiting");
                    break;
                    
                default:
                    completionHandler(NO);
                    break;
            }
        });
    }];
}

// AVAudio Player Delegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(flag)
        [self.delegate AMZAudioDidStopPlaying];
}

// Remove all the recorded files from memory
- (void) ClearCache
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"/AudioFiles"];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, file] error:&error];
        if (!success || error) {
            // it failed.
        }
    }
}

#pragma mark - Time Formatting Helper Methods
- (NSString*) GetTimeNumber:(NSNumber *)number
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterNoStyle];
    [formatter setFormatWidth:2];
    [formatter setPaddingCharacter:[self GetNumber:@0 withDecimalValue:NO]];
    NSString *arStr= [formatter stringFromNumber:number];
    return arStr;
}
- (NSString*) GetNumber:(NSNumber *)number withDecimalValue:(BOOL)withDecimal
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    if(!withDecimal)
        [formatter setNumberStyle: NSNumberFormatterNoStyle];
    else {
        [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
        [formatter setMaximumFractionDigits:2];
    }
    NSString *arStr= [formatter stringFromNumber:number];
    return arStr;
}

@end
