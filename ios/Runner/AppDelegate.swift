import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  
  // Add a blur view for screenshot protection
  private var blurView: UIVisualEffectView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Register for notifications to detect screenshots and screen recording
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(preventScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    // Add observer for when app moves to background (prevents screenshots in app switcher)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    
    // Make content secure (iOS 13+)
    if let window = self.window {
      makeWindowSecure(window: window)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
  
  // Make window content secure
  private func makeWindowSecure(window: UIWindow) {
    let field = UITextField()
    field.isSecureTextEntry = true
    window.addSubview(field)
    field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
    field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
    window.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(window.layer)
  }
  
  // Prevent screenshot notification
  @objc private func preventScreenshot() {
    print("Screenshot attempt detected")
    // You can show an alert or handle this event
  }
  
  // Add blur when app enters background
  @objc private func applicationDidEnterBackground() {
    addBlurEffect()
  }
  
  // Remove blur when app enters foreground
  @objc private func applicationWillEnterForeground() {
    removeBlurEffect()
  }
  
  private func addBlurEffect() {
    guard blurView == nil else { return }
    
    if let window = self.window {
      let blurEffect = UIBlurEffect(style: .light)
      let blurEffectView = UIVisualEffectView(effect: blurEffect)
      blurEffectView.frame = window.bounds
      blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      window.addSubview(blurEffectView)
      blurView = blurEffectView
    }
  }
  
  private func removeBlurEffect() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
