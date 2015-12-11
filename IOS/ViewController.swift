import UIKit

//Single View

//need to add CoreBluetooth.framework in "Linked Frameworks and libraries"
import CoreBluetooth

//ref http://qiita.com/shu223/items/78614325ce25bf7f4379
//rfduino haracteristic UUID: "2221 - Read, 2222 - Write
//maybe transform onece data max size is 256 byte

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var readComp: Bool!
    var writeComp: Bool!
    
    
    let serviceUUIDs:[CBUUID] = [CBUUID(string: "9a444680-9fd8-11e5-8994-feff819cdc9f")]
    
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var receiveView: UITextView!
    @IBOutlet weak var sendTextField: UITextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.readComp = true
        self.writeComp = true
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // IOS go to hear rfduino
        //_ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("ReceiveTimer"), userInfo: nil, repeats: true)
    }
    
    ////////////////////////////////////////////////////////////////////////
    /// Write Action
    @IBAction func PushSendButton(sender: UIButton)
    {
        if(self.writeComp == true && self.peripheral.state == CBPeripheralState.Connected)
        {
            writeComp = false
            let data: NSData! = sendTextField.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            
            print(data)
            
            if(self.peripheral.services != nil)
            {
                if(self.peripheral.services![0].characteristics != nil)
                {
            
            peripheral .writeValue(data, forCharacteristic: self.peripheral.services![0].characteristics![1], type: CBCharacteristicWriteType.WithResponse)
                }
            }
        }
    }
  
    
    //after write
    func peripheral(peripheral: CBPeripheral,
        didWriteValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if (error != nil)
        {
            print("Write失敗...error: \(error)")
            return
        }
        
        print("Write成功！")
        writeComp = true
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //read on timer  ( not used )
    func ReceiveTimer()
    {
        if(self.peripheral.state == CBPeripheralState.Connected && self.readComp == true)
        {
            self.readComp = false;
             //use first characteristics    
            
            if(self.peripheral.services != nil)
            {
                if(self.peripheral.services![0].characteristics != nil)
                {
                    self.peripheral.readValueForCharacteristic(self.peripheral.services![0].characteristics![0])
                }
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    func centralManagerDidUpdateState(central: CBCentralManager)
    {
        print("state: \(central.state)")
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Connect Init Action
    // scan device -> connect device -> search service -> search Characteristics -> set notify from rfduino
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @IBAction func PushConnectButton(sender: UIButton)
    {
        if(self.centralManager.state == CBCentralManagerState.PoweredOn)
        {
            if(connectButton.titleLabel!.text == "Connect")
            {
                self.centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: nil)
            }
            else
            {
                self.centralManager.cancelPeripheralConnection(self.peripheral)
                connectButton.setTitle("Connect", forState: .Normal)
            }
        }
    }
    
    
    //result after scan
    func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
       // print("peripheral:" + peripheral.description);
        if(peripheral.name != nil)
        {
            print(peripheral.name)
            self.peripheral = peripheral
            if(self.peripheral.state == CBPeripheralState.Disconnected)
            {
                self.centralManager.connectPeripheral(self.peripheral, options: nil);
            }
            self.centralManager.stopScan()
        
        }
    }
    
    
    //Connect OK
    func centralManager(central: CBCentralManager,
        didConnectPeripheral peripheral: CBPeripheral)
    {
        print("connected!")
        
        //Search service
        self.peripheral.delegate = self;
        self.peripheral.discoverServices(nil)
    }
    
    //Connect Fail
    func centralManager(central: CBCentralManager,
        didFailToConnectPeripheral peripheral: CBPeripheral,
        error: NSError?)
    {
        print("failed...")
        connectButton.setTitle("Fail", forState: .Normal);
    }
    
    //result after search service
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?)
    {
        if (error != nil) {
            print("error: \(error)")
            return
        }
        
        if !(peripheral.services?.count > 0) {
            print("no services")
            return
        }
        
        let services = peripheral.services!
        print("Found \(services.count) services! :\(services)")
        
        //use first service
        //search characteristics
        if(peripheral.services?.count > 0)
        {
            self.peripheral.discoverCharacteristics(nil, forService: self.peripheral.services![0])
        }
    }
    
    //result after search characteristics
    func peripheral(peripheral: CBPeripheral,
        didDiscoverCharacteristicsForService service: CBService,
        error: NSError?)
    {
        if (error != nil) {
            print("error: \(error)")
            return
        }
        
        if !(service.characteristics?.count > 0) {
            print("no characteristics")
            return
        }
        
        let characteristics = service.characteristics!
        print("Found \(characteristics.count) characteristics! : \(characteristics)")
        
        if (service.characteristics?.count > 0)
        {
            connectButton.setTitle("Disconnect", forState: .Normal)
            self.receiveView.text = ""
            self.peripheral.setNotifyValue(true, forCharacteristic: characteristics[0])
            //                            false is stop notify
        }
    }
    
    //after notify start and stop
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        if(error != nil)
        {
            
        }
    }
    
    //notify result and read result
    //after read end
    func peripheral(peripheral: CBPeripheral,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if (error != nil)
        {
            print("Failed... error: \(error)")
            return
        }
        
        /*
        var byte: CUnsignedChar = 0
        characteristic.value?.getBytes(&byte, length: 1)
        print("get 1 byte is %d", (byte))
        */
        
        let v = characteristic.value?.description;
        if(v != nil)
        {
            print("Succeeded! service uuid: \(characteristic.service.UUID), characteristic uuid: \(characteristic.UUID), value: \(characteristic.value?.description)")
            print(v);
            receiveView.text = receiveView.text + v!
            if(receiveView.text.characters.count > 50)
            {
                receiveView.text! = "";
            }
        }
        readComp = true;
    }
}