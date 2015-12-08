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
    var connected: Bool!
    var readComp: Bool!
    var writeComp: Bool!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var receiveView: UITextView!
    @IBOutlet weak var sendTextField: UITextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.connected = false
        self.readComp = true
        self.writeComp = true
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("ReceiveTimer"), userInfo: nil, repeats: true)
    }
    
    @IBAction func PushSendButton(sender: UIButton)
    {
        if(self.writeComp == true && self.connected == true)
        {
            writeComp = false
            let data: NSData! = sendTextField.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            
            print(data)
            peripheral .writeValue(data, forCharacteristic: self.peripheral.services![0].characteristics![1], type: CBCharacteristicWriteType.WithResponse)
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
    
    
    
    //read on timer
    func ReceiveTimer()
    {
        if(self.connected == true && self.readComp == true)
        {
            self.readComp = false;
             //use first characteristics            
            self.peripheral.readValueForCharacteristic(self.peripheral.services![0].characteristics![0])
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager)
    {
        print("state: \(central.state)")
    }
    
    
    
    @IBAction func PushConnectButton(sender: UIButton)
    {
        self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    
    
    
    
    
    //result after scan
    func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
        print("peripheral:" + peripheral.description);
        if(peripheral.name! == "myRFduino")
        {
            self.peripheral = peripheral;
            if(self.peripheral.state == CBPeripheralState.Disconnected)
            {
                self.centralManager.connectPeripheral(self.peripheral, options: nil);
            }
            
            /*
            else if(self.peripheral.state ==
                CBPeripheralState.Connected)
            {

            }
            */
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
           self.connected = true
           connectButton.setTitle("OK", forState: .Normal)
           self.receiveView.text = ""
        }
    }
    
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
        
        print("Succeeded! service uuid: \(characteristic.service.UUID), characteristic uuid: \(characteristic.UUID), value: \(characteristic.value?.description)")
       
        let v = characteristic.value?.description;
        print(v);
        receiveView.text = receiveView.text + v!
        
        if(receiveView.text.characters.count > 50)
        {
            receiveView.text! = "";
        }
        readComp = true;
    }
}