//
//  KRBeaconFinder.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

enum KRBeaconNotifyModes : Int
{
    case Deny
    case OnlyDisplay
    case OnlyEntry
    case DisplayAndEntry
    case OnlyExit
    case DisplayAndExit
    case EntryAndExit
    case Default
}

@objc protocol KRBeaconFinderDelegate : NSObjectProtocol
{
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!)
    @optional func peripheralManager(peripheral: CBPeripheralManager!, willRestoreState dict: NSDictionary!)
}

class KRBeaconFinder : NSObject, CLLocationManagerDelegate
{
    typealias FoundBeaconsHandler  = (foundBeacons : NSArray, beaconRegion : CLBeaconRegion) -> Void;
    typealias EnterRegionHandler   = (manager : CLLocationManager, region : CLRegion) -> Void;
    typealias ExitRegionHandler    = (manager : CLLocationManager, region : CLRegion) -> Void;
    typealias DisplayRegionHandler = (manager : CLLocationManager, region : CLRegion, state : CLRegionState) -> Void;
    
    var delegate         : KRBeaconFinderDelegate?;
    var locationManager  : CLLocationManager!;
    var foundBeacons     : AnyObject[] = [];
    var rangedRegions    : AnyObject[] = [];
    var monitoredRegions : AnyObject[] = [];
    
    var isRanging        : Bool;
    var isMonitoring     : Bool;
    
    //regions will use for ranging and monitoring more different regions of beacon.
    var regions          : AnyObject[] = [];
    var adverstingRegion : CLBeaconRegion?;
    
    var foundBeaconsHandler  : FoundBeaconsHandler?;
    var enterRegionHandler   : EnterRegionHandler?;
    var exitRegionHandler    : ExitRegionHandler?;
    var displayRegionHandler : DisplayRegionHandler?;
    
    var beaconCentral         : KRBeaconCentral;
    var beaconPeripheral      : KRBeaconPeripheral;
    var bleScanningEnumerator : KRBeaconCentral.ScanningEnumerator?;
    
    class var sharedFinder : KRBeaconFinder
    {
        struct Singleton
        {
            static let instance : KRBeaconFinder = KRBeaconFinder();
        }
        return Singleton.instance;
    }
    
    init()
    {
        //super.init();
        isRanging        = false;
        isMonitoring     = false;
        adverstingRegion = nil;
    }
    
}

