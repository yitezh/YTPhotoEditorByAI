import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)

        let landingVC = LandingViewController()
        let navController = UINavigationController(rootViewController: landingVC)
        navController.setNavigationBarHidden(true, animated: false)

        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
}
