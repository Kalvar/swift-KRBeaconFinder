//
//  AppDelegate.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, KRBeaconOneDelegate {
                            
    var window: UIWindow?
    var beaconFinder : KRBeaconOne!;

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool
    {
        beaconFinder             = KRBeaconOne.sharedFinder;
        beaconFinder.oneDelegate = self;
        beaconFinder.uuid        = "B9407F30-F5F8-466E-AFF9-25556B57FE6D";
        beaconFinder.identifier  = "com.kalvar.ibeacons";
        beaconFinder.awakeDisplay();
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func krBeaconOneDidDetermineState(beaconFinder : KRBeaconOne, state : CLRegionState, region : CLRegion)
    {
        let appState : UIApplicationState = UIApplication.sharedApplication().applicationState;
        println("state : \(appState)");
        
        if appState != UIApplicationState.Active
        {
            if state == CLRegionState.Inside
            {
                beaconFinder.fireLocalNotification("You're inside the beacon delegate");
            }
            else if state == CLRegionState.Outside
            {
                beaconFinder.fireLocalNotification("You're outside the beacon delegate");
            }
            else
            {
                return;
            }
        }
    }

}

