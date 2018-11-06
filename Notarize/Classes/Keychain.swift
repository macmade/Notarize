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

import Foundation
import Security

class Keychain
{
    private var keychain: CFTypeRef?
    
    init( keychain: CFTypeRef? )
    {
        self.keychain = keychain
    }
    
    func setPassword( service: String, account: String, password: String ) -> Bool
    {
        guard let item = self.findGenericPassword( service: service, account: account ) else
        {
            let status = SecKeychainAddGenericPassword( nil, UInt32( service.utf8.count ), service, UInt32( account.utf8.count ), account, UInt32( password.utf8.count ), password, nil )
            
            return status == errSecSuccess
        }
        
        return SecKeychainItemModifyContent( item, nil, UInt32( password.utf8.count ), password ) == errSecSuccess
    }
    
    func getPassword( service: String, account: String ) -> String?
    {
        guard let item = self.findGenericPassword( service: service, account: account ) else
        {
            return nil
        }
        
        var length: UInt32                   = 0
        var data:   UnsafeMutableRawPointer? = nil
        
        if SecKeychainItemCopyContent( item, nil, nil, &length, &data ) == errSecSuccess && data != nil
        {
            let password = NSString( bytes: data!, length: Int( length ), encoding: String.Encoding.utf8.rawValue ) as String?
            
            SecKeychainItemFreeContent( nil, data )
            
            return password
        }
        
        return nil
    }
    
    func delete( service: String, account: String ) -> Bool
    {
        guard let item = self.findGenericPassword( service: service, account: account ) else
        {
            return true
        }
        
        return SecKeychainItemDelete( item ) == errSecSuccess
    }
    
    private func findGenericPassword( service: String, account: String ) -> SecKeychainItem?
    {
        var item: SecKeychainItem?
        
        let status = SecKeychainFindGenericPassword( nil, UInt32( service.utf8.count ), service, UInt32( account.utf8.count ), account, nil, nil, &item )
            
        return ( status == errSecSuccess ) ? item : nil
    }
}
