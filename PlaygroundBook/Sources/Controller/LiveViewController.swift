//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import Metal
import MetalKit
import PlaygroundSupport

@objc(Book_Sources_LiveViewController)
public class LiveViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer, MTKViewDelegate {

    public func receive(_ message: PlaygroundValue) {
        guard let settings = try? Settings.decode(message: message) else {
            return
        }

        updateSettings(settings)
    }

    public func updateSettings(_ newSettings: Settings) {
        self.settings = newSettings
        requestRendering()
    }

    private let metalDevice: MTLDevice
    private let pipelineState: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue
    private let metalView: MTKView
    private let centerBuffer: MTLBuffer

    private var settings = Settings.mandelbrot()
    private var scaleFactor: CGFloat = 200
    private var center = CGPoint.zero

    init() {
        metalDevice = MTLCreateSystemDefaultDevice()!
        commandQueue = metalDevice.makeCommandQueue()!

        let shaderSource = try! String(contentsOf: Bundle.main.url(forResource: "Shader", withExtension: "metal")!)

        let library = try! metalDevice.makeLibrary(source: shaderSource, options: nil)
        let renderFunction = library.makeFunction(name: "mandelbrotShader")!

        pipelineState = try! metalDevice.makeComputePipelineState(function: renderFunction)
        centerBuffer = metalDevice.makeBuffer(length: 4 * MemoryLayout<Float32>.stride)!

        metalView = MTKView(frame: .zero, device: metalDevice)
        metalView.framebufferOnly = false
        metalView.autoResizeDrawable = true
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true

        super.init(nibName: nil, bundle: nil)

        metalView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        self.view = metalView

    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let scaleGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerChanged))
        scaleGestureRecognizer.delegate = self
        view.addGestureRecognizer(scaleGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerChanged))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        requestRendering()
    }

    public func requestRendering() {
        metalView.setNeedsDisplay()
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        commandEncoder.setTexture(drawable.texture, index: 0)

        commandEncoder.setComputePipelineState(pipelineState)

        commandEncoder.setBuffer(centerBuffer, offset: 0, index: 0)

        let centerPos = centerBuffer.contents().bindMemory(to: Float.self, capacity: 4)
        centerPos[0] = Float32(center.x)
        centerPos[1] = Float32(center.y)
        centerPos[2] = Float32(scaleFactor)

        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)


        let threadsPerGrid = MTLSize(width: drawable.texture.width/w,
                                     height: drawable.texture.height/h,
                                     depth: 1)

        commandEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
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

        requestRendering()
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)

        center = CGPoint(
            x: center.x + movement.x / scaleFactor,
            y: center.y + movement.y / scaleFactor)
        requestRendering()
    }

    let backgrogroundThread = DispatchQueue(label: "Worker")
    var currentRunIsFastMode = false
//    private var currentRenderProcess: RenderProcess?

//    func render(fastMode: Bool = false) {


//        guard didReceiveSettings else {
//            return
//        }
//
//        guard !fastMode || (currentRenderProcess?.isStopped ?? true) || !currentRunIsFastMode else {
//            return
//        }
//
//        self.currentRenderProcess?.stop()
//        self.currentRunIsFastMode = fastMode
//        let sizeFactor: CGFloat = fastMode ? 6 : 1
//
//        let renderProcess = RenderProcess(
//            width: Int(view.bounds.width / sizeFactor),
//            height: Int(view.bounds.height / sizeFactor),
//            scaling: CGFloat(sizeFactor) / CGFloat(self.scaleFactor),
//            center: center,
//            settings: settings
//        )
//        self.currentRenderProcess = renderProcess
//
//        renderProcess.start { image in
//            self.imageView.image = image
//        }
//    }
}

extension LiveViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
