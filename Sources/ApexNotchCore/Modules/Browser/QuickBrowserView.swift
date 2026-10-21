import SwiftUI
import WebKit

@MainActor
public final class BrowserViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    public static let shared = BrowserViewModel()
    
    @Published public var urlString: String = "https://duckduckgo.com"
    @Published public var title: String = "Browser"
    @Published public var isLoading: Bool = false
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    
    public var webView: WKWebView
    
    override private init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        
        self.webView.navigationDelegate = self
        loadDefaultHome()
    }
    
    public func loadDefaultHome() {
        let home = UserPreferences.shared.searchEngine.homeURL
        load(url: home)
    }
    
    public func navigate(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if trimmed.contains(".") && !trimmed.contains(" ") {
            var urlStr = trimmed
            if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
                urlStr = "https://" + urlStr
            }
            if let url = URL(string: urlStr) {
                load(url: url)
                return
            }
        }
        
        // Treat as query
        if let queryURL = UserPreferences.shared.searchEngine.url(for: trimmed) {
            load(url: queryURL)
        }
    }
    
    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        self.urlString = url.absoluteString
    }
    
    public func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    public func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    public func reload() {
        webView.reload()
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.isLoading = true
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.isLoading = false
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
        self.title = webView.title ?? "Browser"
        if let currentURL = webView.url?.absoluteString {
            self.urlString = currentURL
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.isLoading = false
    }
}

public struct QuickBrowserNSViewRepresentable: NSViewRepresentable {
    public let webView: WKWebView
    
    public func makeNSView(context: Context) -> WKWebView {
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
}

public struct QuickBrowserView: View {
    @ObservedObject private var browser = BrowserViewModel.shared
    @NotchState private var inputURL: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Navigation Bar
            HStack(spacing: 6) {
                Button(action: { browser.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!browser.canGoBack)
                .foregroundColor(browser.canGoBack ? NotchDesign.textPrimary : NotchDesign.textTertiary)
                
                Button(action: { browser.goForward() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!browser.canGoForward)
                .foregroundColor(browser.canGoForward ? NotchDesign.textPrimary : NotchDesign.textTertiary)
                
                Button(action: { browser.reload() }) {
                    Image(systemName: browser.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(NotchDesign.textSecondary)
                
                // URL input bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(NotchDesign.textTertiary)
                    
                    TextField("Search or enter web address...", text: $inputURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .onSubmit {
                            browser.navigate(input: inputURL)
                        }
                    
                    if browser.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                
                Button(action: { browser.loadDefaultHome() }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Search Engine Home")
            }
            
            // WebView container
            QuickBrowserNSViewRepresentable(webView: browser.webView)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
                .frame(maxHeight: 280)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NotchDesign.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
        .onAppear {
            inputURL = browser.urlString
        }
        .onChange(of: browser.urlString) { _, newURL in
            inputURL = newURL
        }
    }
}
