//
//  ViewController.h
//  AMZRecorder
//
//  Created by Admin on 1/13/17.
//  Copyright © 2017 Admin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMZRecorder.h"

@interface ViewController : UIViewController <AMZRecorderDelegate>
{
    AMZRecorder *audioKit;
}


@end

