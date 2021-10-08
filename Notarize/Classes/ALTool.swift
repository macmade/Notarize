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
        guard let out = try? ALTool.run( arguments: [ "--help" ] ) else
        {
            return false
        }
        
        return out.stdout.count > 0 || out.stderr.count > 0
    }
    
    init( username: String, password: String )
    {
        self.username = username
        self.password = password
    }
    
    func checkPassword() throws
    {
        let _ = try ALTool.run( arguments: [ "--notarization-history", "0", "-u", self.username, "-p", self.password, "--output-format", "xml" ] )
    }
    
    func notarizationHistory( page: Int64 ) throws -> String?
    {
        let out = try ALTool.run( arguments: [ "--notarization-history", "\( page )", "-u", self.username, "-p", self.password, "--output-format", "xml" ] )
        
        return out.stdout.trimmingCharacters( in: NSCharacterSet.whitespacesAndNewlines )
    }
    
    func notarizationInfo( for uuid: String ) throws -> String?
    {
        let out = try ALTool.run( arguments: [ "--notarization-info", uuid, "-u", self.username, "-p", self.password, "--output-format", "xml" ] )
        
        return out.stdout.trimmingCharacters( in: NSCharacterSet.whitespacesAndNewlines )
    }
    
    private class var executablePath: String?
    {
        let pipe               = Pipe()
        let process            = Process()
        process.launchPath     = "/usr/bin/xcrun"
        process.arguments      = [ "-f", "altool" ]
        process.standardOutput = pipe
        
        do
        {
            try process.run()
        }
        catch let e as NSError
        {
            Swift.print( e )
            
            return nil
        }
        
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let out = String( bytes: data, encoding: .utf8 ) else
        {
            return nil
        }
        
        return out.trimmingCharacters( in: .whitespacesAndNewlines )
    }
    
    private class func run( arguments: [ String ] ) throws -> ( stdout: String, stderr: String )
    {
        guard let exec = ALTool.executablePath else
        {
            throw NSError( domain: NSCocoaErrorDomain, code: -1, userInfo: [ NSLocalizedDescriptionKey : "altool executable not found" ] )
        }
        
        let pipeOut            = Pipe()
        let pipeErr            = Pipe()
        let process            = Process()
        process.launchPath     = exec
        process.arguments      = arguments
        process.standardOutput = pipeOut
        process.standardError  = pipeErr
        
        do
        {
            try process.run()
        }
        catch let e as NSError
        {
            Swift.print( e )
            
            throw e
        }
        
        process.waitUntilExit()
        
        let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
        let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
        
        guard let out = String( bytes: dataOut, encoding: .utf8 ),
              let err = String( bytes: dataErr, encoding: .utf8 )
        else
        {
            throw NSError( domain: NSCocoaErrorDomain, code: -1, userInfo: [ NSLocalizedDescriptionKey : "No data received from altool" ] )
        }
        
        if let data = out.data( using: .utf8 )
        {
            if let dict = try? PropertyListSerialization.propertyList( from: data, options: [], format: nil ) as? NSDictionary
            {
                if let errors = dict.object( forKey: "product-errors") as? NSArray
                {
                    if errors.count > 0
                    {
                        if let errorDict = errors.object( at: 0 ) as? NSDictionary
                        {
                            let code    = errorDict.object( forKey: "code" )    as? NSNumber ?? NSNumber( integerLiteral: 0 )
                            let message = errorDict.object( forKey: "message" ) as? NSString ?? "Unknown error" as NSString
                            
                            if let info = errorDict.object( forKey: "userInfo" ) as? NSDictionary, let failure = info.object( forKey: "NSLocalizedFailureReason" ) as? NSString
                            {
                                throw NSError( domain: NSCocoaErrorDomain, code: code.intValue, userInfo: [ NSLocalizedDescriptionKey : message, NSLocalizedRecoverySuggestionErrorKey : failure ] )
                            }
                            else
                            {
                                throw NSError( domain: NSCocoaErrorDomain, code: code.intValue, userInfo: [ NSLocalizedDescriptionKey : "Error", NSLocalizedRecoverySuggestionErrorKey : message ] )
                            }
                        }
                    }
                }
            }
        }
        
        return ( stdout: out, stderr: err )
    }
}
