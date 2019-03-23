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
    public func receive(_ message: PlaygroundValue) {
        guard let settings = try? Settings.decode(message: message) else {
            return
        }

        updateSettings(settings)
    }

    public func updateSettings(_ newSettings: Settings) {
        self.settings = newSettings
        didReceiveSettings = true
        render()
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

        render()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        render()
    }

    private var scaleFactor: CGFloat = 200
    private var center = CGPoint.zero
    private var didReceiveSettings = false

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

        render(fastMode: shouldRenderFast(recognizer: recognizer))
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)

        center = CGPoint(
            x: center.x - movement.x / scaleFactor,
            y: center.y - movement.y / scaleFactor)
        render(fastMode: shouldRenderFast(recognizer: recognizer))
    }

    let backgrogroundThread = DispatchQueue(label: "Worker")
    var currentRunIsFastMode = false
    private var currentRenderProcess: RenderProcess?

    func render(fastMode: Bool = false) {
        guard didReceiveSettings else {
            return
        }

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
            settings: settings
        )
        self.currentRenderProcess = renderProcess

        renderProcess.start { image in
            self.imageView.image = image
        }
    }
}

extension LiveViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
