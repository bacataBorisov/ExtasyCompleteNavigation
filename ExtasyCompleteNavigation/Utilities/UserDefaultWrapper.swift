//
//  UserDefaultWrapper.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 30.12.24.
//
import Foundation

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            UserDefaults.standard.value(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

