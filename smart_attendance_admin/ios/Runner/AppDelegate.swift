import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var bleAdvertiser: BleAdvertiser?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let bleChannel = FlutterMethodChannel(name: "smart_attendance/ble_advertiser",
                                              binaryMessenger: controller.binaryMessenger)
        
        bleAdvertiser = BleAdvertiser()
        
        bleChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            switch call.method {
            case "startAdvertising":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uuid = args["uuid"] as? String {
                    let success = self.bleAdvertiser?.startAdvertising(uuidString: uuid) ?? false
                    result(success)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT",
                                      message: "UUID is required",
                                      details: nil))
                }
                
            case "stopAdvertising":
                self.bleAdvertiser?.stopAdvertising()
                result(true)
                
            case "isAdvertisingSupported":
                let supported = self.bleAdvertiser?.isAdvertisingSupported() ?? false
                result(supported)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
