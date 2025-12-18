//
//  InterstitialAdManager.swift
//  Seven Hand Poker
//
//  Manager for Google AdMob interstitial ads
//

import UIKit
import GoogleMobileAds

class InterstitialAdManager: NSObject {
    // MARK: - Singleton
    static let shared = InterstitialAdManager()

    // MARK: - Properties
    private var interstitialAd: InterstitialAd?
    private var isLoading = false

    private override init() {
        super.init()
        loadAd()
    }

    // MARK: - Public Methods

    /// Load a new interstitial ad
    func loadAd() {
        guard !isLoading else { return }

        isLoading = true
        let adUnitID = AdConfig.interstitialAdUnitId

        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            self?.isLoading = false

            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                return
            }

            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            print("Interstitial ad loaded successfully")
        }
    }

    /// Show the interstitial ad if available
    /// - Returns: true if ad was shown, false otherwise
    @discardableResult
    func showAd() -> Bool {
        guard let ad = interstitialAd else {
            print("Interstitial ad not ready")
            loadAd()
            return false
        }

        guard let rootViewController = getRootViewController() else {
            print("Could not get root view controller")
            return false
        }

        ad.present(from: rootViewController)
        return true
    }

    /// Check if an ad is ready to be shown
    var isAdReady: Bool {
        return interstitialAd != nil
    }

    // MARK: - Private Methods

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - FullScreenContentDelegate

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        // Load the next ad
        interstitialAd = nil
        loadAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
        interstitialAd = nil
        loadAd()
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad will present")
        TrackingManager.shared.trackAdShown(type: "interstitial")
    }
}
