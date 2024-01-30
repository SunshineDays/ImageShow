//
//  ImageShow.swift
//  Sunshine
//
//  Created by Sunshine Days on 2021/12/28.
//

import UIKit

/// 当前Sence
let CurrentScene = UIApplication.shared.connectedScenes.filter{$0.activationState == .foregroundActive || $0.activationState == .foregroundInactive}.compactMap{$0 as? UIWindowScene}.first
/// 屏宽
let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
/// 屏高
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
/// 状态栏高度
let kStatusBarHeight: CGFloat = CurrentScene?.statusBarManager?.statusBarFrame.size.height ?? 20.0

/// 查看图片
struct ImageShow {
    
    /// 展示图片
    /// 支持双击放大，缩放等
    /// 预览时：图片会在点击位置放大
    /// 关闭时：图片会缩小到点击位置
    /// - Parameters:
    ///   - images: 图片数组[String]、[UIImage]
    ///   - index: 默认选中哪一个
    ///   - view: 来自于哪张图片的view
    ///   - views: 图片数组所在的views，可以只传在页面上展示的
    static func show(_ images: [Any], at index: Int, from view: UIView, in views: [UIView]) {
        guard let keyWindow = kKeyWindow else { return }
        
        // 把frame先拿出来，如果直接在block中引用view。会造成循环引用，导致内存泄漏
        let fromFrame = view.convert(view.bounds, to: UIScreen.main.coordinateSpace)
        let viewFrames = views.map { $0.convert(view.bounds, to: UIScreen.main.coordinateSpace) }

        let scrollView = ImagesShowView(frame: .init(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
        scrollView.set(images: images, defaultIndex: index) { imageView, dismissIndex in
            
            // 获取 点击的图片 所在view的 下标
            if let startIndex = viewFrames.firstIndex(where: { $0 == fromFrame }) {
                // 获取 关闭的图片 所在view的 下标
                if let frame = viewFrames[safe: startIndex + (dismissIndex - index)] {
                    let animteImageView = UIImageView(frame: imageView.frame)
                    animteImageView.image = imageView.image
                    animteImageView.contentMode = .scaleAspectFill
                    animteImageView.clipsToBounds = true
                    keyWindow.addSubview(animteImageView)
                    
                    UIView.animate(withDuration: 0.3) {
                        animteImageView.frame = frame
                        scrollView.backgroundColor = .clear
                    } completion: { isFinished in
                        scrollView.removeFromSuperview()
                        animteImageView.removeFromSuperview()
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        scrollView.backgroundColor = .clear
                    } completion: { isFinished in
                        scrollView.removeFromSuperview()
                    }
                }
            }
        }
        keyWindow.addSubview(scrollView)
        
        if let subviews = scrollView.scrollView.subviews[safe: index]?.subviews, let imageView = subviews.first(where: { $0 is UIImageView }) as? UIImageView {
            imageView.isHidden = true
            
            let animteImageView = UIImageView(frame: fromFrame)
            animteImageView.image = imageView.image
            animteImageView.contentMode = .scaleAspectFill
            animteImageView.clipsToBounds = true
            keyWindow.addSubview(animteImageView)
            
            UIView.animate(withDuration: 0.3) {
                animteImageView.frame = imageView.frame
                scrollView.backgroundColor = .black
            } completion: { isFinished in
                animteImageView.removeFromSuperview()
                imageView.isHidden = false
            }
        }
    }
}


/// 查看图片弹窗（单张/多张）
class ImagesShowView: UIView, UIScrollViewDelegate {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        return scrollView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: kStatusBarHeight, width: kScreenWidth, height: 44))
        label.set(nil, textColor: .white, font: UIFont.systemFont(ofSize: 15), textAlignment: .center)
        addSubview(label)
        return label
    }()
    
    private var count = 0 {
        didSet {
            titleLabel.isHidden = count <= 1
        }
    }
    
    private var selectedIndex = 0
    
 
    /// images中可以包含url或image
    func set(images: [Any], defaultIndex: Int, dismissBlock: ((_ imageView: UIImageView, _ index: Int) -> Void)? = nil) {
        count = images.count
        scrollView.contentSize = CGSize(width: kScreenWidth * CGFloat(images.count), height: 0)
        for (index, image) in images.enumerated() {
            let scrollView = ShowImageScrollView(frame: CGRect(x: kScreenWidth * CGFloat(index), y: 0, width: kScreenWidth, height: kScreenHeight))
            if let image = image as? UIImage {
                scrollView.image = image
            }
            if let url = image as? String {
                scrollView.imageUrl = url
            }
            if let data = image as? Data {
                scrollView.image = UIImage(data: data) ?? .nonePicture
            }
            scrollView.dismissBlock = { imageView in
                dismissBlock?(imageView, index)
            }
            self.scrollView.addSubview(scrollView)
        }
        scrollView.setContentOffset(CGPoint(x: kScreenWidth * CGFloat(defaultIndex), y: 0), animated: false)
        titleLabel.text = "\(defaultIndex + 1)/\(images.count)"
        selectedIndex = defaultIndex
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(scrollView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / kScreenWidth)
        titleLabel.text = "\(index + 1)/\(count)"
        selectedIndex = index
    }
}


/// 单张图片查看view，可以放大、缩小、拖动等
fileprivate class ShowImageScrollView: UIScrollView, UIScrollViewDelegate {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    /// 最小缩放比例
    private var minScale: CGFloat = 1.0
    /// 最大缩放比例
    private var maxScale: CGFloat = 10.0
    
    public var image = UIImage() {
        didSet {
            layoutImageView()
        }
    }
    
    public var imageUrl = "" {
        didSet {
            if let url = URL(string: imageUrl) {
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    if let info = try? result.get() {
                        self.image = info.image
                    }
                }
            }
        }
    }
    
    public var dismissBlock: ((_ imageView: UIImageView) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        kKeyWindow?.endEditing(true)
        
        delegate = self
        minimumZoomScale = minScale
        maximumZoomScale = maxScale
        backgroundColor = .clear
        addSubview(imageView)
        
        // 单击
        let tapSingleRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapSingleClick(_:)))
        tapSingleRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapSingleRecognizer)

        // 双击
        let tapDoubleRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDoubleClick(_:)))
        tapDoubleRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(tapDoubleRecognizer)
        
        // 当没有检测到双击时，才响应单击
        tapSingleRecognizer.require(toFail: tapDoubleRecognizer)
                
        // 下滑
        let swipeDownRecoginzer = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownClick(_:)))
        swipeDownRecoginzer.direction = .down
        addGestureRecognizer(swipeDownRecoginzer)
        
        // 长按
        let longPressRecoginzer = UILongPressGestureRecognizer(target: self, action: #selector(longPressClick(_:)))
        longPressRecoginzer.minimumPressDuration = 1.0
        addGestureRecognizer(longPressRecoginzer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = bounds.size.width > contentSize.width ? (bounds.size.width - contentSize.width) * 0.5 : 0
        let offsetY = bounds.size.height > contentSize.height ? (bounds.size.height - contentSize.height) * 0.5 : 0
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    // 单击
    @objc private func tapSingleClick(_ gesture: UITapGestureRecognizer) {
        removeFromSuperview()
        dismissBlock?(imageView)
    }
    
    // 双击
    @objc private func tapDoubleClick(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minScale {
            setZoomScale(minScale, animated: true)
        } else {
            let touchPoint = gesture.location(in: imageView)
            let newZoomScale = maximumZoomScale
            let xSize = frame.size.width / newZoomScale
            let ySize = frame.size.height / newZoomScale
            zoom(to: CGRect(x: touchPoint.x - xSize / 2, y: touchPoint.y - ySize / 2, width: xSize, height: ySize), animated: true)
        }
    }
            
    // 下滑
    @objc private func swipeDownClick(_ gesture: UISwipeGestureRecognizer) {
        removeFromSuperview()
        dismissBlock?(imageView)
    }
    
    // 长按
    @objc private func longPressClick(_ gesture: UILongPressGestureRecognizer) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet)
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { [weak self] (action) in
            if let image = self?.imageView.image {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        AppCurrentVC?.present(alertController, sourceView: imageView)
    }

    @objc private func image(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
        if didFinishSavingWithError == nil {
            print("已保存到相册")
        }  else {
            print("保存失败")
        }
    }
    
    private func layoutImageView() {
        var imageFrame = CGRect()

        imageFrame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenWidth * image.size.height / image.size.width)
        if imageFrame.height < bounds.size.height {
            imageFrame.origin.y = (bounds.size.height - imageFrame.height) / 2
        }
        contentSize = CGSize(width: imageFrame.width, height: imageFrame.height)
        
        imageView.frame = imageFrame
        imageView.image = image
    }
}
