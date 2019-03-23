//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import PlaygroundSupport

@objc(Book_Sources_LiveViewController)
public class LiveViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    /*
    public func liveViewMessageConnectionOpened() {
        // Implement this method to be notified when the live view message connection is opened.
        // The connection will be opened when the process running Contents.swift starts running and listening for messages.
    }
    */

    /*
    public func liveViewMessageConnectionClosed() {
        // Implement this method to be notified when the live view message connection is closed.
        // The connection will be closed when the process running Contents.swift exits and is no longer listening for messages.
        // This happens when the user's code naturally finishes running, if the user presses Stop, or if there is a crash.
    }
    */

    public func receive(_ message: PlaygroundValue) {
        // Implement this method to receive messages sent from the process running Contents.swift.
        // This method is *required* by the PlaygroundLiveViewMessageHandler protocol.
        // Use this method to decode any messages sent as PlaygroundValue values and respond accordingly.
    }

    let imageView = UIImageView()

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

    override public func viewLayoutMarginsDidChange() {
        render()
    }

    private var scaleFactor: CGFloat = 200
    private var fastMode = false
    private var center = CGPoint.zero

    func shouldRenderFast(recognizer: UIGestureRecognizer) -> Bool {
        return [UISwipeGestureRecognizer.State.began, .changed, .possible].contains(recognizer.state)
    }

    @objc func pinchGestureRecognizerChanged(recognizer: UIPinchGestureRecognizer) {
        let oldScaleFactor = scaleFactor
        scaleFactor *= recognizer.scale
        recognizer.scale = 1

        let scaleCenter = recognizer.location(in: view)

        let xDistance = scaleCenter.x - view.bounds.midX
        let yDistance = scaleCenter.y - view.bounds.midY

        center = CGPoint(
            x: center.x - xDistance / scaleFactor + xDistance / oldScaleFactor,
            y: center.y - yDistance / scaleFactor + yDistance / oldScaleFactor)

        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)

        center = CGPoint(
            x: center.x - movement.x / scaleFactor,
            y: center.y - movement.y / scaleFactor)
        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    let backgrogroundThread = DispatchQueue(label: "Worker")
    var currentRunIsFastMode = false
    private var currentRenderProcess: RenderProcess?

    func render() {
        guard !fastMode || (currentRenderProcess?.isStopped ?? true) || !currentRunIsFastMode else {
            return
        }

        self.currentRenderProcess?.stop()
        self.currentRunIsFastMode = fastMode
        let sizeFactor: CGFloat = fastMode ? 6 : 1

        let renderProcess = RenderProcess(
            width: Int(view.bounds.width / sizeFactor),
            height: Int(view.bounds.height / sizeFactor),
            scaling: CGFloat(sizeFactor) / CGFloat(self.scaleFactor),
            center: center,
            function: function
        )
        self.currentRenderProcess = renderProcess

        renderProcess.start { image in
            self.imageView.image = image
        }
    }

    var function = Function.id.map { (number: ComplexNumber) -> CGFloat in
        var current = number
        let maxIterations = 1000
        var iterations = 0

        while (current.real * current.real + current.imaginary * current.imaginary <= 2 * 2 && iterations < maxIterations) {
            current = current * current + ComplexNumber(real: -0.8, imaginary: 0.156)
            iterations += 1
        }

        return pow(CGFloat(iterations) / CGFloat(maxIterations), 0.5)
    }.toHueColor().toPixelData()
}

extension LiveViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
