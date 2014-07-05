//
//  ViewController.swift
//  KRBeaconFinder
//
//  Created by Kalvar on 2014/6/22.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var beaconFinder    : KRBeaconOne!;
    var detectedBeacons : AnyObject[] = [];
    @IBOutlet var tableView          : UITableView;
    @IBOutlet var advertisingSwitch  : UISwitch;
    @IBOutlet var rangingSwitch      : UISwitch;
    @IBOutlet var bleScanningSwitchs : UISwitch;
    
    @IBAction func changeAdvertisingState(sender : AnyObject)
    {
        let theSwitch : UISwitch = sender as UISwitch;
        if theSwitch.on
        {
            beaconFinder.bleAdversting();
        }
        else
        {
            beaconFinder.bleStopAdversting();
        }
    }
    
    @IBAction func changeRangingState(sender : AnyObject)
    {
        let theSwitch : UISwitch = sender as UISwitch;
        if theSwitch.on
        {
            beaconFinder.ranging();
            //beaconFinder.monitoring();
        }
        else
        {
            beaconFinder.stopRanging();
            //beaconFinder.stopMonitoring();
        }
    }
    
    @IBAction func changeScanningState(sender : AnyObject)
    {
        let theSwitch : UISwitch = sender as UISwitch;
        if theSwitch.on
        {
            beaconFinder.bleScan();
        }
        else
        {
            beaconFinder.bleStopScan();
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        //Let's get start in Beacons coding ...
        //建立要讓 App 發廣播的 BeaconRegion, 這能讓 iPhone 變成客製化的 iBeacon
        //Build the beacon region of advertising within use app which can be customized iBeacon.
        /*
        beaconFinder = KRBeaconFinder.sharedFinder;
        beaconFinder.createAdvertisingRegion(
            Uuid       : "B9407F30-F5F8-466E-AFF9-25556B57FE6D",
            identifier : "com.kalvar.ibeacons",
            major      : 55000,
            minor      : 65000);
        */
        
        beaconFinder              = KRBeaconOne.sharedFinder;
        
        //beaconFinder.uuid       = "B9407F30-F5F8-466E-AFF9-25556B57FE6D";
        //beaconFinder.identifier = "com.kalvar.ibeacons";
        
        beaconFinder.foundBeaconsHandler = {foundBeacons, beaconRegion in
            self.detectedBeacons = foundBeacons;
            self.tableView.reloadData();
        };
        
        beaconFinder.bleScanningEnumerator = {peripheral, advertisements, RSSI in
            println("The advertisement with identifer: \(peripheral.identifier), " +
                    "state: \(peripheral.state), " +
                    "name: \(peripheral.name), " +
                    "services: \(peripheral.services), " +
                    "description: \(advertisements.description)");
        };
        
        beaconFinder.enterRegionHandler = {manager, region in
            self.beaconFinder.fireLocalNotification("Enter region notification", userInfo : ["key" : "doShareToPeople"]);
        }
        
        beaconFinder.exitRegionHandler = {manager, region in
            self.beaconFinder.fireLocalNotification("Exit region notification");
        };
        
        /*
        //It works without write in AppDelegate, but you must be uniform integration the processing and coding-style in one scope.
        beaconFinder.displayRegionHandler = {manager, region, state in
            if state == CLRegionState.Inside
            {
                self.beaconFinder.fireLocalNotification("You're inside the beacon region 2");
            }
            else if state == CLRegionState.Outside
            {
                self.beaconFinder.fireLocalNotification("You're outside the beacon region 2");
            }
            else
            {
                return;
            }
        };
        */
        
        /*
        //It works for watching more iBeacons.
        KRBeaconFinder.sharedFinder.addRegion("A9407F30-F5F8-466E-AFF9-25556B57FE6D", identifier : "com.kalvar.ibeacons1");
        KRBeaconFinder.sharedFinder.addRegion("B9407F30-F5F8-466E-AFF9-25556B57FE6D", identifier : "com.kalvar.ibeacons2");
        KRBeaconFinder.sharedFinder.addRegion("C9407F30-F5F8-466E-AFF9-25556B57FE6D", identifier : "com.kalvar.ibeacons3");
        KRBeaconFinder.sharedFinder.ranging();
        KRBeaconFinder.sharedFinder.monitoring();
        */
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning();
    }
    
    func removeRegionSample()
    {
        //It'll remove all beacons from matched the UUID and Identifier.
        beaconFinder.removeRegion(beaconUuid : "B9407F30-F5F8-466E-AFF9-25556B57FE6D", beaconIdentifier : "com.kalvar.ibeacons");
        
        //It'll remove all beacons from matched the UUID, Identifier and Major.
        beaconFinder.removeRegion(beaconUuid : "B9407F30-F5F8-466E-AFF9-25556B57FE6D", beaconIdentifier : "com.kalvar.ibeacons", beaconMajor : 2540);
        
        //It'll remove all beacons from matched the UUID, Identifier, Major and Minor.
        beaconFinder.removeRegion(beaconUuid : "B9407F30-F5F8-466E-AFF9-25556B57FE6D", beaconIdentifier : "com.kalvar.ibeacons", beaconMajor : 2540, beaconMinor : 1028);
        
        //It'll remove the specified region.
        let beaconRegion : CLBeaconRegion = CLBeaconRegion(proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", identifier: "com.kalvar.ibeacons");
        beaconFinder.removeRegion( beaconRegion );
    }
    
    /*
     * !
     * @ UITableViewDelegate
     */
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int
    {
        return 1;
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return detectedBeacons.count;
    }
    
    func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String!
    {
        return "Detected beacons";
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let defaultCell : UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "BeaconCells");
        let beacon      : CLBeacon        = self.detectedBeacons[indexPath.row] as CLBeacon;
        defaultCell.textLabel.text        = beacon.proximityUUID.UUIDString;
        /*
        * @ Noted
        *   - 收到的 Beacon 訊息
        *     CLBeacon (uuid:<__NSConcreteUUID 0x146c6c80> B9407F30-F5F8-466E-AFF9-25556B57FE6D,
        *               major:18527,
        *               minor:23618,
        *               proximity:1 +/- 0.07m,
        *               rssi:-53)
        *
        *   - uuid      是 Apple Certificated Beacon ID，不同於 Device UUID
        *   - major     是 該 Beacons 群組 ID，當接收到 uuid 判斷為可以作動的 Beacons 後，就依照 major 來判斷是要做什麼類型的事情
        *   - minor     是 該 Beacons 群組底下，每一顆 Beacon 可以做什麼事情的判斷 ID
        *   - accuracy  會顯示目前 Beacon 離 iPhone 多遠，單位是公尺( meter ), not proximity
        *   - rssi      會顯示目前的訊號強度，越近則越大，越遠則越小，範圍從 -43 ~ -94 以內為可信區域
        *
        */
        var proximityString : String = "";
        switch beacon.proximity
        {
            case CLProximity.Immediate:
                //~ 50 cm
                proximityString = "Immediate";
                break;
            case CLProximity.Near:
                //~ 2 m
                proximityString = "Near";
                break;
            case CLProximity.Far:
                //~ 30 m
                proximityString = "Far";
                break;
            case CLProximity.Unknown:
                fallthrough;
            default:
                proximityString = "Unknown";
                break;
        }
        
        //beacon.rssi = Int
        defaultCell.detailTextLabel.text = beacon.major.stringValue + ", " + beacon.minor.stringValue + " • " + proximityString + " • " + String(beacon.accuracy) + " • " + String(beacon.rssi);
        
        defaultCell.detailTextLabel.textColor = UIColor.grayColor();
        
        return defaultCell;
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath!, animated: true);
        let beacon : CLBeacon = self.detectedBeacons[indexPath.row] as CLBeacon;
        switch beacon.major.unsignedIntegerValue
        {
            //Something wanna do with major.
            case 18527:
                //...
                break;
            default:
                break;
        }
    }
    
}






