//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import UIKit
//import PlaygroundSupport

@objc(Book_Sources_LiveViewController)
public class LiveViewController: UIViewController {
    public func updateSettings(_ newSettings: Settings) {
        self.settings = newSettings
        didReceiveSettings = true
        render(isFinal: true)
    }

    private let imageView = UIImageView()
    private var settings = Settings.mandelbrot()

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let scaleGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerChanged))
        scaleGestureRecognizer.delegate = self
        view.addGestureRecognizer(scaleGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerChanged))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        render(isFinal: true)
    }

    private var scaleFactor: BDouble = 200
    private var center = ComplexNumber(real: 0, imaginary: 0)
    private var didReceiveSettings = false

    func isFinalEvent(recognizer: UIGestureRecognizer) -> Bool {
        return [UISwipeGestureRecognizer.State.began, .changed, .possible].contains(recognizer.state)
    }

    @objc func pinchGestureRecognizerChanged(recognizer: UIPinchGestureRecognizer) {
        let oldScaleFactor = scaleFactor
        scaleFactor *= BDouble(Double(recognizer.scale))
        recognizer.scale = 1

        let scaleCenter = recognizer.location(in: view)

        let xDistance = BDouble(Double((scaleCenter.x - view.bounds.midX) * UIScreen.main.scale))
        let yDistance = BDouble(Double((scaleCenter.y - view.bounds.midY) * UIScreen.main.scale))

        center = ComplexNumber(
            real: center.real - xDistance / scaleFactor + xDistance / oldScaleFactor,
            imaginary: center.imaginary - yDistance / scaleFactor + yDistance / oldScaleFactor)

        render(isFinal: isFinalEvent(recognizer: recognizer))
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)

        center = ComplexNumber(
            real: center.real - BDouble(Double(movement.x * UIScreen.main.scale)) / scaleFactor,
            imaginary: center.imaginary - BDouble(Double(movement.y * UIScreen.main.scale)) / scaleFactor)
        render(isFinal: isFinalEvent(recognizer: recognizer))
    }

    private var currentRenderProcess: RenderProcess?
    private var currentRenderProcessCanBeStopped = true

    func render(isFinal: Bool) {
        guard didReceiveSettings, currentRenderProcessCanBeStopped else {
            return
        }

        self.currentRenderProcess?.stop()
        currentRenderProcessCanBeStopped = false

        let renderProcess = RenderProcess(
            width: Int(view.bounds.width * UIScreen.main.scale),
            height: Int(view.bounds.height * UIScreen.main.scale),
            scaling: scaleFactor,
            center: center,
            settings: settings
        )
        self.currentRenderProcess = renderProcess

        renderProcess.start { image in
            self.imageView.image = image
            self.currentRenderProcessCanBeStopped = true
        }
    }
}

extension LiveViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
