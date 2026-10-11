//
//  BarcodeCameraPreview.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import AudioToolbox
@preconcurrency import AVFoundation
import SwiftUI

/// Live barcode camera. Configuration stays on one queue so starting the session cannot throw.
struct BarcodeCameraPreview: UIViewRepresentable {
    let rescanToken: Int
    let onBarcodeDetected: (String) -> Void
    let onFailure: (String) -> Void

    func makeUIView(context: Context) -> BarcodeCameraView {
        let view = BarcodeCameraView()
        view.onBarcodeDetected = onBarcodeDetected
        view.onFailure = onFailure
        view.appliedRescanToken = rescanToken
        view.start()
        return view
    }

    func updateUIView(_ uiView: BarcodeCameraView, context: Context) {
        uiView.onBarcodeDetected = onBarcodeDetected
        uiView.onFailure = onFailure
        guard uiView.appliedRescanToken != rescanToken else { return }
        uiView.appliedRescanToken = rescanToken
        uiView.resetDetection()
    }

    static func dismantleUIView(_ uiView: BarcodeCameraView, coordinator: ()) {
        uiView.stop()
    }
}

final class BarcodeCameraView: UIView {
    var onBarcodeDetected: ((String) -> Void)?
    var onFailure: ((String) -> Void)?

    private let sessionQueue = DispatchQueue(label: "uk.progress.barcode.camera")
    private let captureSession = AVCaptureSession()
    private let metadataProxy = BarcodeMetadataProxy()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var appliedRescanToken = 0

    func start() {
        bindProxy()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            nonisolated(unsafe) let cameraView = self
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraView.configureAndStart()
                    } else {
                        cameraView.onFailure?("Camera permission required")
                    }
                }
            }
        default:
            onFailure?("Camera permission required")
        }
    }

    func resetDetection() {
        metadataProxy.resetDetection()
    }

    func stop() {
        nonisolated(unsafe) let session = captureSession
        let proxy = metadataProxy
        sessionQueue.async {
            proxy.isStopped = true
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func bindProxy() {
        metadataProxy.onBarcode = { [weak self] code in
            self?.onBarcodeDetected?(code)
        }
        metadataProxy.onFailure = { [weak self] message in
            self?.onFailure?(message)
        }
    }

    private func configureAndStart() {
        bindProxy()
        installPreviewLayerIfNeeded()

        nonisolated(unsafe) let session = captureSession
        let proxy = metadataProxy
        sessionQueue.async {
            BarcodeCameraConfigurator.configure(session: session, proxy: proxy)
        }
    }

    private func installPreviewLayerIfNeeded() {
        guard previewLayer == nil else {
            previewLayer?.frame = bounds
            return
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

/// Receives barcode metadata on the main queue and reports setup failures.
final class BarcodeMetadataProxy: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    var onBarcode: ((String) -> Void)?
    var onFailure: ((String) -> Void)?
    var isStopped = false
    private var hasDetectedBarcode = false

    func resetDetection() {
        DispatchQueue.main.async { [weak self] in
            self?.hasDetectedBarcode = false
        }
    }

    func reportFailure(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onFailure?(message)
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetectedBarcode else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.isEmpty else {
            return
        }

        hasDetectedBarcode = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onBarcode?(value)
    }
}

enum BarcodeCameraConfigurator {
    static func configure(session: AVCaptureSession, proxy: BarcodeMetadataProxy) {
        guard !proxy.isStopped else { return }

        session.beginConfiguration()
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        guard let device = AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration()
            proxy.reportFailure("Camera isn't available on this device.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                proxy.reportFailure("This device can't open the camera.")
                return
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            proxy.reportFailure("Camera permission required")
            return
        }

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            proxy.reportFailure("This device can't read barcodes.")
            return
        }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(proxy, queue: .main)

        let requested: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128, .code39]
        let available = output.availableMetadataObjectTypes
        let supported = available.isEmpty
            ? [AVMetadataObject.ObjectType.ean8, .ean13, .upce]
            : requested.filter { available.contains($0) }
        guard !supported.isEmpty else {
            session.commitConfiguration()
            proxy.reportFailure("This device can't read barcodes.")
            return
        }
        output.metadataObjectTypes = supported
        session.commitConfiguration()

        guard !proxy.isStopped else { return }
        if !session.isRunning {
            session.startRunning()
        }
    }
}
