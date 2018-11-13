/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2018 DigiDNA - www.imazing.com
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

class IsNotEmpty: ValueTransformer
{
    override class func transformedValueClass() -> AnyClass
    {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool
    {
        return false
    }
    
    override func transformedValue( _ value: Any? ) -> Any?
    {
        if let array = value as? NSArray
        {
            return array.count > 0
        }
        else if let set = value as? NSSet
        {
            return set.count > 0
        }
        else if let dictionary = value as? NSDictionary
        {
            return dictionary.count > 0
        }
        else if let string = value as? String
        {
            return string.count > 0
        }
        
        return false
    }
}
