//
//  AMZRecorder.h
//  AMZRecorder
//
//  Created by Admin on 1/13/17.
//  Copyright © 2017 Admin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol AMZRecorderDelegate <NSObject>

/*
    Notify when the recorder starts recording
*/
- (void) AMZAudioDidStartRecording;
/*
 Notify when the recorder pauses recording
 */
- (void) AMZAudioDidPauseRecording;

/*
 Notify when the audio player plays the record
 */
- (void) AMZAudioDidStartPlaying;

/*
 Notify when the audio player pauses the record
 */
- (void) AMZAudioDidPausePlaying;

/*
 Notify when the audio player stops playing the record
 */
- (void) AMZAudioDidStopPlaying;
@optional

/*
 Keeps track of the current state of the recording
 #recordTime: Provides the current recording/playing time in seconds
 
 When the audio player is playing, recordTime is the current playing time in seconds
 When the recorder is recording without previously being paused, recordTime is the current recording time in seconds
 When the recorder is recording but being previously paused, recordTime is the current recording time + the previous recordings time in seconds.
 
 #totalRecordTime: Provides the total recording length in seconds
 */
- (void) AMZAudioRecordingTime:(double)recordTime totalRecordedTime:(double)totalRecordTime;

/*
 Notify when the record has been successfully saved in the memory.
 The saving method of the recorded file is asynchronous
 When the audio files are combined together, this method is triggered to notify if successfully saved or not
 As the file gets larger, it would take some more little time to save
 So in order for the files to not get corrupted,
 Put a loader when the user clicks on pause and remove the loader inside this method
 */
- (void) AMZAudioDidSaveRecord:(BOOL)succeed error:(NSError*)error;
@end

@interface AMZRecorder : NSObject <AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    //Original Recorder
    AVAudioRecorder *recorder;
    
    //Secondary Recorder
    AVAudioRecorder *tempRecorder;
    
    //Audio Player
    AVAudioPlayer *player;
    AVAudioSession *playingSession;
    
    //Timer used to keep calling the delegate methods to update the user with the current status of the recorder
    NSTimer *recordTimer;
    
    //Total recorded length in seconds
    double totalRecordTime;
    
    //Flag to determine if the audio player is paused
    BOOL isPlayerPaused;
    
    //Flag to determine if there exists an old recorded file
    BOOL originalRecordExist;
    
    //Flag to determine if there exists a new recorded file
    BOOL tempRecordExist;
    
    //Flag to determine if the secondary recorded is paused
    BOOL isTempRecordingPaused;
    
    //Flag to determine if the app is in the background
    BOOL appInBackground;
    
    //Flag to determine if the app should save the recorded file
    //When the app enters background while recording, the recorder pauses, and the when entering the foreground
    //this flag is set and the recorded audio is saved.
    BOOL shouldSave;
    
    //Value set by the user to determine the maximum recording time allowed in seconds.
    int maxRecordTime;
    
    //These time intervals are used to calculate the record length in seconds.
    NSTimeInterval newRecordDuration;
    NSTimeInterval originalRecordDuration;
    NSTimeInterval newPlayerCurrentTime;
    NSTimeInterval oldPlayerSavedTime;
    
    //Recorded File Name
    NSString *FileName;
    
    //URL of the recorded file saved in the memory
    NSURL *tempRecordURL;
    
}
@property (nonatomic,weak) id<AMZRecorderDelegate> delegate;

// Get the recorded file data
@property (nonatomic,readonly) NSData *FileData;

// Get the record duration in seconds.
@property (nonatomic,readonly) NSTimeInterval RecordDuration;

// Used to set the offset of the audio player from where to play the audio
@property (nonatomic,assign) NSTimeInterval PlayDuration;

// Status of the Recorder/Player
@property (nonatomic,readonly) BOOL isRecording,isPlaying,isPaused;

// Must be set to YES when the app enters the background, and NO when it enters the foreground
@property (nonatomic,assign) BOOL isInBackground;

// Set the maximum recording time allowed in seconds
@property (nonatomic,assign) int MaxRecordingTime;

// Initialize the audio recorder
- (id) initAudioRecorder;

// Start recording, if startOver is set to YES the record is overriden, else the record is combined with an old one.
- (void)recordAudio:(BOOL) startOver;

// Play the recorded file
- (void)playAudio;

// Stop the recording or audio playing
- (void)stopAudio:(void(^)(BOOL success))completionHandler;

// Pause the audio playing
- (void)pauseAudio;
@end
