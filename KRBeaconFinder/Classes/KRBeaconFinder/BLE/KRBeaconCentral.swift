//
//  KRBeaconCentral.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import CoreBluetooth

class KRBeaconCentral : NSObject, CBCentralManagerDelegate
{
    //typealias ScanningEnumerator = (peripheral: CBPeripheral, advertisements: Dictionary<String, Any>, RSSI: NSNumber) -> Void;
    typealias ScanningEnumerator = (peripheral: CBPeripheral, advertisements: NSDictionary, RSSI: NSNumber) -> Void;
    
    var centralManager     : CBCentralManager?;
    var peripheral         : CBPeripheral?;
    var scanningEnumerator : ScanningEnumerator?;
    
    class var sharedCentral : KRBeaconCentral
    {
        struct Singleton
        {
            static let instance : KRBeaconCentral = KRBeaconCentral();
        }
        return Singleton.instance;
    }
    
    init()
    {
        //在預設的 init 這裡，一定要跑這行
        super.init();
        let _centralQueue : dispatch_queue_t! = dispatch_queue_create("CentralManagerQueue", DISPATCH_QUEUE_SERIAL);
        centralManager     = CBCentralManager(delegate: self, queue: _centralQueue);
        peripheral         = nil;
        scanningEnumerator = nil;
        /*
         * @ 筆記
         *   - 如果一開始在 var centralManager : CBCentralManager; 沒有給定 CBCentralManager? 問號( Wrap, 封包, 初始不配記憶體 )的話，
         *     下面的寫法就不用加 ! ( Unwrap, 拆包, 取出被封起來包裡的值 ) 來設定 delegate。
         *
         */
        //self.centralManager!.delegate = self;
    }
    
    /*
     * #pragma --mark Public Methods
     */
    func scanWithEnumerator(_enumerator: ScanningEnumerator)
    {
        scanningEnumerator = _enumerator;
        scan();
    }
    
    func scan()
    {
        stopScan();
        //用 Dictionary<String, Any> 會 Crash
        let options : NSDictionary = [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber.numberWithBool(true)];
        centralManager!.scanForPeripheralsWithServices(nil, options: options);
    }
    
    func stopScan()
    {
        centralManager!.stopScan();
    }
    
    /*
     * @ CentralManagerDelegate
     */
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        /*
         * @ 筆記
         *   - 如果是這樣的 enum struct :
         *
                    enum CBCentralManagerState : Int {
                        case Unknown
                        case Resetting
                        case Unsupported
                        case Unauthorized
                        case PoweredOff
                        case PoweredOn
                    }
         *
         *     就必須用這模式取用值 ( 跟 Obj-C 時代的 typedef enum 不一樣 ) :
         *
         *          CBCentralManagerState.Unknown
         *          CBCentralManagerState.PoweredOn
         *
         *     舉個例 : 
         *
         *          let state : CBCentralManagerState = CBCentralManagerState.Unknown;
         *
         *          之後進入 Switch 要這麼用 :
         *
                    switch state{
                        //用法 1
                        case CBCentralManagerState.Unknown:
                            //... Do Something
        
                        //用法 2
                        case .PoweredOn:
                            //... Do Something
        
                        default:
                            break;
                    }
         *
         */
        //state 的型態為 CBCentralManagerState
        switch central.state
        {
            //同這用法 CBCentralManagerState.PoweredOn
            case .PoweredOn:
                //Kalvar : 別把 Scan 寫在這裡, 直接使用 Scan 的函式即可
                //println("PoweredOn");
                break;
            default:
                break;
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: NSDictionary!, RSSI: NSNumber!)
    {
        //println("advertisementData : \(advertisementData)");
        if( scanningEnumerator )
        {
            scanningEnumerator!(peripheral: peripheral, advertisements: advertisementData, RSSI: RSSI);
        }
        
        //Beacons 是不能被連線的，所以就不用做連線
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!)
    {
        //...
    }
    
}

