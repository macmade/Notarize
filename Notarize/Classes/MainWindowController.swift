/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2018 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa

class MainWindowController: NSWindowController
{
    @IBOutlet private var accountsController:   NSArrayController!
    @IBOutlet private var historyViewContainer: NSView!
    
    private var add:          AccountWindowController?           = nil
    private var observations: [ NSKeyValueObservation ]          = []
    private var controllers:  [ String : HistoryViewController ] = [ : ]
    
    @objc private dynamic var controller:        HistoryViewController?
    @objc private dynamic var accounts:          [ Account ] = []
    @objc private dynamic var altoolIsAvailable: Bool        = true
    
    override var windowNibName: NSNib.Name?
    {
        return NSStringFromClass( type( of: self ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.altoolIsAvailable = ALTool.isAvailable()
        self.accounts          = Preferences.shared.getAccounts()
        
        let o1 = Preferences.shared.observe( \.accounts )
        {
            o, c in self.accounts = Preferences.shared.getAccounts()
        }
        
        let o2 = self.accountsController.observe( \.selection )
        {
            o, c in
            
            self.controller = nil
            
            self.historyViewContainer.subviews.forEach
            {
                v in v.removeFromSuperview()
            }
            
            guard let account = self.accountsController.selectedObjects.first as? Account else
            {
                return
            }
            
            if self.controllers[ account.username ] == nil
            {
                self.controllers[ account.username ] = HistoryViewController( account: account )
                
                self.controllers[ account.username ]?.refresh( nil )
            }
            
            guard let controller = self.controllers[ account.username ] else
            {
                return
            }
            
            self.controller       = controller
            controller.view.frame = self.historyViewContainer.bounds
            
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.historyViewContainer.addSubview( controller.view )
            self.historyViewContainer.addConstraint( NSLayoutConstraint( item: controller.view, attribute: .width,   relatedBy: .equal, toItem: self.historyViewContainer, attribute: .width,   multiplier: 1, constant: 0 ) )
            self.historyViewContainer.addConstraint( NSLayoutConstraint( item: controller.view, attribute: .height,  relatedBy: .equal, toItem: self.historyViewContainer, attribute: .height,  multiplier: 1, constant: 0 ) )
            self.historyViewContainer.addConstraint( NSLayoutConstraint( item: controller.view, attribute: .centerX, relatedBy: .equal, toItem: self.historyViewContainer, attribute: .centerX, multiplier: 1, constant: 0 ) )
            self.historyViewContainer.addConstraint( NSLayoutConstraint( item: controller.view, attribute: .centerY, relatedBy: .equal, toItem: self.historyViewContainer, attribute: .centerY, multiplier: 1, constant: 0 ) )
        }
        
        self.observations.append( contentsOf: [ o1, o2 ] )
        
        self.accountsController.sortDescriptors = [ NSSortDescriptor( key: "username", ascending: true ) ]
    }
    
    @IBAction func refresh( _ sender: Any? )
    {
        guard let account    = self.accountsController.selectedObjects.first as? Account,
              let controller = self.controllers[ account.username ]
        else
        {
            return
        }
        
        controller.refresh( sender )
    }
    
    @IBAction func addAccount( _ sender: Any? )
    {
        if self.add != nil
        {
            return
        }
        
        self.add = AccountWindowController()
        
        guard let sheet = self.add?.window else
        {
            return
        }
        
        self.window?.beginSheet( sheet )
        {
            r in
            
            guard let add = self.add else
            {
                return
            }
            
            self.add = nil
            
            if r != .OK
            {
                return
            }
            
            if( add.username.count == 0 || add.password.count == 0 )
            {
                return
            }
            
            let account = Account( username: add.username, password: add.password, useKeychain: add.keepInKeychain )
            
            Preferences.shared.addAccount( account );
        }
    }
    
    @IBAction func removeAccount( _ sender: Any? )
    {
        guard let account = self.accountsController.selectedObjects.first as? Account,
              let window = self.window
        else
        {
            return
        }
        
        let alert = NSAlert()
        
        alert.messageText     = "Delete Account"
        alert.informativeText = "Are you sure you want to delete this account?"
        
        alert.addButton( withTitle: "Delete" )
        alert.addButton( withTitle: "Cancel" )
        
        alert.beginSheetModal( for: window )
        {
            r in
            
            if r != .alertFirstButtonReturn
            {
                return
            }
            
            Preferences.shared.removeAccount( account )
        }
    }
}

