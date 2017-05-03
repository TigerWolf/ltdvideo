import Firebase
import UIKit
import Photos // needed?
import MobileCoreServices
import DZNEmptyDataSet
import AVFoundation
import DKImagePickerController
import FirebaseDatabase

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet private weak var progressLabel:UILabel!
	@IBOutlet private weak var table:UITableView!
	
    let imagePicker = UIImagePickerController()
    
    var urlTextView: UITextField!
//    var storageRef: FIRStorageReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.retreiveFromFile()
        
        let uploadButton = UIButton(frame: CGRect(x:20, y:150, width:300, height:40))
        uploadButton.setTitle("Upload file", for: .normal)
        uploadButton.backgroundColor = .blue
        uploadButton.addTarget(self, action: #selector(selectAndUpload), for: .touchUpInside)
        
//        self.navigationController?.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(selectAndUpload))]
        self.navigationItem.rightBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(selectAndUpload))
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(signout))

//        view.addSubview(uploadButton)

        // A little trick for removing the cell separators
        table.tableFooterView = UIView()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		FIRAuth.auth()?.addStateDidChangeListener {auth, user in
			if let user = user {
				NSLog("User is signed in.")
				// Nothing to do, proceed
			} else {
				NSLog("User is signed out. Show login view.")
				// Show login view
				if let lvc = self.storyboard?.instantiateViewController(withIdentifier:"LoginViewController") {
					self.present(lvc, animated:true, completion:nil)
				}
			}
		}
	}
	
    func signout() {
        
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
//        try! FIRAuth.auth()!.signOut()
//        self.removeFromParentViewController()
        dismiss(animated: true, completion: nil)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Upload a file. ")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Click the + to start.")
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "uploadicon")
    }
    
    func selectAndUpload2(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String] //[kUTTypeMovie as String]
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func selectAndUpload(_ sender: UIButton) {
        let pickerController = DKImagePickerController()
        
//        pickerCon
         pickerController.assetType = .allAssets // .allVideos
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            print("didSelectAssets")
            print(assets)
            assets.forEach { asset in
                self.uploadAsset(dk_asset: asset)
            }
        }
        
//        self.presentViewController(pickerController, animated: true) {}
        self.present(pickerController, animated: true)
    }
    
    func storeFilenameInDB(metadata: FIRStorageMetadata) {
        
        let downloadURL = metadata.downloadURL()
        
        let ref = FIRDatabase.database().reference()
        let key = ref.child("uploads").childByAutoId().key
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM EEEE HH:mm"
        let result = formatter.string(from: date)

        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let uid = user.uid
            let email = user.email
            
            let dictionaryUser = [
                "uid": uid,
                "userName": email!,
                "imageUrl": downloadURL?.absoluteString ?? "",
                "path": metadata.path!,
                "created": result
            ]
            
            let childUpdates = ["/uploads/\(key)": dictionaryUser]
            ref.updateChildValues(childUpdates, withCompletionBlock: { (error, ref) -> Void in
                //save
            })
        }
        
    }
    
    func uploadAsset(dk_asset: DKAsset){

        let videoUpload = VideoUpload()
        // TODO: check if this is safe
        let filename = dk_asset.originalAsset?.value(forKey: "filename")
        videoUpload.originalFilename = filename as! String
        
        if (dk_asset.isVideo) {
            dk_asset.fetchAVAssetWithCompleteBlock({(asset: AVAsset?, avinfo: [AnyHashable : Any]?) in
                NSLog("fetching AV - uploading")
                dk_asset.fetchImageWithSize(CGSize(width: 200, height: 200), completeBlock: { (thumbnailImage: UIImage?,  tninfo: [AnyHashable: Any]?) in
                    NSLog("fetching TN - uploading")
                    videoUpload.thumbnail = thumbnailImage ?? UIImage()
                })
                
                // TODO: Save thumbnail image to object
                let asset = asset as? AVURLAsset
                do {
                    let video = try NSData(contentsOf: (asset?.url)!, options: .mappedIfSafe)
                    self.uploadData(data: video, videoUpload: videoUpload)
                } catch {
                    print(error)
                    return
                }


            })
        } else {
//            dk_asset.fetchOriginalImage(<#T##sync: Bool##Bool#>, completeBlock: <#T##(UIImage?, [AnyHashable : Any]?) -> Void#>)
            dk_asset.fetchOriginalImageWithCompleteBlock({(asset: UIImage?, info: [AnyHashable : Any]?) in
              let image = UIImageJPEGRepresentation(asset!, 1.0)!
            videoUpload.thumbnail = asset!
              self.uploadData(data: image as NSData, videoUpload: videoUpload)
            })
        }
        
    }
    
    func uploadData(data: NSData, videoUpload: VideoUpload){
        
        NSLog("data uploading")
        let storage = FIRStorage.storage()
        // Create a root reference
        let storageRef = storage.reference()
        
        FIRAnalytics.logEvent(withName: "upload_started", parameters: nil)
        
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let fileExtension = ".mp4"
        // Create a reference to the file you want to upload
        let filePath = FIRAuth.auth()!.currentUser!.uid +
        "/\(year)-\(month)/\(self.formattedDate())\(fileExtension)"
        
        let fileRef = storageRef.child(filePath)
        
        let uploadTask = fileRef.put(data as Data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            if let error = error {
                print("Error uploading: \(error)")
                DispatchQueue.main.async {
                    self.urlTextView.text = "Upload Failed"
                }
                return
            }
            self.uploadSuccess(metadata, storagePath: filePath, videoUpload: videoUpload)
        }
        
        // Add a progress observer to an upload task
        uploadTask.observe(.progress) { snapshot in
			self.table.reloadData()
        }
        
        
        videoUpload.firebaseUploadRef = uploadTask
        self.files.append(videoUpload)
        self.saveToFile()
        self.table.reloadData()

    }
    
    func formattedDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func uploadSuccess(_ metadata: FIRStorageMetadata, storagePath: String, videoUpload: VideoUpload) {
        print("Upload Succeeded!")
        videoUpload.completed = true
        self.storeFilenameInDB(metadata: metadata)

        FIRAnalytics.logEvent(withName: "upload_complete", parameters: nil)
        self.progressLabel.text = "Upload done!"
        table.reloadData()
    }
    
    public var files: [VideoUpload] = []
	
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Retry
//        print("Num: \(indexPath.row)")
//        print("Value: \(files[indexPath.row])")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)

        // TODO: maybe improve how this optional works - reduce bugs
        let videoUpload = files[indexPath.row]
        var progressFraction = 0.0
        if let firebaseUploadRef = videoUpload.firebaseUploadRef {
           progressFraction = firebaseUploadRef.snapshot.progress?.fractionCompleted ?? 0.0
        }
        
        let progressFloat = Float(progressFraction)
        progressFraction = (progressFraction * 100).rounded()
        
        // TODO: we are probably creating a whole bunch of progress bars and we only need one
        let progressBar = UIProgressView(frame: cell.frame)
        progressBar.progress = progressFloat
        progressBar.frame.origin.y = 0
        progressBar.frame.origin.x = 0
        
        cell.contentView.addSubview(progressBar)
        cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "uploadicon"))
        
        cell.imageView?.image = videoUpload.thumbnail

        let itemSize = CGSize(width: 55, height: 55)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale);
        let imageRect = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height);
        cell.imageView?.image!.draw(in: imageRect)
        cell.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();

        cell.setNeedsLayout()
        
        let progressString = String(describing: progressFraction)
        
//        NSLog("\(String(describing: snapshot.metadata?.size))")
        cell.textLabel!.text = "\(videoUpload.originalFilename) uploading: \(progressString)%"
        
        // TODO: Move this somewhere else
//        if snapshot.status == .success {
//            videoUpload.completed = true
            //This is done in callback
//        }
        
        if videoUpload.completed == true {
            //            progressBar.isHidden = true
            progressBar.removeFromSuperview()
//            VideoUpload.
            cell.textLabel!.text = "Upload of \(videoUpload.originalFilename) successful."
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "greenTick"))
        }
        
        if videoUpload.failed == true {
            progressBar.removeFromSuperview()
            cell.textLabel!.text = "Upload of \(videoUpload.originalFilename) failed."
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "failed"))
        }
        
        // TODO: Works on all phone sizes
        cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        
        return cell
    }
    
    var filePath: String {
        //1 - manager lets you examine contents of a files and folders in your app; creates a directory to where we are saving it
        let manager = FileManager.default
        //2 - this returns an array of urls from our documentDirectory and we take the first path
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        print("this is the url path in the documentDirectory \(url)")
        //3 - creates a new path component and creates a new file called "Data" which is where we will store our Data array.
        return (url!.appendingPathComponent("Data").path)
    }
    
    func saveToFile(){
        let result = NSKeyedArchiver.archiveRootObject(self.files, toFile: filePath)
        if (result == false) {
            NSLog("error saving file")
        }
    }
    
    func retreiveFromFile(){
        NSLog("retreiving file")
        
        if let decodedFiles = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [VideoUpload] {
            self.files = decodedFiles
        }
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        self.saveToFile()

        /* 
         Cannot save FIRStorageUploadTask as it doest not implement encodeWithCoder. 
         Instead we need to make all the files as failed and maybe add a retry button
         for each item. 
         We may need to store different items to keep the table view state.
        */

        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        self.retreiveFromFile()
        for file in files {
            // Set in progress files to failed.
            if (file.completed == false){
                file.failed = true
                // TODO: We might need to also set the completed ones to true too.
            }
        }

//        self.saveToFile()
        super.decodeRestorableState(with: coder)
    }

    override func applicationFinishedRestoringState() {
        NSLog("Finished restoring state for UploadViewController")
    }
}

extension UploadViewController: UIViewControllerRestoration {
    
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        let vc = UploadViewController()
//        vc.files = self.files
        if let filesData = coder.decodeObject(forKey: "files") as? [VideoUpload] {
            for file in filesData {
                // Set in progress files to failed.
                if (file.completed == false){
                    file.failed = true
                    // TODO: We might need to also set the completed ones to true too.
                }
            }
            vc.files = filesData
        }

        NSLog("\(vc)")
        return vc
    }
}
