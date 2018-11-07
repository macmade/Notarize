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

class HistoryViewController: NSViewController
{
    @IBOutlet private var itemsController: NSArrayController!
    
    @objc private dynamic var loading    = true
    @objc private dynamic var refreshing = false
    @objc private dynamic var items      = [ HistoryItem ]()
    
    private var account: Account?
    private var timer:   Timer?
    private var add:     AccountWindowController?
    
    convenience init( account: Account )
    {
        self.init()
        
        self.account = account
    }
    
    deinit
    {
        self.timer?.invalidate()
    }
    
    override var nibName: NSNib.Name?
    {
        return NSStringFromClass( type( of: self ) )
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.itemsController.sortDescriptors = [ NSSortDescriptor( key: "date", ascending: false ) ]
        
        self.refresh( nil )
        
        self.timer = Timer.scheduledTimer( withTimeInterval: 5, repeats: true )
        {
            t in self.refresh( userInitiated: false )
        }
    }
    
    @IBAction func refresh( _ sender: Any? )
    {
        self.refresh( userInitiated: true )
    }
    
    private func refresh( userInitiated: Bool )
    {
        DispatchQueue.main.async
        {
            if self.refreshing
            {
                return
            }
            
            self.refreshing = true
            
            guard let account = self.account else
            {
                self.refreshing = false
                self.loading    = false
                
                return
            }
            
            guard let password = account.password else
            {
                if userInitiated
                {
                    self.askPassword()
                }
                
                self.refreshing = false
                self.loading    = false
                
                return
            }
            
            if userInitiated
            {
                self.loading = true
            }
            
            DispatchQueue.global( qos: .userInitiated ).async
            {
                let altool  = ALTool( username: account.username, password: password )
                let xml     = try? altool.notarizationHistory()
                
                DispatchQueue.main.async
                {
                    if let xmlData = xml??.data( using: .utf8 )
                    {
                        if let history = try? PropertyListSerialization.propertyList( from: xmlData, options: [], format: nil ) as? NSDictionary
                        {
                            self.itemsController.remove( contentsOf: self.items )
                            self.itemsController.add( contentsOf: HistoryItem.ItemsFromDictionary( dict: history ) )
                        }
                    }
                    
                    self.loading    = false
                    self.refreshing = false
                }
            }
        }
    }
    
    private func askPassword()
    {
        if self.add != nil
        {
            return
        }
        
        self.add = AccountWindowController()
        
        guard let add = self.add else
        {
            return
        }
        
        guard let account = self.account else
        {
            return
        }
        
        guard let sheet = add.window else
        {
            return
        }
        
        add.username = account.username
        
        self.view.window?.beginSheet( sheet )
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
            
            self.account = account
            
            self.refresh( nil )
        }
    }
}
