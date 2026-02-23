import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        // Allow localStorage and other storage APIs
        config.websiteDataStore = WKWebsiteDataStore.default()
        // Allow inline media playback (for Web Audio API)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
