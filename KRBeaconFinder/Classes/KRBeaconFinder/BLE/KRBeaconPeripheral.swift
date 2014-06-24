//
//  KRBeaconPeripheral.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import CoreBluetooth
import CoreLocation

class KRBeaconPeripheral : NSObject, CBPeripheralManagerDelegate
{
    var peripheralManager : CBPeripheralManager?;
    //會在 BeaconFinder / BeaconOne 裡設定 beaconRegion
    var beaconRegion      : CLBeaconRegion?;
    
    /*
     * #pragma --mark Private Methods
     */
    func _buildBeaconPeripheralData() -> NSDictionary
    {
        //在這裡一定要初始化
        //time_t = Int = CLong
        var t : time_t = 0;
        //time(&t) 是回傳 Int
        //srand() 要傳入 UInt32
        //所以得先取出 Int 再轉成 UInt32
        var timesrandInt    : Int    = time(&t) as Int;
        var timesrandUInt32 : UInt32 = UInt32( timesrandInt ); //Not works this : timesrandInt as UInt32
        srand( timesrandUInt32 );
        
        let uuid       : NSUUID = self.beaconRegion!.proximityUUID;
        let identifier : String = self.beaconRegion!.identifier;
        let major      : UInt16 = UInt16( rand() ); //CLBeaconMajorValue = UInt16
        let minor      : UInt16 = UInt16( rand() );
        
        let region : CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: identifier);
        
        return region.peripheralDataWithMeasuredPower(nil);
    }
    
    /*
     * #pragma mark - Public methods
     */
    class var sharedPeripheral : KRBeaconPeripheral
    {
        struct Singleton
        {
            static let instance : KRBeaconPeripheral = KRBeaconPeripheral();
        }
        return Singleton.instance;
    }
    
    init()
    {
        super.init();
        peripheralManager = nil;
        beaconRegion      = nil;
    }
    
    func advertising()
    {
        //if beaconRegion == nil
        if !beaconRegion
        {
            return;
        }
        
        if !peripheralManager
        {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil);
        }
        
        if peripheralManager!.state != CBPeripheralManagerState.PoweredOn
        {
            return;
        }
        
        peripheralManager!.startAdvertising( _buildBeaconPeripheralData() );
    }
    
    func stopAdvertising()
    {
        peripheralManager!.stopAdvertising();
    }
    
    /*
     * #pragma mark - Beacon advertising delegate methods
     */
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!)
    {
        if let someError = error
        {
            return;
        }
        
        if peripheralManager!.isAdvertising
        {
            //...
        }
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!)
    {
        if peripheralManager!.state != CBPeripheralManagerState.PoweredOn
        {
            return;
        }
        
        advertising();
    }
    
}

