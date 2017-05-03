//
//  VideoUpload.swift
//  ltdvideo
//
//  Created by Kieran Andrews on 29/4/17.
//  Copyright © 2017 Kieran Andrews. All rights reserved.
//

import Foundation
import FirebaseStorage

class VideoUpload: NSObject, NSCoding {

    var thumbnail: UIImage
    var firebaseUploadRef: FIRStorageUploadTask?
    var failed: Bool
    var completed: Bool
    var originalFilename: String
    
    override init() {
        self.thumbnail = UIImage()
        self.firebaseUploadRef = nil
        self.failed = false
        self.completed = false
        self.originalFilename = ""
    }
    
    required init(coder decoder: NSCoder) {
        self.thumbnail = decoder.decodeObject(forKey: "thumbnail") as? UIImage ?? UIImage()
        self.firebaseUploadRef = nil
        // TODO: set this to true if we are encoding it as we know the upload ref cannot be saved
        self.failed = decoder.decodeObject(forKey: "failed") as? Bool ?? false
        self.completed = decoder.decodeObject(forKey: "completed") as? Bool ?? false
        self.originalFilename = decoder.decodeObject(forKey: "originalFilename") as? String ?? ""
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(thumbnail, forKey: "thumbnail")
//        coder.encode(firebaseUploadRef, forKey: "firebaseUploadRef") // We cannot encode this
        coder.encode(failed, forKey: "failed")
        coder.encode(completed, forKey: "completed")
        coder.encode(originalFilename, forKey: "originalFilename")
    }
    
    
}
