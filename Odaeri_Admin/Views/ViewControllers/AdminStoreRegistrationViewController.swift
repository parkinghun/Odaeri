//
//  AdminStoreRegistrationViewController.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import UIKit
import Combine
import SnapKit
import PhotosUI

final class AdminStoreRegistrationViewController: UIViewController {
    private let viewModel: AdminStoreRegistrationViewModel
    private var cancellables = Set<AnyCancellable>()

    var onRegistered: ((StoreEntity) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "가게 등록"
        label.font = AppFont.title1
        label.textColor = AppColor.gray90
        return label
    }()

    private let nameField = AdminFormFieldView(title: "가게 이름", placeholder: "가게 이름")
    private let categoryField = AdminFormFieldView(title: "카테고리", placeholder: "카테고리")
    private let descriptionField = AdminFormFieldView(title: "소개", placeholder: "설명")
    private let addressField = AdminFormFieldView(title: "주소", placeholder: "주소")
    private let latitudeField = AdminFormFieldView(title: "위도", placeholder: "예: 37.1234")
    private let longitudeField = AdminFormFieldView(title: "경도", placeholder: "예: 127.1234")
    private let openField = AdminFormFieldView(title: "오픈 시간", placeholder: "예: 09:00")
    private let closeField = AdminFormFieldView(title: "마감 시간", placeholder: "예: 22:00")
    private let parkingField = AdminFormFieldView(title: "주차 안내", placeholder: "주차 안내")
    private let hashTagsField = AdminFormFieldView(title: "해시태그", placeholder: "예: 커피,디저트")

    private let picchelinSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColor.deepSprout
        return toggle
    }()

    private let imageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("가게 이미지 추가", for: .normal)
        button.titleLabel?.font = AppFont.body2
        button.setTitleColor(AppColor.deepSprout, for: .normal)
        button.layer.borderColor = AppColor.deepSprout.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        return button
    }()

    private let imageCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray60
        label.text = "선택된 이미지 0장"
        return label
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("등록하기", for: .normal)
        button.titleLabel?.font = AppFont.body1Bold
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.backgroundColor = AppColor.deepSprout
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    private var selectedImages: [UIImage] = [] {
        didSet {
            imageCountLabel.text = "선택된 이미지 \(selectedImages.count)장"
        }
    }

    init(viewModel: AdminStoreRegistrationViewModel = AdminStoreRegistrationViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.gray0

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(nameField)
        contentView.addSubview(categoryField)
        contentView.addSubview(descriptionField)
        contentView.addSubview(addressField)
        contentView.addSubview(latitudeField)
        contentView.addSubview(longitudeField)
        contentView.addSubview(openField)
        contentView.addSubview(closeField)
        contentView.addSubview(parkingField)
        contentView.addSubview(hashTagsField)

        let picchelinRow = UIStackView(arrangedSubviews: [UILabel(), picchelinSwitch])
        let picchelinLabel = picchelinRow.arrangedSubviews.first as! UILabel
        picchelinLabel.text = "픽슐랭"
        picchelinLabel.font = AppFont.body2
        picchelinLabel.textColor = AppColor.gray90
        picchelinRow.axis = .horizontal
        picchelinRow.alignment = .center
        picchelinRow.distribution = .equalSpacing

        contentView.addSubview(picchelinRow)
        contentView.addSubview(imageButton)
        contentView.addSubview(imageCountLabel)
        contentView.addSubview(registerButton)
        contentView.addSubview(activityIndicator)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        let fields = [
            nameField, categoryField, descriptionField, addressField,
            latitudeField, longitudeField, openField, closeField,
            parkingField, hashTagsField
        ]

        var previous: UIView = titleLabel
        fields.forEach { field in
            field.snp.makeConstraints {
                $0.top.equalTo(previous.snp.bottom).offset(16)
                $0.leading.trailing.equalToSuperview().inset(24)
            }
            previous = field
        }

        picchelinRow.snp.makeConstraints {
            $0.top.equalTo(previous.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        imageButton.snp.makeConstraints {
            $0.top.equalTo(picchelinRow.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }

        imageCountLabel.snp.makeConstraints {
            $0.top.equalTo(imageButton.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(imageButton)
        }

        registerButton.snp.makeConstraints {
            $0.top.equalTo(imageCountLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
            $0.bottom.equalToSuperview().offset(-40)
        }

        activityIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(registerButton.snp.bottom).offset(16)
        }

        imageButton.addTarget(self, action: #selector(handleImageTap), for: .touchUpInside)
        latitudeField.textField.keyboardType = .decimalPad
        longitudeField.textField.keyboardType = .decimalPad
    }

    private func bind() {
        let input = AdminStoreRegistrationViewModel.Input(
            name: nameField.textPublisher,
            category: categoryField.textPublisher,
            description: descriptionField.textPublisher,
            address: addressField.textPublisher,
            latitude: latitudeField.textPublisher,
            longitude: longitudeField.textPublisher,
            open: openField.textPublisher,
            close: closeField.textPublisher,
            parkingGuide: parkingField.textPublisher,
            hashTags: hashTagsField.textPublisher,
            isPicchelin: picchelinSwitch.isOnPublisher,
            images: Just(selectedImages).merge(with: imageSelectionPublisher()).eraseToAnyPublisher(),
            submit: registerButton.tapPublisher()
        )

        let output = viewModel.transform(input: input)

        output.isSubmitEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.registerButton.isEnabled = isEnabled
                self?.registerButton.alpha = isEnabled ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "등록 실패", message: message)
            }
            .store(in: &cancellables)

        output.storeRegistered
            .receive(on: DispatchQueue.main)
            .sink { [weak self] store in
                self?.onRegistered?(store)
            }
            .store(in: &cancellables)
    }

    @objc private func handleImageTap() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func imageSelectionPublisher() -> AnyPublisher<[UIImage], Never> {
        let subject = PassthroughSubject<[UIImage], Never>()
        selectedImagesPublisher = subject
        return subject.eraseToAnyPublisher()
    }

    private var selectedImagesPublisher: PassthroughSubject<[UIImage], Never>?

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension AdminStoreRegistrationViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        selectedImages = []
        let providers = results.map { $0.itemProvider }
        let group = DispatchGroup()
        var images: [UIImage] = []
        providers.forEach { provider in
            if provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.selectedImages = images
            self?.selectedImagesPublisher?.send(images)
        }
    }
}

private final class AdminFormFieldView: UIView {
    let textField = UITextField()

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.font = AppFont.caption1
        titleLabel.textColor = AppColor.gray60
        textField.borderStyle = .roundedRect

        addSubview(titleLabel)
        addSubview(textField)

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
    }

    func configure(title: String, placeholder: String) {
        titleLabel.text = title
        textField.placeholder = placeholder
    }

    var textPublisher: AnyPublisher<String, Never> {
        textField.textPublisher.eraseToAnyPublisher()
    }
}

private extension AdminFormFieldView {
    convenience init(title: String, placeholder: String) {
        self.init(frame: .zero)
        configure(title: title, placeholder: placeholder)
    }
}

private extension UISwitch {
    var isOnPublisher: AnyPublisher<Bool, Never> {
        controlPublisher(for: .valueChanged)
            .map { [weak self] in self?.isOn ?? false }
            .prepend(isOn)
            .eraseToAnyPublisher()
    }
}

private extension UIControl {
    func controlPublisher(for event: UIControl.Event) -> AnyPublisher<Void, Never> {
        let subject = PassthroughSubject<Void, Never>()
        addAction(UIAction { _ in subject.send(()) }, for: event)
        return subject.eraseToAnyPublisher()
    }
}
