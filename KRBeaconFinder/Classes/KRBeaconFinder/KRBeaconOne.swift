//
//  KRBeaconOne.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import CoreLocation
import CoreBluetooth

@objc protocol KRBeaconOneDelegate : NSObjectProtocol
{
    @optional func krBeaconOneDidDetermineState(beaconFinder : KRBeaconOne, state : CLRegionState, region : CLRegion);
    
}

class KRBeaconOne : KRBeaconFinder, CLLocationManagerDelegate
{
    var oneDelegate     : KRBeaconOneDelegate? = nil;
    var uuid            : String!;
    var identifier      : String!;
    var major           : UInt16?;
    var minor           : UInt16?;
    
    var beaconRegion    : CLBeaconRegion? = nil
    {
    didSet
    {
        //同步設定 beaconPeripheral 要廣播的 beaconRegion
        if beaconPeripheral != nil
        {
            super.beaconPeripheral!.beaconRegion = beaconRegion;
        }
    }
    };
    
    var notifyOnDisplay : Bool!
    {
    didSet
    {
        if beaconRegion != nil
        {
            beaconRegion!.notifyEntryStateOnDisplay = notifyOnDisplay;
        }
    }
    };
    
    var notifyOnEntry   : Bool!
    {
    didSet
    {
        if beaconRegion != nil
        {
            beaconRegion!.notifyOnEntry = notifyOnEntry;
        }
    }
    };
    
    var notifyOnExit    : Bool!
    {
    didSet
    {
        if beaconRegion != nil
        {
            beaconRegion!.notifyOnExit = notifyOnExit;
        }
    }
    };
    
    var notifyMode      : KRBeaconNotifyModes
    {
    set
    {
        //KRBeaconNotifyModes.Default
        //...
    }
    
    get
    {
        /*
        * @ 演算法則
        *   - 1. 先將 KRBeaconNotifyModes 以 2 進制模式編排 :
        *
        *      //0 0 0
        *      .Deny = 0,         //0
        *      //1 0 0
        *      .OnlyDisplay,      //1
        *      //0 1 0
        *      .OnlyEntry,        //2
        *      //1 1 0
        *      .DisplayAndEntry,  //3
        *      //0 0 1
        *      .OnlyExit,         //4
        *      //1 0 1
        *      .DisplayAndExit,   //5
        *      //0 1 1
        *      .EntryAndExit,     //6
        *      //1 1 1
        *      .Default           //7
        *
        *   - 2. 再將 _notifyOnDisplay, _notifyOnEntry, _notifyOnExit 依照順序放入陣列。
        *
        *   - 3. 依陣列位置給 2^0, 2^1, 2^2 值。
        *        - 因為代入的判斷參數只有 true / false 2 種狀態，故以 2 為基底。
        *        - 如代入的判斷參數有 0, 1, 2 這 3 種狀態，就要以 3 為基底，其它以此類推。
        *
        *   - 4. 列舉陣列值，只要為 true 就累加起來。
        *
        *   - 5. 最後依照累加的總值對應 KRBeaconNotifyModes 的位置即可。
        *
        */
        var _styles : Bool[]  = [notifyOnDisplay, notifyOnEntry, notifyOnExit];
        //如代入的參數為 2 種判斷狀態，就以 2 為基底，如為 3 種判斷狀態，就代 3，其餘以此類推。
        let _binaryCode : Int = 2;
        var _times      : Int = 0;
        var _sum        : Int = 0;
        for _everyStyle : Bool in _styles
        {
            if true == _everyStyle
            {
                //sumOf( 2^0, 2^1 ... )
                _sum += Int( pow(Double(_binaryCode), Double(_times)) );
            }
            ++_times;
        }
        //從 Int 轉換成 enum 相對應位置的值
        return KRBeaconNotifyModes.fromRaw(_sum)!;
    }
    };
    
    /*
    * #pragma --mark Private Methods
    */
    func _createBeaconRegion()
    {
        //Has value is return.
        if let _someBeacon = beaconRegion
        {
            return;
        }
        
        //proximityUUID 指的是該 Apple Certificated Beacon ID，而不是 BLE 掃出來的 DeviceUUID
        let proximityUUID : NSUUID = NSUUID(UUIDString : uuid);
        if( major > 0 && minor > 0 )
        {
            beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, major: major!, minor: minor!, identifier: identifier);
        }
        else
        {
            if( major > 0 )
            {
                beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, major: major!, identifier: identifier!);
            }
            else
            {
                beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, identifier: identifier!);
            }
        }
        
        if beaconRegion? != nil
        {
            beaconRegion!.notifyEntryStateOnDisplay = notifyOnDisplay;
            beaconRegion!.notifyOnEntry             = notifyOnEntry;
            beaconRegion!.notifyOnExit              = notifyOnExit;
            super.addRegion( beaconRegion! );
        }
        
    }
    
    /*
    * #pragma --mark Public Methods
    */
    //override extended singleton method.
    override class var sharedFinder : KRBeaconOne
    {
        struct Singleton
        {
            static let instance : KRBeaconOne = KRBeaconOne();
        }
        return Singleton.instance;
    }
    
    //init does not override
    init()
    {
        //如果沒有 ? 問號的變數，就一定要在這裡作初始化的動作
        super.init();
        /*
        //Extends and Overrides all of works
        super.test();
        self.test();
        test();
        */
        
        uuid                           = nil;
        identifier                     = nil;
        major                          = 0;
        minor                          = 0;
        
        notifyOnDisplay                = true;
        notifyOnEntry                  = true;
        notifyOnExit                   = true;
        
        oneDelegate                    = nil;
        
        //GCG still Works
        //dispatch_async(dispatch_get_main_queue(), {});
        
        super.locationManager.delegate = self;
        
    }
    
    /*
    * #pragma --mark Override Add Region Methods
    */
    func addRegionWithUuid(beaconUuid : String, beaconIdentifier : String, beaconMajor : UInt16, beaconMinor : UInt16)
    {
        uuid         = beaconUuid;
        identifier   = beaconIdentifier;
        major        = beaconMajor;
        minor        = beaconMinor;
        beaconRegion = nil;
        _createBeaconRegion();
    }
    
    /*
    * #pragma --mark Override Ranging Methods
    */
    /*
    * @ 開始範圍搜索
    */
    override func ranging(founder : FoundBeaconsHandler?)
    {
        _createBeaconRegion();
        super.ranging( founder );
    }
    
    override func ranging()
    {
        _createBeaconRegion();
        ranging();
    }
    
    override func stopRanging()
    {
        super.stopRanging();
    }
    
    /*
    * #pragma --mark Override Monitoring Methods
    */
    override func monitoring(handler : DisplayRegionHandler?)
    {
        _createBeaconRegion();
        super.monitoring( handler );
    }
    
    override func monitoring()
    {
        _createBeaconRegion();
        super.monitoring();
    }
    
    override func stopMonitoring()
    {
        super.stopMonitoring();
    }
    
    override func awakeDisplay(completion : DisplayRegionHandler?)
    {
        super.displayRegionHandler = completion;
        monitoring();
    }
    
    override func awakeDisplay()
    {
        awakeDisplay( super.displayRegionHandler );
    }
    
    override func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if !CLLocationManager.locationServicesEnabled()
        {
            return;
        }
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.Authorized
        {
            return;
        }
    }
    
    override func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!)
    {
        println("beacons 2 \(beacons)");
        self.foundBeacons = beacons;
        //All of works.
        //if self.foundBeaconsHandler? != nil
        //if self.foundBeaconsHandler
        foundBeaconsHandler?(foundBeacons : foundBeacons, beaconRegion : region);
    }
    
    override func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!)
    {
        enterRegionHandler?(manager : manager, region : region);
    }
    
    override func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!)
    {
        exitRegionHandler?(manager : manager, region : region);
    }
    
    override func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!)
    {
        oneDelegate?.krBeaconOneDidDetermineState?(self, state : state, region : region);
        displayRegionHandler?(manager : manager, region : region, state : state);
    }
    
}

