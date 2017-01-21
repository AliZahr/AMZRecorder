//
//  ViewController.m
//  AMZRecorder
//
//  Created by Admin on 1/13/17.
//  Copyright © 2017 Admin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    audioKit = [[AMZRecorder alloc] initAudioRecorder];
    audioKit.delegate = self;
    audioKit.MaxRecordingTime = 30;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playAudio:(id)sender
{
    [audioKit playAudio];
}

- (IBAction)pauseAudio:(id)sender
{
    [audioKit pauseAudio];
}

- (IBAction)stopAudio:(id)sender
{
    [audioKit stopAudio:^(BOOL success) {}];
}

- (IBAction)startRecording:(id)sender
{
    [audioKit recordAudio:YES];
}

- (IBAction)ResumeRecording:(id)sender
{
    [audioKit recordAudio:NO];
}

- (IBAction)stopRecording:(id)sender
{
    [audioKit stopAudio:^(BOOL success) {
        double recordedTime = audioKit.RecordDuration;
        NSLog(@"Paused Recording with total time: %.2f", recordedTime);
    }];
}

#pragma mark - AMZRecorder Delegate Methods

- (void) AMZAudioDidStartRecording
{
    
}
- (void) AMZAudioDidPauseRecording
{
    
}
- (void) AMZAudioDidStartPlaying
{
    
}
- (void) AMZAudioDidPausePlaying
{
    
}
- (void) AMZAudioDidStopPlaying
{
    
}
- (void) AMZAudioRecordingTime:(double)recordTime totalRecordedTime:(double)totalRecordTime
{
    
}
- (void) AMZAudioDidSaveRecord:(BOOL)succeed error:(NSError*)error
{

}

@end
