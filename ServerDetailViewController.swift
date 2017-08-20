//
//  ServerDetailViewController.swift
//  MusicSync
//
//  Created by nils on 25.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData
import Validator

class ServerDetailViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    var server: Server?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    enum ValidationErrors: String, Error {
        case addressRequired = "Address is required"
        case nameRequired = "Name is required"
        case portRequired = "Port is required"
        case portInvalid = "Not a valid port"
        
        var message: String { return self.rawValue }
    }
    
    var errors = [UIView: Error]()
    
    @IBOutlet weak var protocolPicker: UIPickerView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var addressRules = ValidationRuleSet<String>()
        addressRules.add(rule: ValidationRuleCondition<String>(error: ValidationErrors.addressRequired, condition: isNotEmpty(input:)))
        addressField.validationRules = addressRules
        
        var nameRules = ValidationRuleSet<String>()
        nameRules.add(rule: ValidationRuleCondition<String>(error: ValidationErrors.nameRequired, condition: isNotEmpty(input:)))
        nameField.validationRules = nameRules
        
        var portRules = ValidationRuleSet<String>()
        portRules.add(rule: ValidationRuleCondition<String>(error: ValidationErrors.portRequired, condition: isNotEmpty(input:)))
        portRules.add(rule: ValidationRuleCondition<String>(error: ValidationErrors.portInvalid) {
            input in
            if let i = input, let port = Int(i), port >= 0, port <= 65535 {
                return true
            }
            return false
        })
        portField.validationRules = portRules
        
            
        nameField.validationHandler = {
            return self.validate(result: $0, view: self.nameField)
        }
        portField.validationHandler  = {
            return self.validate(result: $0, view: self.portField)
        }
        addressField.validationHandler  = {
            return self.validate(result: $0, view: self.addressField)
        }
        nameField.validateOnInputChange(enabled: true)
        portField.validateOnInputChange(enabled: true)
        addressField.validateOnInputChange(enabled: true)
        
        protocolPicker.dataSource = self
        protocolPicker.delegate = self
        
        if let s = server {
            nameField.text = s.name
            portField.text = String(s.port)
            addressField.text = s.url
            if (s.prot == .Https) {
                protocolPicker.selectRow(1, inComponent: 0, animated: false)
            } else {
                protocolPicker.selectRow(0, inComponent: 0, animated: false)
            }
            doneButton.isEnabled = true
        }
        //some test data
        else {
            nameField.text = "test"
            portField.text = "8080"
            addressField.text = "sterny1337.ddns.net"
            protocolPicker.selectRow(1, inComponent: 0, animated: false)
            doneButton.isEnabled = true
        }
    }
    
    func isNotEmpty(input: String?) -> Bool{
        if let s = input, s != "" {
            return true
        }
        return false
    }
    
    func validate(result: ValidationResult, view: UIView) {
        switch (result) {
        case .valid:
            errors.removeValue(forKey: view)
            if (errors.isEmpty) {
                doneButton.isEnabled = true
            }
            break
        case .invalid(let viewErrors):
            errors.updateValue(viewErrors[0], forKey: view)
            doneButton.isEnabled = false
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard component == 0 else {
            return nil
        }
        switch(row) {
        case 0: return "HTTP"
        case 1: return "HTTPS"
        default: return nil
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    /*@IBAction func unwindToServers(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        server!.name = nameField.text
        server!.url = addressField.text
        server!.port = Int16(portField.text!)!
        
        appDelegate.saveContext()
    }*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
