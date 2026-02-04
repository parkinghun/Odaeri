//
//  AdminStoreManagementDetailViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import UIKit
import Combine
import SnapKit
import PhotosUI

final class AdminStoreManagementDetailViewController: UIViewController {
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let saveStoreSubject = PassthroughSubject<AdminStoreFormData, Never>()
    private let saveMenuSubject = PassthroughSubject<AdminMenuFormData, Never>()
    private var store: StoreEntity?
    private var selectedItem: AdminStoreManagementItem = .storeInfo

    var viewDidLoadPublisher: AnyPublisher<Void, Never> {
        viewDidLoadSubject.eraseToAnyPublisher()
    }

    var saveStorePublisher: AnyPublisher<AdminStoreFormData, Never> {
        saveStoreSubject.eraseToAnyPublisher()
    }

    var saveMenuPublisher: AnyPublisher<AdminMenuFormData, Never> {
        saveMenuSubject.eraseToAnyPublisher()
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "가게 정보를 불러오는 중입니다."
        label.font = AppFont.body2
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let storeFormView = AdminStoreFormView()
    private let menuFormView = AdminMenuFormView()
    private var imagePickTarget: AdminImagePickTarget?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewDidLoadSubject.send(())
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = Layout.sectionSpacing
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.pageInsets)
        }

        contentStack.addArrangedSubview(storeFormView)
        contentStack.addArrangedSubview(menuFormView)

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func bind() {
        storeFormView.onSave = { [weak self] data in
            self?.saveStoreSubject.send(data)
        }
        storeFormView.onPickImages = { [weak self] in
            self?.presentImagePicker(target: .store)
        }
        menuFormView.onSave = { [weak self] data in
            self?.saveMenuSubject.send(data)
        }
        menuFormView.onPickImage = { [weak self] in
            self?.presentImagePicker(target: .menu)
        }
    }

    func update(store: StoreEntity?, selectedItem: AdminStoreManagementItem) {
        self.store = store
        self.selectedItem = selectedItem
        emptyLabel.isHidden = store != nil
        scrollView.isHidden = store == nil

        guard let store else { return }
        switch selectedItem {
        case .storeInfo:
            storeFormView.isHidden = false
            menuFormView.isHidden = true
            storeFormView.configure(store: store)
        case .addMenu:
            storeFormView.isHidden = true
            menuFormView.isHidden = false
            menuFormView.configureForNewMenu()
        case .menu(let menu):
            storeFormView.isHidden = true
            menuFormView.isHidden = false
            menuFormView.configure(menu: menu)
        }
    }

    private func presentImagePicker(target: AdminImagePickTarget) {
        imagePickTarget = target
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = target == .store ? 0 : 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension AdminStoreManagementDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let target = imagePickTarget else { return }

        let providers = results.map(\.itemProvider)
        let group = DispatchGroup()
        var images: [UIImage] = []

        for provider in providers where provider.canLoadObject(ofClass: UIImage.self) {
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    images.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            switch target {
            case .store:
                self.storeFormView.appendSelectedImages(images)
            case .menu:
                if let image = images.first {
                    self.menuFormView.updateSelectedImage(image)
                }
            }
        }
    }
}

private enum AdminImagePickTarget {
    case store
    case menu
}

private final class AdminStoreFormView: UIView {
    private let titleLabel = UILabel()
    private let nameField = AdminFormFieldView(title: "가게명")
    private let categoryField = AdminFormFieldView(title: "카테고리")
    private let descriptionField = AdminFormFieldView(title: "설명")
    private let addressField = AdminFormFieldView(title: "주소")
    private let longitudeField = AdminFormFieldView(title: "경도")
    private let latitudeField = AdminFormFieldView(title: "위도")
    private let openField = AdminFormFieldView(title: "오픈")
    private let closeField = AdminFormFieldView(title: "마감")
    private let tagsField = AdminFormFieldView(title: "해시태그")
    private let parkingLabel = UILabel()
    private let parkingSegment = UISegmentedControl(items: ["가능", "불가"])
    private let picchelinLabel = UILabel()
    private let picchelinSwitch = UISwitch()
    private let imageTitleLabel = UILabel()
    private let imageScrollView = UIScrollView()
    private let imageStackView = UIStackView()
    private let imageAddButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)

    var onSave: ((AdminStoreFormData) -> Void)?
    var onPickImages: (() -> Void)?

    private var imageUrls: [String] = []
    private var selectedImages: [UIImage] = []
    private let openPicker = UIDatePicker()
    private let closePicker = UIDatePicker()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.text = "가게 정보 수정"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        longitudeField.keyboardType = .decimalPad
        latitudeField.keyboardType = .decimalPad
        openField.setInputView(openPicker)
        closeField.setInputView(closePicker)
        openField.setAccessoryToolbar(title: "오픈 시간 선택")
        closeField.setAccessoryToolbar(title: "마감 시간 선택")
        openPicker.datePickerMode = .time
        openPicker.preferredDatePickerStyle = .wheels
        closePicker.datePickerMode = .time
        closePicker.preferredDatePickerStyle = .wheels
        openPicker.addTarget(self, action: #selector(handleOpenTimeChanged), for: .valueChanged)
        closePicker.addTarget(self, action: #selector(handleCloseTimeChanged), for: .valueChanged)

        parkingLabel.text = "주차"
        parkingLabel.font = AppFont.body2
        parkingLabel.textColor = AppColor.gray75
        parkingSegment.selectedSegmentIndex = 1

        picchelinLabel.text = "픽슐랭"
        picchelinLabel.font = AppFont.body2
        picchelinLabel.textColor = AppColor.gray75

        imageTitleLabel.text = "가게 이미지"
        imageTitleLabel.font = AppFont.body2
        imageTitleLabel.textColor = AppColor.gray75

        imageStackView.axis = .horizontal
        imageStackView.spacing = Layout.imageSpacing
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.addSubview(imageStackView)

        imageAddButton.setTitle("이미지 추가", for: .normal)
        imageAddButton.setTitleColor(AppColor.gray90, for: .normal)
        imageAddButton.backgroundColor = AppColor.gray30
        imageAddButton.layer.cornerRadius = Layout.buttonCornerRadius
        imageAddButton.addTarget(self, action: #selector(handlePickImages), for: .touchUpInside)

        saveButton.setTitle("가게 정보 저장", for: .normal)
        saveButton.setTitleColor(AppColor.gray0, for: .normal)
        saveButton.backgroundColor = AppColor.deepSprout
        saveButton.layer.cornerRadius = Layout.buttonCornerRadius
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        let picchelinStack = UIStackView(arrangedSubviews: [picchelinLabel, UIView(), picchelinSwitch])
        picchelinStack.axis = .horizontal
        picchelinStack.alignment = .center

        let parkingStack = UIStackView(arrangedSubviews: [parkingLabel, UIView(), parkingSegment])
        parkingStack.axis = .horizontal
        parkingStack.alignment = .center

        let imageHeaderStack = UIStackView(arrangedSubviews: [imageTitleLabel, UIView(), imageAddButton])
        imageHeaderStack.axis = .horizontal
        imageHeaderStack.alignment = .center

        let basicInfoHeader = sectionHeader("기본 정보")
        let timeHeader = sectionHeader("영업 설정")
        let locationHeader = sectionHeader("위치 정보")
        let etcHeader = sectionHeader("태그 및 편의")

        let categoryRow = twoColumnRow(left: categoryField, right: descriptionField)
        let timeRow = twoColumnRow(left: openField, right: closeField)
        let locationRow = twoColumnRow(left: longitudeField, right: latitudeField)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            basicInfoHeader,
            nameField,
            categoryRow,
            timeHeader,
            timeRow,
            locationHeader,
            addressField,
            locationRow,
            etcHeader,
            tagsField,
            parkingStack,
            picchelinStack,
            imageHeaderStack,
            imageScrollView,
            saveButton
        ])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cardInsets)
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
        }

        imageAddButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(90)
            $0.height.equalTo(Layout.smallButtonHeight)
        }

        imageScrollView.snp.makeConstraints {
            $0.height.equalTo(Layout.imageHeight)
        }

        imageStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    func configure(store: StoreEntity) {
        nameField.text = store.name
        categoryField.text = store.category
        descriptionField.text = store.description
        addressField.text = store.address
        longitudeField.text = "\(store.longitude)"
        latitudeField.text = "\(store.latitude)"
        openField.text = store.open
        closeField.text = store.close
        parkingSegment.selectedSegmentIndex = store.parkingGuide.isEmpty ? 1 : 0
        tagsField.text = store.hashTags.joined(separator: ", ")
        picchelinSwitch.isOn = store.isPicchelin
        imageUrls = store.storeImageUrls
        selectedImages = []
        reloadImages()
    }

    func appendSelectedImages(_ images: [UIImage]) {
        selectedImages.append(contentsOf: images)
        reloadImages()
    }

    @objc private func handleSave() {
        let tags = tagsField.text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let parkingGuide = parkingSegment.selectedSegmentIndex == 0 ? "가능" : "불가"
        let data = AdminStoreFormData(
            name: nameField.text,
            category: categoryField.text,
            description: descriptionField.text,
            address: addressField.text,
            longitude: longitudeField.text,
            latitude: latitudeField.text,
            open: openField.text,
            close: closeField.text,
            parkingGuide: parkingGuide,
            tags: tags.filter { !$0.isEmpty },
            storeImageUrls: imageUrls,
            newImages: selectedImages,
            isPicchelin: picchelinSwitch.isOn
        )
        onSave?(data)
    }

    @objc private func handleOpenTimeChanged() {
        openField.text = timeString(from: openPicker.date)
    }

    @objc private func handleCloseTimeChanged() {
        closeField.text = timeString(from: closePicker.date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func sectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = AppFont.body2Bold
        label.textColor = AppColor.gray90
        return label
    }

    private func twoColumnRow(left: UIView, right: UIView) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [left, right])
        stack.axis = .horizontal
        stack.spacing = Layout.fieldSpacing * 2
        stack.distribution = .fillEqually
        return stack
    }

    @objc private func handlePickImages() {
        onPickImages?()
    }

    private func reloadImages() {
        imageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let urls = imageUrls
        urls.forEach { url in
            let imageView = AdminImagePreviewView()
            imageView.configure(url: url, image: nil)
            imageView.snp.makeConstraints {
                $0.width.equalTo(Layout.imageHeight)
            }
            imageStackView.addArrangedSubview(imageView)
        }

        selectedImages.forEach { image in
            let imageView = AdminImagePreviewView()
            imageView.configure(url: nil, image: image)
            imageView.snp.makeConstraints {
                $0.width.equalTo(Layout.imageHeight)
            }
            imageStackView.addArrangedSubview(imageView)
        }

        if imageStackView.arrangedSubviews.isEmpty {
            let placeholder = AdminImagePreviewView()
            placeholder.configure(url: nil, image: nil)
            placeholder.snp.makeConstraints {
                $0.width.equalTo(Layout.imageHeight)
            }
            imageStackView.addArrangedSubview(placeholder)
        }
    }
}

private final class AdminMenuFormView: UIView {
    private let titleLabel = UILabel()
    private let nameField = AdminFormFieldView(title: "메뉴명")
    private let categoryField = AdminFormFieldView(title: "카테고리")
    private let descriptionField = AdminFormFieldView(title: "설명")
    private let originField = AdminFormFieldView(title: "원산지")
    private let priceField = AdminFormFieldView(title: "가격")
    private let tagsField = AdminFormFieldView(title: "태그")
    private let soldOutSwitch = UISwitch()
    private let soldOutLabel = UILabel()
    private let imageView = AdminImagePreviewView()
    private let imageButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var menuId: String = ""
    private var currentImageUrl: String?
    private var selectedImage: UIImage?

    var onSave: ((AdminMenuFormData) -> Void)?
    var onPickImage: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray15
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.text = "메뉴 정보 수정"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.gray90

        priceField.keyboardType = .numberPad

        soldOutLabel.text = "품절"
        soldOutLabel.font = AppFont.body2
        soldOutLabel.textColor = AppColor.gray75

        let soldOutStack = UIStackView(arrangedSubviews: [soldOutLabel, UIView(), soldOutSwitch])
        soldOutStack.axis = .horizontal
        soldOutStack.alignment = .center

        imageButton.setTitle("이미지 변경", for: .normal)
        imageButton.setTitleColor(AppColor.gray90, for: .normal)
        imageButton.backgroundColor = AppColor.gray30
        imageButton.layer.cornerRadius = Layout.buttonCornerRadius
        imageButton.addTarget(self, action: #selector(handlePickImage), for: .touchUpInside)

        saveButton.setTitle("메뉴 정보 저장", for: .normal)
        saveButton.setTitleColor(AppColor.gray0, for: .normal)
        saveButton.backgroundColor = AppColor.deepSprout
        saveButton.layer.cornerRadius = Layout.buttonCornerRadius
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            imageView,
            imageButton,
            nameField,
            categoryField,
            descriptionField,
            originField,
            priceField,
            tagsField,
            soldOutStack,
            saveButton
        ])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Layout.cardInsets)
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(Layout.buttonHeight)
        }

        imageView.snp.makeConstraints {
            $0.height.equalTo(Layout.imageHeight)
        }

        imageButton.snp.makeConstraints {
            $0.height.equalTo(Layout.smallButtonHeight)
        }
    }

    func configure(menu: MenuEntity) {
        titleLabel.text = "메뉴 정보 수정"
        menuId = menu.menuId
        nameField.text = menu.name
        categoryField.text = menu.category
        descriptionField.text = menu.description
        originField.text = menu.originInformation
        priceField.text = "\(menu.priceValue)"
        tagsField.text = menu.tags.joined(separator: ", ")
        soldOutSwitch.isOn = menu.isSoldOut
        currentImageUrl = menu.menuImageUrl
        selectedImage = nil
        imageView.configure(url: currentImageUrl, image: nil)
    }

    func configureForNewMenu() {
        titleLabel.text = "메뉴 등록"
        menuId = ""
        nameField.text = ""
        categoryField.text = ""
        descriptionField.text = ""
        originField.text = ""
        priceField.text = ""
        tagsField.text = ""
        soldOutSwitch.isOn = false
        currentImageUrl = nil
        selectedImage = nil
        imageView.configure(url: nil, image: nil)
    }

    func updateSelectedImage(_ image: UIImage) {
        selectedImage = image
        imageView.configure(url: nil, image: image)
    }

    @objc private func handleSave() {
        let tags = tagsField.text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let data = AdminMenuFormData(
            menuId: menuId,
            name: nameField.text,
            description: descriptionField.text,
            originInformation: originField.text,
            price: priceField.text,
            category: categoryField.text,
            tags: tags.filter { !$0.isEmpty },
            isSoldOut: soldOutSwitch.isOn,
            menuImage: selectedImage
        )
        onSave?(data)
    }

    @objc private func handlePickImage() {
        onPickImage?()
    }
}

private final class AdminImagePreviewView: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColor.gray30
        layer.cornerRadius = Layout.imageCornerRadius
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(url: String?, image: UIImage?) {
        if let image {
            imageView.image = image
            return
        }
        imageView.setImage(url: url, placeholder: UIImage(systemName: "photo"))
    }
}

private final class AdminFormFieldView: UIView {
    private let titleLabel = UILabel()
    private let textField = UITextField()

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    func setInputView(_ view: UIView) {
        textField.inputView = view
    }

    func setAccessoryToolbar(title: String) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let titleItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        titleItem.isEnabled = false
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: textField, action: #selector(UIResponder.resignFirstResponder))
        toolbar.items = [titleItem, spacer, done]
        textField.inputAccessoryView = toolbar
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.font = AppFont.caption1
        titleLabel.textColor = AppColor.gray60

        textField.borderStyle = .roundedRect
        textField.font = AppFont.body2
        textField.textColor = AppColor.gray90

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField])
        stack.axis = .vertical
        stack.spacing = Layout.fieldSpacing

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

private enum Layout {
    static let pageInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    static let cardInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let sectionSpacing: CGFloat = 16
    static let fieldSpacing: CGFloat = 6
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 44
    static let smallButtonHeight: CGFloat = 36
    static let imageHeight: CGFloat = 96
    static let imageCornerRadius: CGFloat = 10
    static let imageSpacing: CGFloat = 8
}
