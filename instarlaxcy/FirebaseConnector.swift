//
//  FirebaseConnector.swift
//  instarlaxcy
//
//  Created by Faizan Khalid on 17/04/2019.
//  Copyright © 2019 Faizan Khalid. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

enum Node: String {
    case chat
    static func getNode(_ node: Node) -> DatabaseReference {
        return Database.database().reference().child(node.rawValue)
    }
}
struct FirebaseConnector {
    func getImages(completion: @escaping ([FBImage])-> Void) {
        Node.getNode(.chat)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let imagesDict = snapshot.value as? [String: AnyObject] else {
                    completion([])
                    return }
                var images = imagesDict.compactMap({ return FBImage(key: $0.key, raw: $0.value) })
                images.sort(by: { return $0.timestamp < $1.timestamp })
                completion(images)
            })
    }

    func uploadImage(image: UIImage) {
        let fileName = UUID().uuidString
        let storageRef = Storage.storage()
            .reference()
            .child(Node.chat.rawValue)
            .child(fileName + ".jpg")
        guard let data = image.jpegData(compressionQuality: 0.2) else { return }
        storageRef.putData(data, metadata: nil) { (uploadedData, error) in
            guard error == nil else { return }
            storageRef.downloadURL(completion: { (url, err) in
                guard let downloadUrl = url?.absoluteString else {
                    return
                }

                self.saveImageToDb(url: downloadUrl, name: fileName)
            })
        }
    }

    func saveImageToDb(url: String, name: String) {
        let data = [
            "timestamp": Date().timeIntervalSince1970,
            "profileUrl": url
            ] as [String : Any]
        Node.getNode(.chat).child(name).setValue(data) { (error, ref) in
            guard error == nil else { return }
            NotificationCenter.default.post(name: reloadEvent, object: nil)
        }
    }

    func deleteImage(_ image: FBImage) {
        Storage.storage()
            .reference()
            .child(Node.chat.rawValue)
            .child(image.id + ".jpg")
            .delete(completion: { err in
            print(err)
        })
        Node.getNode(.chat)
            .child(image.id).removeValue(completionBlock: { _,_  in
                NotificationCenter.default.post(name: reloadOnDeleteEvent, object: nil)
            })
    }
}

let reloadEvent = Notification.Name("reload")
let reloadOnDeleteEvent = Notification.Name("reloadOnDelete")
