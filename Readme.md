#AMZRecorder

AMZRecorder is an Audio Kit that supports:

* Audio Recording
* Audio Recording Pause
* Audio Recording Stop
* Audio Recording Play
* Audio Recording Playing Pause
* Audio Recording Playing Stop

The recorder records in MPEG4(m4a) format which is optimized for the smallest size possible.
Size of audio file in KB of duration 10 sec.

* kAudioFormatMPEG4AAC : 164,

* kAudioFormatAppleLossless : 430,

* kAudioFormatAppleIMA4 : 475,

* kAudioFormatULaw : 889,

* kAudioFormatALaw : 889,

see: [Record audio on iPhone with smallest file size](http://stackoverflow.com/a/7284602/6532217)

##Installation

Drag and Drop the the files "AMZRecorder.h" and "AMZRecorder.m" to your project.

##Usage

###Initializing the Audio Recorder

```
AMZRecorder *audioKit = [[AMZRecorder alloc] initAudioRecorder];
audioKit.delegate = self;
audioKit.MaxRecordingTime = 10;
```
audioKit object comforms to `<AMZRecorderDelegate>` delegate

###Delegate Methods
These delegate methods are mainly used to help you implement your UI changes whenever you change from a state to another. You can apply whatever logic you wish inside them.

```
- (void) AMZAudioDidStartRecording;

- (void) AMZAudioDidPauseRecording;

- (void) AMZAudioDidStartPlaying;

- (void) AMZAudioDidPausePlaying;

- (void) AMZAudioDidStopPlaying;

```
####Optional Delegate Methods
These methods are optional ones to help you keep track of the recorded file.

```
- (void) AMZAudioRecordingTime:(double)recordTime totalRecordedTime:(double)totalRecordTime
{
	// To get the progress of the player playing the record
	double progress = (recordTime*100+1)/totalRecordTime;

	// To display the audio playing countdown
	int minutes=(totalRecordTime-recordTime)/60;
    int seconds=(int)(totalRecordTime-recordTime)%60;
    NSString *time = [NSString stringWithFormat:@"%i:%i", minutes, seconds];
    
    // To get the current recording time while recording
    double recordingTime = audioKit.RecordDuration+1;
    
    // To get the current minute which the audio player is paused at
    double pausedPlayerAt = totalRecordTime - recordTime;
    
    // To get the total record time
    double overAllRecord = totalRecordTime;
}

- (void) AMZAudioDidSaveRecord:(BOOL)succeed error:(NSError*)error
{
	// Used when saving the current record to the memory and when combining  
	the new record files together.
	//The best practice is to implement an Activity Indicator (Loader) in the  
	method ProfAudioDidPauseRecording then inside this method hide the loader  
	to make sure that the recorded file is successfully saved to the memory.
}
```

###Properties
####Check the status of the recorder
* audioKit.isRecording
* audioKit.isPlaying
* audioKit.isPaused

####Get the record duration
* audioKit.RecordDuration

####Check if there is a record file or not (FileData != nil)
* audioKit.FileData

####Set Maximum Recording Time in Seconds
* audioKit.MaxRecordingTime

####When the application enters foreground
* audioKit.shouldSaveRecord = YES;
* audioKit.isInBackground = NO;

####When the application enters the background
* audioKit.isInBackground = YES;
* [audioKit stopAudio:^(BOOL success) {}];

##License
AMZRecorder is released under the MIT license. See LICENSE for details.