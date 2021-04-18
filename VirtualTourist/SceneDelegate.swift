//
//  SceneDelegate.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let mapview = navigationController.topViewController as! MapViewController
        mapview.dataController = (UIApplication.shared.delegate as? AppDelegate)?.dataController
    }


}

