//
//  UserDefaultsSyncMessage.swift
//  nightguard
//
//  Created by Florian Preknya on 1/25/19.
//  Copyright © 2019 private. All rights reserved.
//

import Foundation

class UserDefaultSyncMessage: WatchMessage {
    
    var dictionary: [String : Any]
    
    required init?(dictionary: [String : Any]) {
        self.dictionary = dictionary
    }
}
