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

@objc class HistoryItem: NSObject
{
    @objc public dynamic var date:    NSDate
    @objc public dynamic var uuid:    String
    @objc public dynamic var success: Bool
    @objc public dynamic var status:  Int
    @objc public dynamic var message: String
    @objc public dynamic var logURL:  String?
    
    class func ItemsFromDictionary( dict: NSDictionary? ) -> [ HistoryItem ]
    {
        guard let history = dict?.object( forKey: "notarization-history" ) as? NSDictionary else
        {
            return []
        }
        
        guard let items = history.object( forKey: "items" ) as? NSArray else
        {
            return []
        }
        
        var objects = [ HistoryItem ]()
        
        for o in items
        {
            guard let item = o as? NSDictionary else
            {
                continue
            }
            
            guard let historyItem = HistoryItem( dict: item ) else
            {
                continue
            }
            
            objects.append( historyItem )
        }
        
        return objects
    }
    
    init?( dict: NSDictionary )
    {
        guard let date = dict.object( forKey: "Date" ) as? NSDate else
        {
            return nil
        }
        
        guard let uuid = dict.object( forKey: "RequestUUID" ) as? String else
        {
            return nil
        }
        
        guard let status = dict.object( forKey: "Status" ) as? String else
        {
            return nil
        }
        
        guard let code = dict.object( forKey: "Status Code" ) as? NSNumber else
        {
            return nil
        }
        
        guard let message = dict.object( forKey: "Status Message" ) as? String else
        {
            return nil
        }
        
        self.date    = date
        self.uuid    = uuid
        self.success = status == "success"
        self.status  = code.intValue
        self.message = message
    }
    
    override func isEqual( _ object: Any? ) -> Bool
    {
        guard let o = object as? HistoryItem else
        {
            return false
        }
        
        return self.uuid == o.uuid
    }
    
    override var hash: Int
    {
        return self.uuid.hash
    }
}
