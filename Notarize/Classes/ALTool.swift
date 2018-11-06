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

class ALTool
{
    private var username: String
    private var password: String
    
    class func isAvailable() -> Bool
    {
        let out = ALTool.run( arguments: [ "--help" ] )
        
        return out?.count ?? 0 > 0
    }
    
    init( username: String, password: String )
    {
        self.username = username
        self.password = password
    }
    
    func notarizationHistory() -> String?
    {
        let out = ALTool.run( arguments: [ "--notarization-history", "-u", self.username, "-p", self.password, "--output-format", "xml" ] )
        
        return out?.trimmingCharacters( in: NSCharacterSet.whitespacesAndNewlines )
    }
    
    private class func run( arguments: [ String ] ) -> String?
    {
        var args = [ "altool" ]
        
        args.append( contentsOf: arguments )
        
        let pipe               = Pipe()
        let process            = Process()
        process.launchPath     = "/usr/bin/xcrun"
        process.arguments      = args
        process.standardOutput = pipe
        
        do
        {
            try process.run()
        }
        catch let e
        {
            Swift.print( e )
            return nil
        }
        
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        return String( bytes: data, encoding: .utf8 )
    }
}
