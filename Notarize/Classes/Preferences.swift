/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
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

@objc public class Preferences: NSObject
{
    @objc public dynamic var lastStart: Date?
    @objc public dynamic var accounts:  [ AnyHashable : Any ]?
    
    @objc public static let shared = Preferences()
    
    override init()
    {
        super.init()
        
        if let path = Bundle.main.path( forResource: "Defaults", ofType: "plist" )
        {
            UserDefaults.standard.register( defaults: NSDictionary( contentsOfFile: path ) as? [ String : Any ] ?? [ : ] )
        }
        
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            self.setValue( UserDefaults.standard.object( forKey: key ), forKey: key )
            self.addObserver( self, forKeyPath: key, options: .new, context: nil )
        }
    }
    
    deinit
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            self.removeObserver( self, forKeyPath: key )
        }
    }
    
    @objc public override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey : Any ]?, context: UnsafeMutableRawPointer? )
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            if( key == keyPath )
            {
                UserDefaults.standard.set( change?[ NSKeyValueChangeKey.newKey ], forKey: key )
            }
        }
    }
    
    func addAccount( _ account: Account )
    {
        var accounts = self.accounts ?? [:]
        
        accounts[ account.username ] = NSNumber( booleanLiteral: account.useKeychain )
        
        self.accounts = accounts
    }
    
    func removeAccount( _ account: Account )
    {
        guard var accounts = self.accounts else
        {
            return
        }
        
        accounts.removeValue( forKey: account.username )
        
        if account.useKeychain, let bundleID = Bundle.main.bundleIdentifier
        {
            let _ = Keychain( keychain: nil ).delete( service: bundleID, account: account.username )
        }
        
        self.accounts = accounts
    }
    
    func getAccounts() -> [ Account ]
    {
        var accounts = [ Account ]()
        
        self.accounts?.forEach
        {
            guard let username = $0.key as? String else
            {
                return
            }
             
            let useKeychain = ( $0.value as? NSNumber )?.boolValue ?? false
            
            accounts.append( Account( username: username, useKeychain: useKeychain ) )
        }
        
        return accounts
    }
}
