//
//  ParticleSetupSuccessFailureViewController.m
//  teacup-ios-app
//
//  Created by Ido on 2/3/15.
//  Copyright (c) 2015 spark. All rights reserved.
//


#ifdef USE_FRAMEWORKS
#import <ParticleSDK/ParticleSDK.h>
#else

#import "Particle-SDK.h"

#endif

#import "ParticleSetupUIElements.h"
#import "ParticleSetupMainController.h"
#import "ParticleSetupWebViewController.h"
#import "ParticleSetupCustomization.h"
#import "ParticleSetupResultViewController.h"

#ifdef ANALYTICS
#import <SEGAnalytics.h>
#endif

@interface ParticleSetupResultViewController () <UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet ParticleSetupUILabel *shortMessageLabel;
@property(weak, nonatomic) IBOutlet ParticleSetupUILabel *longMessageLabel;
@property(weak, nonatomic) IBOutlet UIImageView *setupResultImageView;
@property(weak, nonatomic) IBOutlet UIImageView *brandImageView;
@property(weak, nonatomic) IBOutlet UIImageView *brandBackgroundImageView;

@property(weak, nonatomic) IBOutlet ParticleSetupUILabel *nameDeviceLabel;
@property(weak, nonatomic) IBOutlet UITextField *nameDeviceTextField;
@property(strong, nonatomic) NSArray *randomDeviceNamesArray;
@property(nonatomic) BOOL deviceNamed;
@end

@implementation ParticleSetupResultViewController


- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.presentedViewController) {
        return self.presentedViewController.preferredStatusBarStyle;
    } else {
        return ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // set logo
    self.brandImageView.image = [ParticleSetupCustomization sharedInstance].brandImage;
    self.brandImageView.backgroundColor = [UIColor clearColor];
    self.brandBackgroundImageView.backgroundColor = [ParticleSetupCustomization sharedInstance].brandImageBackgroundColor;
    self.brandBackgroundImageView.image = [ParticleSetupCustomization sharedInstance].brandImageBackgroundImage;


    self.nameDeviceLabel.hidden = YES;
    self.nameDeviceTextField.hidden = YES;

    // Trick to add an inset from the left of the text fields
    CGRect viewRect = CGRectMake(0, 0, 10, 32);
    UIView *emptyView = [[UIView alloc] initWithFrame:viewRect];

    self.nameDeviceTextField.leftView = emptyView;
    self.nameDeviceTextField.leftViewMode = UITextFieldViewModeAlways;
    self.nameDeviceTextField.delegate = self;
    self.nameDeviceTextField.returnKeyType = UIReturnKeyDone;
    self.nameDeviceTextField.font = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].normalTextFontName size:16.0];

    // init funny random device names
    //self.randomDeviceNamesArray = [NSArray arrayWithObjects:@"aardvark", @"bacon", @"badger", @"banjo", @"bobcat", @"boomer", @"captain", @"chicken", @"cowboy", @"maker", @"splendid", @"sparkling", @"dentist", @"doctor", @"green", @"easter", @"ferret", @"gerbil", @"hacker", @"hamster", @"wizard", @"hobbit", @"hoosier", @"hunter", @"jester", @"jetpack", @"kitty", @"laser", @"lawyer", @"mighty", @"monkey", @"morphing", @"mutant", @"narwhal", @"ninja", @"normal", @"penguin", @"pirate", @"pizza", @"plumber", @"power", @"puppy", @"ranger", @"raptor", @"robot", @"scraper", @"burrito", @"station", @"tasty", @"trochee", @"turkey", @"turtle", @"vampire", @"wombat", @"zombie", nil];
    self.deviceNamed = NO;
    
    //Current Labs changes to make the name show up as the user email (also commented out above array)
    //and gets rid of the naming step

    NSString *username = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"s453245"]];
    if (username) {
        self.randomDeviceNamesArray = [NSArray arrayWithObject:username];
    } else {
        self.randomDeviceNamesArray = [NSArray arrayWithObject:@"nope"];
    }
    [self doneButtonTapped:self];

}

- (void)viewDidAppear:(BOOL)animated {
    if ((!isiPhone4) && (!isiPhone5))
        [self disableKeyboardMovesViewUp];

    if (self.setupResult == ParticleSetupMainControllerResultSuccess) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.nameDeviceTextField becomeFirstResponder];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
#ifdef ANALYTICS
    [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_SetupResultScreen"];
#endif


    [super viewWillAppear:animated];

    switch (self.setupResult) {
        case ParticleSetupMainControllerResultSuccess: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"success"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_Success_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_Success_Text;

            self.nameDeviceLabel.hidden = NO;
            self.nameDeviceTextField.hidden = NO;
            NSString *randomDeviceName1 = self.randomDeviceNamesArray[arc4random_uniform((UInt32) self.randomDeviceNamesArray.count)];
            NSString *randomDeviceName2 = self.randomDeviceNamesArray[arc4random_uniform((UInt32) self.randomDeviceNamesArray.count)];
            self.nameDeviceTextField.text = [NSString stringWithFormat:@"%@_%@", randomDeviceName1, randomDeviceName2];
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Success"];
#endif

            break;
        }

        case ParticleSetupMainControllerResultSuccessDeviceOffline: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"warning"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_DeviceOffline_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_DeviceOffline_Message;

#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Success" properties:@{@"reason":@"device offline"}];
#endif
            break;
        }

        case ParticleSetupMainControllerResultSuccessNotClaimed: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"success"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_NotClaimed_Title;
            //Current Labs changes
            if ([ParticleSetupCustomization sharedInstance].deviceWorkingColor.length > 0) {
                //we good
            } else {
                [ParticleSetupCustomization sharedInstance].deviceWorkingColor = @"breathing cyan";
            }
            if ([ParticleSetupCustomization sharedInstance].isParticleDevice) {
                //exisiting particle function
                self.longMessageLabel.text = @"Your device has been successfully claimed to your account, however it is offline. If the device was already claimed before this setup, then the Wi-Fi connection may have failed, and you should try setup again.";
            } else {
                //esp32 stuff
                self.longMessageLabel.text = @"Setup was successful. If you see the LED breathing white this means it worked! If not, please restart the setup process.";
            }
            //current labs changes end
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Success" properties:@{@"reason":@"not claimed"}];
#endif
            break;

        }

        case ParticleSetupMainControllerResultFailureClaiming: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_ClaimingFailed_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_ClaimingFailed_Message;
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Failure" properties:@{@"reason":@"claiming failed"}];
#endif

            break;
        }

        case ParticleSetupMainControllerResultFailureCannotDisconnectFromDevice: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_CannotDisconnectFromDevice_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_CannotDisconnectFromDevice_Message;
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Failure" properties:@{@"reason":@"cannot disconnect"}];
#endif

            break;
        }


        case ParticleSetupMainControllerResultFailureConfigure: {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_ConfigurationFailure_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_ConfigurationFailure_Message;
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Failure" properties:@{@"reason":@"cannot configure"}];
#endif
            break;
        }

        default: //ParticleSetupMainControllerResultFailureLostConnectionToDevice
        {
            self.setupResultImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = ParticleSetupStrings_SetupResult_Result_Default_Title;
            self.longMessageLabel.text = ParticleSetupStrings_SetupResult_Result_Default_Message;
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_Failure" properties:@{@"reason":@"lost connection"}];
#endif

            break;
        }


    }

    [self replaceSetupStrings:self.view];
    [self.longMessageLabel setType:@"normal"];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.nameDeviceTextField) {
        [self trimTextFieldValue:self.nameDeviceTextField];
        [self.device rename:self.nameDeviceTextField.text completion:^(NSError *error) {
            if (error) {
                NSLog(@"Error naming device %@", error.description);
            } else {
                self.deviceNamed = YES;
            }
            [textField resignFirstResponder];
            [self doneButtonTapped:self];
        }];

    }

    return YES;

}


- (IBAction)doneButtonTapped:(id)sender {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (self.device) {
        userInfo[kParticleSetupDidFinishDeviceKey] = self.device;
    } else {
        NSLog(@"test");
        [[ParticleCloud sharedInstance] getDevice:@"nope" completion:^(ParticleDevice * _Nullable device, NSError * _Nullable error) {
            if (!error) {
                userInfo[kParticleSetupDidFinishDeviceKey] = device;
            }
        }];
    }

    if (self.deviceID)
        userInfo[kParticleSetupDidFailDeviceIDKey] = self.deviceID;

    userInfo[kParticleSetupDidFinishStateKey] = @(self.setupResult);

    if (self.setupResult == ParticleSetupMainControllerResultSuccess) {

        if (!self.deviceNamed) {
            [self.device rename:self.nameDeviceTextField.text completion:^(NSError *error) {
                if (error) {
                    NSLog(@"error name device %@", error.description);
                } else {
                    self.deviceNamed = YES;
                }
            }];
        }
        
        if ([ParticleSetupCustomization sharedInstance].isParticleDevice) {
            //exisiting particle function
            // Update zero notice to user
            // TODO: condition message only if its really getting update zero (need event listening)
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"shownUpdateZeroNotice"]) {
                if ([ParticleSetupCustomization sharedInstance].deviceWorkingColor.length > 0) {
                    //we good
                } else {
                    [ParticleSetupCustomization sharedInstance].deviceWorkingColor = @"breathing cyan";
                }
                NSString *alertMessage = [NSString stringWithFormat:@"If this is the first time you are setting up this device it might blink its LED in magenta color for a while, this means the device is currently updating its firmware from the cloud to the latest version. Please be patient and do not press the reset button. The Device LED will be %@ once update has completed and it has come online.", [ParticleSetupCustomization sharedInstance].deviceWorkingColor];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware update" message:alertMessage delegate:nil cancelButtonTitle:@"Understood" otherButtonTitles:nil];
               // [alert show];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownUpdateZeroNotice"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }

    // finish with success and provide device
    [[NSNotificationCenter defaultCenter] postNotificationName:kParticleSetupDidFinishNotification
                                                        object:nil
                                                      userInfo:userInfo];

}


- (IBAction)troubleshootingButtonTouched:(id)sender {
    ParticleSetupWebViewController* webVC = [[ParticleSetupMainController getSetupStoryboard] instantiateViewControllerWithIdentifier:@"webview"];
    webVC.link = [ParticleSetupCustomization sharedInstance].troubleshootingLinkURL;
    [self presentViewController:webVC animated:YES completion:nil];
}


@end
