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

class HistoryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource
{
    @IBOutlet private var itemsController: NSArrayController!
    
    @objc private dynamic var loading     = true
    @objc private dynamic var refreshing  = false
    @objc private dynamic var gettingInfo = false
    @objc private dynamic var items       = Set< HistoryItem >()
    
    private var account:      Account?
    private var refreshTimer: Timer?
    private var infoTimer:    Timer?
    private var add:          AccountWindowController?
    
    convenience init( account: Account )
    {
        self.init()
        
        self.account = account
    }
    
    deinit
    {
        self.refreshTimer?.invalidate()
        self.infoTimer?.invalidate()
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
        
        self.refreshTimer = Timer.scheduledTimer( withTimeInterval: 5, repeats: true )
        {
            t in self.refresh( userInitiated: false )
        }
        
        self.infoTimer = Timer.scheduledTimer( withTimeInterval: 5, repeats: true )
        {
            t in self.getInfo()
        }
    }
    
    @IBAction func refresh( _ sender: Any? )
    {
        self.refresh( userInitiated: true )
    }
    
    @IBAction func showInfo( _ sender: Any? )
    {
        guard let item = sender as? HistoryItem,
              let url  = URL( string: item.logURL ?? "" )
        else
        {
            return
        }
        
        NSWorkspace.shared.open( url )
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
                do
                {
                    let items = try self.loadHistory( username: account.username, password: password )
                    
                    DispatchQueue.main.async
                    {
                        items.forEach
                        {
                            o in
                            
                            if self.items.contains( o ) == false
                            {
                                self.items.insert( o )
                            }
                        }
                        
                        self.loading    = false
                        self.refreshing = false
                    }
                }
                catch let error
                {
                    if userInitiated
                    {
                        DispatchQueue.main.async
                        {
                            let alert = NSAlert( error: error )
                            
                            if let window = self.view.window
                            {
                                alert.beginSheetModal( for: window, completionHandler: nil )
                            }
                            else
                            {
                                alert.runModal()
                            }
                            
                            self.loading    = false
                            self.refreshing = false
                        }
                    }
                    else
                    {
                        print( error )
                    }
                }
            }
        }
    }
    
    private func loadHistory( username: String, password: String ) throws -> [ HistoryItem ]
    {
        var items  = [ HistoryItem ]()
        let altool = ALTool( username: username, password: password )
        var page   = Int64( 0 )
        
        repeat
        {
            let xml = try altool.notarizationHistory( page: page )
            page    = -1
            
            if let xmlData = xml?.data( using: .utf8 )
            {
                if let history = try? PropertyListSerialization.propertyList( from: xmlData, options: [], format: nil ) as? [ AnyHashable : Any ]
                {
                    let current = HistoryItem.ItemsFromDictionary( dict: history )
                    
                    items.append( contentsOf: current )
                    
                    if current.count > 0, let history = history[ "notarization-history" ] as? [ AnyHashable : Any ], let next = history[ "next-page" ] as? Int64
                    {
                        page = next
                    }
                }
            }
        }
        while page >= 0
        
        return items
    }
    
    private func getInfo()
    {
        DispatchQueue.main.async
        {
            if self.gettingInfo
            {
                return
            }
            
            self.gettingInfo = true
            
            DispatchQueue.global( qos: .userInitiated ).async
            {
                guard let account  = self.account,
                      let password = account.password
                else
                {
                    return
                }
                
                let items  = DispatchQueue.main.sync { return self.items }
                let altool = ALTool( username: account.username, password: password )
                let group  = DispatchGroup()
                
                for item in items.filter( { o in o.logURL == nil } )
                {
                    DispatchQueue.global( qos: .userInitiated ).async( group: group )
                    {
                        guard let xml          = try? altool.notarizationInfo( for: item.uuid ),
                              let xmlData      = xml.data( using: .utf8 ),
                              let info         = try? PropertyListSerialization.propertyList( from: xmlData, options: [], format: nil ) as? [ AnyHashable : Any ],
                              let notarization = info[ "notarization-info" ]                                                            as? [ AnyHashable : Any ],
                              let url          = notarization[ "LogFileURL" ]                                                           as? String else
                        {
                            return
                        }
                        
                        DispatchQueue.main.async
                        {
                            item.logURL = url
                        }
                    }
                }
                
                group.wait()
                       
                DispatchQueue.main.async
                {
                    self.gettingInfo = false
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
        
        guard let add     = self.add,
              let account = self.account,
              let sheet   = add.window
        else
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
