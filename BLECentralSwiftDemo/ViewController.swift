//
//  ViewController.swift
//  BLECentralSwiftDemo
//
//  Created by Hiago Santos Martins Dias on 17/02/23.
//

import UIKit

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let SERVICE_UUID = "CDD1"
    let CHARACTERISTIC_UUID = "CDD2"
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Bluetooth central device"
        // Create a central manager and set its delegate to this view controller
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    @IBAction func readButtonTapped(_ sender: Any) {
        if let characteristic = characteristic {
            peripheral?.readValue(for: characteristic)
        }
    }
    
    @IBAction func writeButtonTapped(_ sender: Any) {
        guard let characteristic = characteristic, let text = textField.text else { return }
        let data = text.data(using: .utf8)!
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Bluetooth is available, start scanning for peripherals
        if central.state == .poweredOn {
            print("Bluetooth available")
            // Scan for peripherals with the specified service UUID
            central.scanForPeripherals(withServices: [CBUUID(string: SERVICE_UUID)], options: nil)
        } else if central.state == .unsupported {
            print("This device does not support Bluetooth")
        } else if central.state == .poweredOff {
            print("Bluetooth is off")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Save a reference to the discovered peripheral
        self.peripheral = peripheral
        // Connect to the peripheral
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Stop scanning
        central.stopScan()
        // Set the peripheral's delegate to this view controller
        peripheral.delegate = self
        // Discover the services of the peripheral
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])
        print("Connected to peripheral: \(peripheral.name ?? "")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "")")
        // Try to reconnect to the peripheral
        central.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        // Loop through the discovered services and find the characteristic we need
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_UUID)], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        // Loop through the discovered characteristics and find the characteristic we need
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            if characteristic.uuid == CBUUID(string: CHARACTERISTIC_UUID) {
                // Save a reference to the characteristic we need
                self.characteristic = characteristic
                // Read the initial value of the characteristic
                peripheral.readValue(for: characteristic)
                // Subscribe to updates to the characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        // Handle the updated characteristic value
        if characteristic.uuid == CBUUID(string: CHARACTERISTIC_UUID) {
            if let value = characteristic.value, let string = String(data: value, encoding: .utf8) {
                print("Received characteristic value: \(string)")
                // Update the text field with the received value
                DispatchQueue.main.async {
                    self.textField.text = string
                }
            }
        }
    }

    
    

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic value: \(error.localizedDescription)")
            return
        }
        print("Characteristic value written successfully")
    }

}

