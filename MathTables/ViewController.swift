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
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0x0f/255, green: 0x0f/255, blue: 0x1a/255, alpha: 1)
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard webView.url == nil else { return }
        let top = view.safeAreaInsets.top
        let bottom = view.safeAreaInsets.bottom
        let js = """
        document.documentElement.style.setProperty('--sat', '\(top)px');
        document.documentElement.style.setProperty('--sab', '\(bottom)px');
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
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
