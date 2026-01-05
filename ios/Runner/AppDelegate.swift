import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var blurView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Add observers for screenshot prevention in app switcher
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func applicationWillResignActive() {
    // Add blur effect when app goes to background to hide content in app switcher
    if let window = self.window {
      let blurEffect = UIBlurEffect(style: .dark)
      let blurView = UIVisualEffectView(effect: blurEffect)
      blurView.frame = window.bounds
      blurView.tag = 999
      window.addSubview(blurView)
      self.blurView = blurView
    }
  }

  @objc private func applicationDidBecomeActive() {
    // Remove blur effect when app becomes active
    blurView?.removeFromSuperview()
    blurView = nil
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
