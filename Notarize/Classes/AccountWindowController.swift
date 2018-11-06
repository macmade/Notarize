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

class AccountWindowController: NSWindowController
{
    @objc public private( set ) dynamic var username        = ""
    @objc public private( set ) dynamic var password        = ""
    @objc public private( set ) dynamic var keepInKeychain  = false
    
    override var windowNibName: NSNib.Name?
    {
        return NSStringFromClass( type( of: self ) )
    }
    
    @IBAction func add( _ sender: Any? )
    {
        guard let window = self.window else
        {
            return
        }
        
        self.window?.sheetParent?.endSheet( window, returnCode: .OK )
    }
    
    @IBAction func cancel( _ sender: Any? )
    {
        self.username       = ""
        self.password       = ""
        self.keepInKeychain = false
        
        guard let window = self.window else
        {
            return
        }
        
        self.window?.sheetParent?.endSheet( window, returnCode: .cancel )
    }
}

