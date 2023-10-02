//
//  Utilities.swift
//  MapWalk
//
//  Created by MyMac on 02/10/23.
//

import Foundation
import UIKit

class Utility: NSObject {
    static func getDirectoryPath(folderName: String) -> URL? {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(folderName)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            //NSLog("Document directory is \(filePath)")
            return filePath
        }
        return nil
    }
}
