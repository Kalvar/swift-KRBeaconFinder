//
//  KRBeaconFinder.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

enum KRBeaconNotifyModes : Int
{
    //0 0 0
    case Deny
    //1 0 0
    case OnlyDisplay
    //0 1 0
    case OnlyEntry
    //1 1 0
    case DisplayAndEntry
    //0 0 1
    case OnlyExit
    //1 0 1
    case DisplayAndExit
    //0 1 1
    case EntryAndExit
    //1 1 1
    case Default
}

@objc protocol KRBeaconFinderDelegate : NSObjectProtocol
{
    @optional func krBeaconFinderDidDetermineState(beaconFinder : KRBeaconFinder, state : CLRegionState, region : CLRegion);
    
    //func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!)
    //@optional func peripheralManager(peripheral: CBPeripheralManager!, willRestoreState dict: NSDictionary!)
}

class KRBeaconFinder : NSObject, CLLocationManagerDelegate
{
    typealias FoundBeaconsHandler  = (foundBeacons : AnyObject[], beaconRegion : CLBeaconRegion) -> Void;
    typealias EnterRegionHandler   = (manager : CLLocationManager, region : CLRegion) -> Void;
    typealias ExitRegionHandler    = (manager : CLLocationManager, region : CLRegion) -> Void;
    typealias DisplayRegionHandler = (manager : CLLocationManager, region : CLRegion, state : CLRegionState) -> Void;
    
    var delegate         : KRBeaconFinderDelegate?;
    var locationManager  : CLLocationManager!; //一定會有值
    var foundBeacons     : AnyObject[] = []
    {
        willSet(a)
        {
            //...
        }
        didSet
        {
            //...
        }
    };
    var rangedRegions    : AnyObject[]
    {
        get
        {
            if let _manager = locationManager
            {
                return locationManager.rangedRegions.allObjects;
            }
            return [];
        }
    };
    
    var monitoredRegions : AnyObject[]
    {
        get
        {
            if let _manager = locationManager
            {
                return locationManager.monitoredRegions.allObjects;
            }
            return [];
        }
    };
    
    var isRanging        : Bool!;
    var isMonitoring     : Bool!;
    
    //regions will use for ranging and monitoring more different regions of beacon.
    var regions          : CLBeaconRegion[] = [];
    var adverstingRegion : CLBeaconRegion?;
    
    var foundBeaconsHandler  : FoundBeaconsHandler?; //不一定會有值, 可給 nil
    var enterRegionHandler   : EnterRegionHandler?;
    var exitRegionHandler    : ExitRegionHandler?;
    var displayRegionHandler : DisplayRegionHandler?;
    
    var beaconCentral         : KRBeaconCentral?;
    var beaconPeripheral      : KRBeaconPeripheral?;
    var bleScanningEnumerator : KRBeaconCentral.ScanningEnumerator?
    {
        didSet
        {
            if beaconCentral
            {
                beaconCentral!.scanningEnumerator = bleScanningEnumerator;
            }
        }
    };
    
    /*
     * #pragma --mark Private Methods
     */
    //func() -> CLBeaconRegion? 代表可以回傳 nil
    func _makeBeaconRegion(uuid : String, identifier : String, major : UInt16, minor : UInt16, notifyMode : KRBeaconNotifyModes) -> CLBeaconRegion?
    {
        var _beaconRegion : CLBeaconRegion? = nil;
        let _proximityUUID : NSUUID         = NSUUID(UUIDString: uuid);
        /*
         * @ If major or minor either is zero that means nothing.
         */
        if major > 0 && minor > 0
        {
            _beaconRegion = CLBeaconRegion(
                proximityUUID: _proximityUUID,
                major: major,
                minor: minor,
                identifier: identifier
            );
        }
        else
        {
            if major > 0
            {
                _beaconRegion = CLBeaconRegion(proximityUUID: _proximityUUID, major: major, identifier: identifier);
            }
            else
            {
                _beaconRegion = CLBeaconRegion(proximityUUID: _proximityUUID, identifier: identifier);
            }
        }
        
        if let _someRegion = _beaconRegion
        {
            var _notifyDisplay : Bool = true;
            var _notifyEntry   : Bool = true;
            var _notifyExit    : Bool = true;
            switch notifyMode
            {
                case .Deny :
                    _notifyDisplay = false;
                    _notifyEntry   = false;
                    _notifyExit    = false;
                    break;
                case .OnlyDisplay :
                    _notifyEntry   = false;
                    _notifyExit    = false;
                    break;
                case .OnlyEntry :
                    _notifyDisplay = false;
                    _notifyExit    = false;
                    break;
                case .OnlyExit :
                    _notifyDisplay = false;
                    _notifyEntry   = false;
                    break;
                case .DisplayAndEntry :
                    _notifyExit    = false;
                    break;
                case .DisplayAndExit :
                    _notifyEntry   = false;
                    break;
                case .EntryAndExit :
                    _notifyDisplay = false;
                    break;
                default:
                    break;
            }
            
            _beaconRegion!.notifyEntryStateOnDisplay = _notifyDisplay;
            _beaconRegion!.notifyOnEntry             = _notifyEntry;
            _beaconRegion!.notifyOnExit              = _notifyExit;
        }
        return _beaconRegion;
    }
    
    func _buildLocationManager()
    {
        if !locationManager
        {
            locationManager                 = CLLocationManager();
            locationManager.delegate        = self;
            locationManager.activityType    = CLActivityType.Fitness;
            locationManager.distanceFilter  = kCLDistanceFilterNone;
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
    }
    
    func _fireLocalNotification(message : String, userInfo : NSDictionary?)
    {
        let notification : UILocalNotification = UILocalNotification();
        notification.alertBody                 = message;
        notification.userInfo                  = userInfo;
        //App 如運行在前台，則會直接進入本地通知的委派裡，如運行在後台，則會直接出現通知在螢幕上
        UIApplication.sharedApplication().presentLocalNotificationNow(notification);
    }
    
    func _fireLocalNotification(message : String)
    {
        _fireLocalNotification(message, userInfo: nil);
    }
    
    /*
     * #pragma --mark Public Methods
     */
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
        //如果沒有 ? 問號的變數，就一定要在這裡作初始化的動作
        super.init();
        
        delegate              = nil;
        beaconCentral         = KRBeaconCentral.sharedCentral;
        beaconPeripheral      = KRBeaconPeripheral.sharedPeripheral;
        
        foundBeacons          = [];
        isRanging             = false;
        isMonitoring          = false;
        adverstingRegion      = nil;
        
        foundBeaconsHandler   = nil;
        enterRegionHandler    = nil;
        exitRegionHandler     = nil;
        displayRegionHandler  = nil;
        bleScanningEnumerator = nil;
        
        _buildLocationManager();
    }
    
    func addRegion(beaconUuid : String, beaconIdentifier : String, beaconMajor : UInt16, beaconMinor : UInt16, notifyMode : KRBeaconNotifyModes)
    {
        if regions.isEmpty
        {
            //...
        }
        
        var _beaconRegion : CLBeaconRegion? = _makeBeaconRegion(
            beaconUuid,
            identifier : beaconIdentifier,
            major      : beaconMajor,
            minor      : beaconMinor,
            notifyMode : notifyMode
        );
        
        //if let _madeRegion = _beaconRegion
        if _beaconRegion != nil
        {
            regions.append( _beaconRegion!.copy() as CLBeaconRegion );
            _beaconRegion = nil;
        }
    }
    
    func addRegion(beaconUuid : String, beaconIdentifier : String, beaconMajor : UInt16)
    {
        addRegion(
            beaconUuid,
            beaconIdentifier: beaconIdentifier,
            beaconMajor     : beaconMajor,
            beaconMinor     : 0,
            notifyMode      : KRBeaconNotifyModes.Default
        );
    }
    
    func addRegion(beaconUuid : String, beaconIdentifier : String)
    {
        addRegion(beaconUuid, beaconIdentifier: beaconIdentifier, beaconMajor: 0);
    }
    
    func addRegion(beaconRegion : CLBeaconRegion)
    {
        if regions.isEmpty
        {
            // ...
        }
        regions.append( beaconRegion.copy() as CLBeaconRegion );
        //beaconRegion = nil;
    }
    
    func removeRegion(beaconUuid : String, beaconIdentifier : String, beaconMajor : UInt16, beaconMinor : UInt16)
    {
        if !regions.isEmpty
        {
            //如果存在就直接刪除
            //[] 沒有 containsObject 語法 T_T
            var _tempRegions = regions.copy();// as CLBeaconRegion[];
            var _index : Int = 0;
            for _everyRegion : CLBeaconRegion in _tempRegions
            {
                //如果 (NSNumber *) Major, Minor 是 nil, 則 integerValue 會是 0
                if _everyRegion.proximityUUID.UUIDString == beaconUuid  &&
                   _everyRegion.identifier == beaconIdentifier          &&
                   _everyRegion.major.unsignedShortValue == beaconMajor &&
                   _everyRegion.minor.unsignedShortValue == beaconMinor
                {
                    regions.removeAtIndex(_index);
                    locationManager.stopRangingBeaconsInRegion(_everyRegion);
                    locationManager.stopMonitoringForRegion(_everyRegion);
                    break;
                }
                ++_index;
            }
            _tempRegions.removeAll();
            _tempRegions = [];
            //_tempRegions = nil;
        }
    }
    
    func removeRegion(beaconUuid : String, beaconIdentifier : String, beaconMajor : UInt16)
    {
        removeRegion(
            beaconUuid,
            beaconIdentifier : beaconIdentifier,
            beaconMajor : beaconMajor,
            beaconMinor : 0
        );
    }
    
    func removeRegion(beaconUuid : String, beaconIdentifier : String)
    {
        removeRegion(
            beaconUuid,
            beaconIdentifier : beaconIdentifier,
            beaconMajor : 0
        );
    }
    
    func removeRegion(beaconRegion : CLBeaconRegion)
    {
        removeRegion(
            beaconRegion.proximityUUID.UUIDString,
            beaconIdentifier : beaconRegion.identifier,
            beaconMajor : beaconRegion.major.unsignedShortValue,
            beaconMinor : beaconRegion.minor.unsignedShortValue
        );
    }
    
    func createAdvertisingRegion(uuid : String, identifier : String, major : UInt16, minor : UInt16)
    {
        
    }
    
    func canRangeBeacon() -> Bool
    {
        if !locationManager
        {
            _buildLocationManager();
        }
        
        if !CLLocationManager.isRangingAvailable()
        {
            return false;
        }
        
        if regions.count < 1
        {
            return false;
        }
        
        return true;
    }
    
    /*
     * @ 開始範圍搜索多顆 Beacons
     */
    func rangingWithBeaconsFounder(founder : FoundBeaconsHandler?)
    {
        self.foundBeaconsHandler = founder;
        if canRangeBeacon()
        {
            stopRanging();
            isRanging = true;
            for _everyRegion : CLBeaconRegion in regions
            {
                locationManager.startRangingBeaconsInRegion(_everyRegion);
            }
            //取得正在監控的 Region
            //locationManager.monitoredRegions.member(_beaconRegion);
        }
    }
    
    func ranging()
    {
        rangingWithBeaconsFounder( foundBeaconsHandler );
    }
    
    /*
     * @ 停止範圍搜索多顆 Beacons
     */
    func stopRanging()
    {
        isRanging = false;
        //沒有監控的 Regions
        if locationManager.rangedRegions.count == 0
        {
            return;
        }
        
        if regions.count > 0
        {
            for _everyRegion : CLBeaconRegion in regions
            {
                locationManager.stopRangingBeaconsInRegion(_everyRegion);
            }
        }
        
        foundBeacons = [];
        //foundBeacons! = nil;
    }
    
    func canMonitorBeacon() -> Bool
    {
        if !locationManager
        {
            _buildLocationManager();
        }
        
        //Device 支援監控 BeaconRegion 的話
        //同 ![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]
        if !CLLocationManager.isMonitoringAvailableForClass( CLBeaconRegion )
        {
            return false;
        }
        
        if regions.count < 1
        {
            return false;
        }
        
        return true;
    }
    
    /*
     * @ 開始監控 Beacons
     */
    func monitoringWithDisplayHandler(handler : DisplayRegionHandler?)
    {
        self.displayRegionHandler = handler;
        if canMonitorBeacon()
        {
            stopMonitoring();
            isMonitoring = true;
            for _everyRegion : CLBeaconRegion in regions
            {
                locationManager.startMonitoringForRegion(_everyRegion);
            }
        }
    }
    
    func monitoring()
    {
        monitoringWithDisplayHandler( displayRegionHandler );
    }
    
    /*
     * @ 停止監控 Beacons
     */
    func stopMonitoring()
    {
        isMonitoring = false;
        if regions.count > 0
        {
            for _everyRegion : CLBeaconRegion in regions
            {
                locationManager.stopMonitoringForRegion(_everyRegion);
            }
        }
    }
    
    /*
     * @ 請求立即進入 locationManager:didDetermineState:forRegion: 委派方法
     *   - 如此才能在背景移除 App 並鎖屏時，收到通知 ?
     *     - Ans : 不對，這函式是立即觸發該委派方法，作用就像 [NSTimer fire] 的意思一樣，
     *             即使不執行此 requestStateForRegion 的方法，也能正確的在執行 Monitoring 時，被正確的觸發。
     */
    func requestState()
    {
        if canMonitorBeacon()
        {
            for _everyRegion : CLBeaconRegion in regions
            {
                locationManager.requestStateForRegion(_everyRegion);
                break;
            }
        }
    }
    
    /*
     * @ 喚醒鎖屏顯示
     *   - 必須在 AppDelegate 的 didFinishLaunchingWithOptions 方法裡呼叫此方法，
     *     這樣才能在背景移除 App 時，能正確收到通知。
     *
     *   - 須注意，一定要在 AppDelegate 裡啟動 [_locationManager startMonitoringForRegion:] 監控，
     *     這樣才會正確的在實作監控 iBeacons 背景移除並鎖屏的功能時，
     *     順利能進到 locationManager:didDetermineState:forRegion: 委派方法裡。
     *
     */
    func awakeDisplayWithFoundCompletion(handler : DisplayRegionHandler?)
    {
        self.displayRegionHandler = handler;
        if canMonitorBeacon()
        {
            monitoring();
            requestState();
        }
    }
    
    func awakeDisplay()
    {
        awakeDisplayWithFoundCompletion( displayRegionHandler );
    }
    
    func bleScan()
    {
        beaconCentral!.scan();
    }
    
    func bleStopScan()
    {
        beaconCentral!.stopScan();
    }
    
    func bleAdversting()
    {
        beaconPeripheral!.advertising();
    }
    
    func bleStopAdversting()
    {
        beaconPeripheral!.stopAdvertising();
    }
    
    
    func fireLocalNotification(message : String, userInfo : NSDictionary)
    {
        _fireLocalNotification(message, userInfo : userInfo);
    }
    
    func fireLocalNotification(message : String)
    {
        _fireLocalNotification(message);
    }
    
    /*
     * #pragma --mark Block Setters
     */
    /*
    func setFoundBeaconsHandler(theBlock : FoundBeaconsHandler?)
    {
        foundBeaconsHandler = theBlock;
    }
    
    func setBleScanningEnumerator(theBlock : KRBeaconCentral.ScanningEnumerator?)
    {
        bleScanningEnumerator = theBlock;
        if beaconCentral
        {
            beaconCentral!.scanningEnumerator = bleScanningEnumerator;
        }
    }
    
    func setEnterRegionHandler(theBlock : EnterRegionHandler?)
    {
        enterRegionHandler = theBlock;
    }
    
    func setExitRegionHandler(theBlock : ExitRegionHandler?)
    {
        exitRegionHandler = theBlock;
    }
    
    func setDisplayRegionHandler(theBlock : DisplayRegionHandler?)
    {
        displayRegionHandler = theBlock;
    }
    */
    
    /*
     * #pragma --mark Beacon ranging delegate methods
     */
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
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
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!)
    {
        println("beacons 1 \(beacons)");
        /*
        * @ Noted
        *   - 收到的 CLBeacon 訊息
        *     CLBeacon (uuid:<__NSConcreteUUID 0x146c6c80> B9407F30-F5F8-466E-AFF9-25556B57FE6D,
        *               major:18527,
        *               minor:23618,
        *               proximity:1 +/- 0.07m,
        *               rssi:-53)
        *
        *   - uuid      是 Apple Certificated Beacon ID，不同於 Device UUID
        *   - major     是 該 Beacons 群組 ID，當接收到 uuid 判斷為可以作動的 Beacons 後，就依照 major 來判斷是要做什麼類型的事情 ( major likes category #. )
        *   - minor     是 該 Beacons 群組底下，每一顆 Beacon 可以做什麼事情的判斷 ID ( use the minor number to do what you do. )
        *   - accuracy  會顯示目前 Beacon 離 iPhone 多遠，單位是公尺( meter )，not proximity
        *   - rssi      會顯示目前的訊號強度，越近則越大，越遠則越小，範圍從 -43 ~ -94 以內為可信區域 ( trust scopes )
        *
        */
        
        foundBeacons = beacons;
        if self.foundBeaconsHandler
        {
            foundBeaconsHandler!(foundBeacons : foundBeacons, beaconRegion : region);
        }
    }
    
    //When app enters the monitored iBeacon scope happen.
    //當 iBeacons 進入區域時
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!)
    {
        if self.enterRegionHandler
        {
            enterRegionHandler!(manager : manager, region : region);
        }
    }
    
    //When app exited the monitored iBeacon scope happen.
    //當 iBeacons 離開區域時
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!)
    {
        if self.exitRegionHandler
        {
            exitRegionHandler!(manager : manager, region : region);
        }
    }
    
    /*
     * A user can transition in or out of a region while the application is not running. When this happens CoreLocation will launch the application momentarily, call this delegate method and we will let the user know via a local notification.
     *
     * 用戶可以在應用程序沒有運行或縮小一個區域的時，CoreLocation 將啟動應用程序瞬間調用此委託的方法，將通過本地通知讓用戶知道，包含鎖屏時也能收到通知。
     *
     */
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!)
    {
        if self.delegate
        {
            //func krBeaconFinderDidDetermineState(beaconFinder : KRBeaconFinder, state : CLRegionState, region : CLRegion);
            
            if delegate!.respondsToSelector( Selector("krBeaconFinderDidDetermineState:state:region:") )
            {
                //因為它是 @optional 的
                delegate!.krBeaconFinderDidDetermineState!(self, state : state, region : region);
            }
        }
        
        if( self.displayRegionHandler )
        {
            displayRegionHandler!(manager : manager, region : region, state : state);
        }
    }
    
}



