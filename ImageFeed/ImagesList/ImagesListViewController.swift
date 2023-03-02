import UIKit
import Kingfisher

class ImagesListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Private properties
    private var photos: [Photo] = []
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imageListService = ImageListService.shared
    private var imageListServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
//        imageListService.fetchPhotosNextPage()
        
        imageListServiceObserver = NotificationCenter.default
            .addObserver(forName: ImageListService.didChangeNotification,
                         object: nil,
                         queue: .main,
                         using: { [weak self] _ in
                guard let self = self else { return }
                self.updateTableViewAnimated()
            })
    }
    
    // MARK: - Override methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupView() {
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func updateTableViewAnimated() {
        let oldPhotoCount = photos.count
        let newPhotoCount = imageListService.photos.count
        photos = imageListService.photos
        
        if oldPhotoCount != newPhotoCount {
            tableView.performBatchUpdates {
                let indexPath = (oldPhotoCount..<newPhotoCount).map { IndexPath(row: $0, section: 0)}
                tableView.insertRows(at: indexPath, with: .automatic)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard
            let imagesListCell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as? ImagesListCell else { return UITableViewCell() }
        let photo = photos[indexPath.row]
        
        var dateString: String
        
        if let date = photo.createdAt {
            dateString = dateFormatter.string(from: date)
        } else {
            dateString = ""
        }
        
        let image = photo.thumbImageURL
        imagesListCell.selectionStyle = .none
        return imagesListCell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSingleImage", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count-1 {
            imageListService.fetchPhotosNextPage()
        }
    }
    
    func reloadCellHeight(numberRow: Int) {
        let indexPath = IndexPath(item: numberRow, section: 0)
        
        tableView.performBatchUpdates {
            tableView.reloadRows(at: [indexPath], with: .automatic )
        }
    }
}

//extension ImagesListViewController: ImagesListCellDelegate {
//    func reloadCellHeight(numberRow: Int) {
//        let indexPath = IndexPath(item: numberRow, section: 0)
//
//        tableView.performBatchUpdates {
//            tableView.reloadRows(at: [indexPath], with: .automatic )
//        }
//    }
//    
//    func imageListCellDidTapeLike(_ cell: ImagesListCell) {
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        let photo = photos[indexPath.row]
//        
//        UIBlockingProgressHUD.show()
//        imageListService.changeLike(idPhoto: photo.id, isLike: !photo.isLiked) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success:
//                self.photos = self.imageListService.photos
//                cell.setIsLiked(isLiked: self.photos[indexPath.row].isLiked)
//                UIBlockingProgressHUD.dismiss()
//            case .failure(let failure):
//                print(failure)
//                UIBlockingProgressHUD.dismiss()
//            }
//        }
//    }
//}

/*
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == ShowSingleImageSegueIdentifier {
        let viewController = segue.destination as! SingleImageViewController
        let indexPath = sender as! IndexPath
        let image = UIImage(named: photosName[indexPath.row])
        viewController.image = image
    } else {
        super.prepare(for: segue, sender: sender)
    }
}
}

extension ImagesListViewController: UITableViewDataSource {
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return photosName.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)

    guard let imageListCell = cell as? ImagesListCell else {
        return UITableViewCell()
    }

    configCell(for: imageListCell, with: indexPath)

    return imageListCell
}
}

extension ImagesListViewController {
func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
    guard let image = UIImage(named: photosName[indexPath.row]) else {
        return
    }
    
    cell.cellImage.image = image
    cell.dateLabel.text = dateFormatter.string(from: Date())
    
    let isLiked = indexPath.row % 2 == 0
    let likeImage = isLiked ? UIImage(named: "LikeActive") : UIImage(named: "Like")
    cell.likeButton.setImage(likeImage, for: .normal)
}
}

extension ImagesListViewController: UITableViewDelegate {
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: "ShowSingleImage", sender: indexPath)
}

func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let image = UIImage(named: photosName[indexPath.row]) else {
        return 0
    }
    
    let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
    let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
    let imageWidth = image.size.width
    let scale = imageViewWidth / imageWidth
    let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
    return cellHeight
}

//12 спринт
func tableView(
  _ tableView: UITableView,
  willDisplay cell: UITableViewCell,
  forRowAt indexPath: IndexPath
) {
    // ...
}
}

extension ImagesListViewController {
func updateTableViewAnimated() {
    let oldCount = photos.count
    let newCount = imagesListService.photos.count
    photos = imagesListService.photos
    if oldCount != newCount {
        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { i in
                IndexPath(row: i, section: 0)
            }
            tableView.insertRows(at: indexPaths, with: .automatic)
        } completion: { _ in }
    }
}
}

*/
