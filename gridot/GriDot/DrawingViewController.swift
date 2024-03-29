//
//  DrawingViewController.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/11/05.
//

import UIKit
import RxSwift

enum direction {
    case left
    case right
    case top
    case bottom
}

class DrawingViewController: UIViewController {
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var canvasViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollNav: UIView!
    @IBOutlet weak var scrollNavBar: UIView!
    
    @IBOutlet weak var superView: UIView!
    @IBOutlet weak var panelView: UIView!
    @IBOutlet weak var panelCollectionView: UICollectionView!
    @IBOutlet weak var panelWidthContraint: NSLayoutConstraint!
    
    @IBOutlet weak var sideButtonViewGroup: UIView!
    @IBOutlet weak var sideButtonView: UIView!
    @IBOutlet weak var topSideBtn: UIView!
    @IBOutlet weak var midSideBtnView: UIView!
    @IBOutlet weak var midExtensionBtn: UIView!
    @IBOutlet weak var midSideBtn: UIView!
    @IBOutlet weak var botSideBtn: UIView!
    @IBOutlet weak var topSideBtnImage: UIImageView!
    @IBOutlet weak var midSideBtnImage: UIImageView!
    @IBOutlet weak var botSideBtnImage: UIImageView!

    var canvas: Canvas!
    var coreData: CoreData = CoreData.shared
    var timeMachineVM: TimeMachineViewModel!
    
    var panelConstraint: NSLayoutConstraint!
    var sideButtonGroupConstraint: NSLayoutConstraint!
    var sideButtonToCanvasConstraint: NSLayoutConstraint!
    var sideButtonToGroupConstraint: NSLayoutConstraint!
    var currentSide: direction!
    var prevToolIndex: Int!
    
    var scrollPosition: CGFloat!
    var scrollPanelNum: CGFloat!
    var scrollBeganPos: CGFloat!
    var scrollMovedPos: CGFloat!
    
    var scrollConstraint: NSLayoutConstraint!
    var orderOfTools: [Int] = [0, 1, 2]
    
    // view models
    var animatedPreviewVM: AnimatedPreviewViewModel!
    var layerVM: LayerListViewModel!
    var colorPaletteVM: ColorPaletteListViewModel!
    var drawingToolVM: DrawingToolViewModel!
    var loadingVM: LoadingCanvasViewModel!
    
    // view cells
    var previewImageToolBar: PreviewAndLayerCollectionViewCell!
    var colorPickerToolBar: ColorPaletteCollectionViewCell!
    var drawingToolBar: DrawingToolCollectionViewCell!
    
    // drawing mode values
    var buttonViewWidth: CGFloat!
    var panelViewWidth: CGFloat!
    
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        currentSide = .left
        
        scrollPosition = 0
        scrollPanelNum = 0
        scrollBeganPos = 0
        scrollMovedPos = 0
        
        layerVM = LayerListViewModel()
        animatedPreviewVM = AnimatedPreviewViewModel()
        colorPaletteVM = ColorPaletteListViewModel()
        drawingToolVM = DrawingToolViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let numsOfPixels: CGFloat = 16
        let frameWidth = self.view.frame.width * 0.9
        let lengthOfOneSide = round(frameWidth / numsOfPixels) * numsOfPixels
        
        canvas = Canvas(lengthOfOneSide, Int(numsOfPixels), self)
        canvas.frame = CGRect(x: 0, y: 0, width: lengthOfOneSide, height: lengthOfOneSide)
        canvas.backgroundColor = .clear
        canvasView.addSubview(canvas)
        loadingVM = LoadingCanvasViewModel.init(frame: canvas.frame)
        
        self.timeMachineVM = TimeMachineViewModel(canvas, self)
        canvas.timeMachineVM = self.timeMachineVM
        panelWidthContraint.constant = 0
        canvasViewWidth.constant = lengthOfOneSide
        setButtonImage()
        
        setSideCorner(target: sideButtonView, side: "all", radius: sideButtonView.bounds.width / 4)
        setSideCorner(target: topSideBtn, side: "all", radius: topSideBtn.bounds.width / 4)
        setSideCorner(target: midExtensionBtn, side: "top", radius: midSideBtn.bounds.width / 4)
        setSideCorner(target: midSideBtn, side: "bottom", radius: midSideBtn.bounds.width / 4)
        setSideCorner(target: botSideBtn, side: "all", radius: botSideBtn.bounds.width / 4)
        
        UserDefaults.standard.setValue(0, forKey: "drawingMode")
        setNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        if (coreData.hasIndexChanged) {
            DispatchQueue.main.async { [self] in
                self.loadingVM.setLabelView(self)
                DispatchQueue.main.async { [self] in
                    canvas.initViewModelImageIntData()
                    loadingVM.removeLoadingCanvasView(canvasView)
                    previewImageToolBar.setOffsetForSelectedFrame()
                    previewImageToolBar.setOffsetForSelectedLayer()
                    drawingToolBar.drawingToolCollection.reloadData()
                    coreData.hasIndexChanged = false
                }
            }
        }
    }
    
    private func setNavigationBar() {
        let backButton = UIButton(type: .system)
        var config = UIImage.SymbolConfiguration(weight: .heavy)
        config = config.applying(UIImage.SymbolConfiguration(hierarchicalColor: UIColor.init(named: "Icon")!))
        
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        image?.withTintColor(UIColor(named: "Icon")!)
        backButton.setImage(image, for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        backButton.rx
            .tap.subscribe { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        let lightModeButton = UIButton(type: .system)
        lightModeButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        lightModeButton.rx
            .tap.subscribe { [weak self] _ in
                let lightMode = self?.view.window?.overrideUserInterfaceStyle
                self?.navigationController?.view.window?.overrideUserInterfaceStyle = lightMode == .dark ? .light : .dark
                let imageName = lightMode == .dark ? "sun.max.fill" : "moon.fill"
                let lightModeImage = UIImage(systemName: imageName, withConfiguration: config)
                lightModeButton.setImage(lightModeImage, for: .normal)
            }.disposed(by: disposeBag)
        
        let lightMode = self.navigationController?.view.window?.overrideUserInterfaceStyle
        let imageName = lightMode == .dark ? "moon.fill" : "sun.max.fill"
        let lightModeImage = UIImage(systemName: imageName, withConfiguration: config)
        lightModeButton.setImage(lightModeImage, for: .normal)
        
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton)]
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: lightModeButton)]
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.navigationBar.isHidden = false
        navigationItem.title = ""
    }
    
    @objc func detectOrientation() {
        if (UIDevice.current.orientation == .landscapeLeft) {
            print("drawing : landscapeLeft")
            superView.transform = CGAffineTransform(rotationAngle: 0)
            canvasView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            panelView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        }
        
        if (UIDevice.current.orientation == .landscapeRight) {
            print("drawing : landscapeRight")
            superView.transform = CGAffineTransform(rotationAngle: .pi)
            canvasView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            panelView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            
            if (buttonViewWidth == nil) {
                buttonViewWidth = sideButtonView.frame.width
                panelViewWidth = panelCollectionView.frame.size.width
            }
            setPanelSize(
                width: panelViewWidth - buttonViewWidth,
                constant: -1 * buttonViewWidth
            )
        }

        if (UIDevice.current.orientation == .portrait) {
            print("drawing : portrait")
            superView.transform = CGAffineTransform(rotationAngle: 0)
            canvasView.transform = CGAffineTransform(rotationAngle: 0)
            panelView.transform = CGAffineTransform(rotationAngle: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        loadingVM.removeLoadingCanvasView(canvasView)
        canvas.switchToolsSetUnused()
        canvas.selectedArea.stopDrawOutlineInterval()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let colorMode = self.traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
        
        loadingVM.changeLoadingColorMode(colorMode)
        setSideButtonBGColor(target: midSideBtn, isDown: false)
        setSideButtonBGColor(target: botSideBtn, isDown: false)
    }
    
    func changeDrawingMode(selectedMode: Int) -> Bool {
        let drawingMode = ["pen", "touch"]
        let defaults = UserDefaults.standard
        
        if (defaults.value(forKey: "drawingMode") as! Int == selectedMode) { return false }
        else { defaults.setValue(selectedMode, forKey: "drawingMode") }
        
        if (buttonViewWidth == nil) {
            buttonViewWidth = sideButtonView.frame.width
            panelViewWidth = panelCollectionView.frame.size.width
        }
        
        switch drawingMode[selectedMode] {
        case "pen":
            setPanelSize(
                width: panelViewWidth + buttonViewWidth,
                constant: 0
            )
            setVisibleSidButtonView(isHidden: true)
        case "touch":
            setPanelSize(
                width: panelViewWidth - buttonViewWidth,
                constant: -1 * buttonViewWidth
            )
            setVisibleSidButtonView(isHidden: false)
            canvas.setCenterTouchPosition()
            canvas.touchDrawingMode.setInitPosition()
        default:
            return false
        }
        if (canvas.selectedArea.isDrawing) {
            canvas.selectedArea.stopDrawOutlineInterval()
        }
        setCanvasDrawingMode(selectedMode)
        canvas.switchToolsInitSetting()
        canvas.updateAnimatedPreview()
        canvas.setNeedsDisplay()
        return true
    }
    
    func setPanelSize(width: CGFloat, constant: CGFloat) {
        colorPickerToolBar.sliderView.BGGradient.frame.size.width = width
        panelWidthContraint.constant = constant
        panelCollectionView.frame.size.width = width
        panelCollectionView.collectionViewLayout.invalidateLayout()
        previewImageToolBar.previewAndLayerCVC.collectionViewLayout.invalidateLayout()
    }
    
    func setCanvasDrawingMode(_ selectedMode: Int) {
        switch canvas.selectedDrawingTool {
        case "Picker", "Photo":
            canvas.selectedDrawingMode = "pen"
        default:
            canvas.selectedDrawingMode = selectedMode == 0 ? "pen" : "touch"
        }
    }
    
    func setVisibleSidButtonView(isHidden: Bool) {
        guard let sideButtonGroup = sideButtonViewGroup else { return }
        
        if (isHidden) {
            sideButtonGroup.isHidden = true
        } else {
            UIView.transition(with: sideButtonGroup, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                sideButtonGroup.isHidden = false
            })
        }
    }
    
    // undo 또는 redo하는 경우, 변경되는 Frame, Layer를 확인하기 쉽게 CollectionView 스크롤을 이동
    func checkSelectedFrameAndScroll(index: Int) {
        if (timeMachineVM.isSameSelectedFrameIndex(timeIndex: index) == false) {
            previewImageToolBar.setScrollToFrameList()
        } else if (timeMachineVM.isSameSelectedLayerIndex(timeIndex: index) == false) {
            previewImageToolBar.setScrollToLayerList()
        }
    }
}

// side button view
extension DrawingViewController {
    @IBAction func tappedChangeSide(_ sender: Any) {
        if (panelConstraint != nil) {
            panelConstraint.priority = UILayoutPriority(500)
            sideButtonGroupConstraint.priority = UILayoutPriority(500)
            sideButtonToCanvasConstraint.priority = UILayoutPriority(500)
            sideButtonToGroupConstraint.priority = UILayoutPriority(500)
        }
        switch currentSide {
        case .left:
            panelConstraint = panelCollectionView.leftAnchor.constraint(equalTo: canvasView.leftAnchor)
            sideButtonGroupConstraint = sideButtonViewGroup.rightAnchor.constraint(equalTo: view.rightAnchor)
            sideButtonToCanvasConstraint = sideButtonView.rightAnchor.constraint(equalTo: canvasView.rightAnchor, constant: 6)
            sideButtonToGroupConstraint = sideButtonView.leftAnchor.constraint(equalTo: sideButtonViewGroup.leftAnchor)
            topSideBtnImage.image = UIImage(systemName: "rectangle.lefthalf.inset.filled")
            currentSide = .right
        case .right:
            panelConstraint = panelCollectionView.rightAnchor.constraint(equalTo: canvasView.rightAnchor)
            sideButtonGroupConstraint = sideButtonViewGroup.leftAnchor.constraint(equalTo: view.leftAnchor)
            sideButtonToCanvasConstraint = sideButtonView.leftAnchor.constraint(equalTo: canvasView.leftAnchor, constant: -6)
            sideButtonToGroupConstraint = sideButtonView.rightAnchor.constraint(equalTo: sideButtonViewGroup.rightAnchor)
            topSideBtnImage.image = UIImage(systemName: "rectangle.righthalf.inset.filled")
            currentSide = .left
        case .top, .bottom, .none:
            return
        }
        panelConstraint.isActive = true
        sideButtonGroupConstraint.isActive = true
        sideButtonToGroupConstraint.isActive = true
        sideButtonToCanvasConstraint.isActive = true
        canvas.setNeedsDisplay()
    }
    
    @IBAction func touchUpExtensionBtn(_ sender: UIButton) {
        guard let superViewRect = getPopupViewPosition() else { return }
        let view = MiddleExtensionView(midSideBtnView, superViewRect, currentSide, setButtonImage)
        self.view.addSubview(view)
    }
    
    func getPopupViewPosition() -> CGRect? {
        guard let topInsets = sideButtonView.window?.safeAreaInsets.top else { return nil }
        guard let naviHeight = navigationController?.navigationBar.frame.height else { return nil }
        var x = sideButtonView.frame.minX
        let y = topInsets + naviHeight + midSideBtnView.frame.minY - 2.5
        let width = (midSideBtnView.frame.width + 12) * 2
        let height = midSideBtnView.frame.height + 5
        
        if (currentSide == .right) {
            x -= (midSideBtnView.frame.width + 12)
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    @IBAction func touchDownSideButton(_ sender: UIButton) {
        if (sender.tag == 1) {
            canvas.switchToolsSetUnused()
            canvas.selectedDrawingTool = CoreData.shared.selectedSubTool
            canvas.initTouchPosition = canvas.touchDrawingMode.cursorPosition
            canvas.switchToolsInitSetting()
            
            switch CoreData.shared.selectedSubTool {
            case "none":
                touchUpExtensionBtn(sender)
            case "Undo":
                checkSelectedFrameAndScroll(index: timeMachineVM.endIndex - 1)
                timeMachineVM.undo()
            case "Picker":
                canvas.selectedDrawingMode = "pen"
            default:
                break
            }
        } else {
            canvas.initTouchPosition = canvas.touchDrawingMode.cursorPosition
        }
        sideButtonAction(isDown: true, buttonNo: sender.tag)
        canvas.setNeedsDisplay()
    }
    
    @IBAction func touchUpSideButton(_ sender: UIButton) {
        sideButtonAction(isDown: false, buttonNo: sender.tag)
        if (sender.tag == 1) {
            canvas.selectedDrawingMode = "touch"
            canvas.switchToolsInitSetting()
            canvas.selectedDrawingTool = CoreData.shared.selectedMainTool
        }
        canvas.updateLayerImage(canvas.targetLayerIndex)
        canvas.updateAnimatedPreview()
        canvas.setNeedsDisplay()
    }
    
    func sideButtonAction(isDown: Bool, buttonNo: Int) {
        guard let target = buttonNo == 0 ? botSideBtn : midSideBtn else { return }
        
        setSideButtonBGColor(target: target, isDown: isDown)
        if (canvas.selectedDrawingMode == "touch") {
            canvas.activatedDrawing = isDown
            canvas.touchDrawingMode.changeCursorSelectedDrawingTool()
            if (isDown) { canvas.switchToolsButtonDown(buttonNo) }
            else { canvas.switchToolsButtonUp(buttonNo) }
        }
    }
    
    func setSideButtonBGColor(target: UIView, isDown: Bool) {
        if (target.window?.traitCollection.userInterfaceStyle == .light) {
            target.overrideUserInterfaceStyle = isDown ? .dark : .light
        } else {
            target.overrideUserInterfaceStyle = isDown ? .light : .dark
        }
    }
    
    func setButtonImage() {
        midSideBtnImage.image = UIImage(named: CoreData.shared.selectedSubTool)
        botSideBtnImage.image = UIImage(named: CoreData.shared.selectedMainTool)
    }
}

extension DrawingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return orderOfTools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case orderOfTools[0]:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewAndLayerCollectionViewCell", for: indexPath) as? PreviewAndLayerCollectionViewCell else { return UICollectionViewCell() }
            cell.canvas = canvas
            cell.layerVM = layerVM
            cell.animatedPreviewVM = animatedPreviewVM
            cell.drawingVC = self
            previewImageToolBar = cell
            layerVM.previewAndLayerCVC = cell
            animatedPreviewVM.targetView = cell.animatedPreviewUIView
            animatedPreviewVM.targetImageView = animatedPreviewVM.findImageViewOfUIView(cell.animatedPreviewUIView)
            animatedPreviewVM.viewModel = layerVM
            setSideCorner(target: cell, side: "all", radius: cell.frame.height / 15)
            return cell
            
        case orderOfTools[1]:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorPaletteCollectionViewCell", for: indexPath) as? ColorPaletteCollectionViewCell else { return UICollectionViewCell() }
            cell.drawingVC = self
            colorPickerToolBar = cell
            setSideCorner(target: cell, side: "all", radius: cell.frame.height / 15)
            return cell
            
        case orderOfTools[2]:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DrawingToolCollectionViewCell", for: indexPath) as? DrawingToolCollectionViewCell else { return UICollectionViewCell() }
            cell.drawingToolVM = drawingToolVM
            cell.timeMachineVM = timeMachineVM
            cell.drawingVC = self
            cell.panelCollectionView = self.panelCollectionView
            drawingToolBar = cell
            setSideCorner(target: cell, side: "all", radius: cell.frame.height / 15)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
}

extension DrawingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let modeHeight: CGFloat!
        let height: CGFloat!
        let drawingMode: Int!
        
        drawingMode = (UserDefaults.standard.value(forKey: "drawingMode") as! Int)
        modeHeight = drawingMode == 1 ? buttonViewWidth : 0
        height = (panelCollectionView.frame.width + modeHeight) * 0.3
        return CGSize(width: panelCollectionView.frame.width, height: height)
    }
}

extension DrawingViewController: UICollectionViewDelegate {
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        scrollPosition = panelCollectionView.contentOffset.y
//    }
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        scrollConstraint.priority = UILayoutPriority(200)
//        setScrollNavBarConstraint(scrollView)
//    }
//
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        let drawingMode: Int!
//        let ModeHeight: CGFloat!
//        let height: CGFloat!
//        let scrollOffset: CGFloat!
//
//        drawingMode = (UserDefaults.standard.value(forKey: "drawingMode") as! Int)
//        ModeHeight = drawingMode == 1 ? 30 : 0
//        height = ((panelCollectionView.bounds.width + ModeHeight) * 0.3) + 10
//        scrollOffset = scrollView.contentOffset.y - scrollPosition
//        if (scrollOffset > height / 4) {
//            scrollPanelNum += 1
//        } else if (scrollOffset < height / -4){
//            scrollPanelNum -= 1
//        }
//        targetContentOffset.pointee = CGPoint(x: 0, y: height * scrollPanelNum)
//    }
//
//    func setScrollNavBarConstraint(_ scrollView: UIScrollView) {
//        let viewHeight = scrollView.frame.width
//        let scrollRatio = scrollView.contentOffset.y / viewHeight
//        scrollConstraint = scrollNavBar.topAnchor.constraint(
//            equalTo: scrollNav.topAnchor,
//            constant: scrollNav.bounds.height * scrollRatio + 5
//        )
//        scrollConstraint.priority = UILayoutPriority(500)
//        scrollConstraint.isActive = true
//    }
}

