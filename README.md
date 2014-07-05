## About

This KRBeaconFinder supports iOS 8 swift to lazy scanning beacons, relax using CoreLocation to monitor beacon-regions or use CoreBluetooth (BLE) to scan. It also can simulate beacon adversting from peripheral adversting.

More Information see the souce code, any questions you can email me or leave the messages to discussion to help more people.

## How To Get Started

#### You can use KRBeaconOne to find and monitor only one iBeacon.

``` objective-c
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
```

## Version

V1.0.

## License

MIT.
