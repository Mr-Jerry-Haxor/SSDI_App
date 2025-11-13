import Flutter
import CoreBluetooth

class BleAdvertiser: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    private var advertisingUUID: CBUUID?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(uuidString: String) -> Bool {
        guard let uuid = UUID(uuidString: uuidString) else {
            print("Invalid UUID string")
            return false
        }
        
        advertisingUUID = CBUUID(nsuuid: uuid)
        
        if peripheralManager?.state == .poweredOn {
            let advertisementData: [String: Any] = [
                CBAdvertisementDataServiceUUIDsKey: [advertisingUUID!],
                CBAdvertisementDataLocalNameKey: ""
            ]
            
            peripheralManager?.startAdvertising(advertisementData)
            print("✅ iOS BLE Advertising started for UUID: \(uuidString)")
            return true
        } else {
            print("❌ Bluetooth is not powered on")
            return false
        }
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        print("🛑 iOS BLE Advertising stopped")
    }
    
    func isAdvertisingSupported() -> Bool {
        return peripheralManager?.state == .poweredOn
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unsupported:
            print("Bluetooth is not supported")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown bluetooth state")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("❌ Failed to start advertising: \(error.localizedDescription)")
        } else {
            print("✅ Successfully started advertising")
        }
    }
}
