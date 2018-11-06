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
    
    convenience init( account: Account )
    {
        self.init()
        
        self.account = account
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
    }
    
    @IBAction func refresh( _ sender: Any? )
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
                return
            }
            
            guard let password = account.password else
            {
                return
            }
            
            self.itemsController.remove( contentsOf: self.items )
            
            self.loading = true
            
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
                            self.itemsController.add( contentsOf: HistoryItem.ItemsFromDictionary( dict: history ) )
                        }
                    }
                    
                    self.loading    = false
                    self.refreshing = false
                }
            }
        }
    }
}
