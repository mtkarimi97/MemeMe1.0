//
//  ViewController.swift
//  MemeMe 1.0
//
//  Created by Administrator on 6/22/20.
//  Copyright © 2020 Walek. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // The view that displays the image being memed
    @IBOutlet weak var imageView: UIImageView!
    // The button to start the camera to take a new picture for the meme
    @IBOutlet weak var cameraButton: UIButton!
    // Button to share meme
    @IBOutlet weak var shareButton: UIBarButtonItem!
    // Button that resets the UI of app to launch state
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    // Top text field of meme
    @IBOutlet weak var topTextField: UITextField!
    // Bottom text field of meme
    @IBOutlet weak var bottomTextField: UITextField!
    // Top toolbar outlet
    @IBOutlet weak var topToolbar: UIToolbar!
    // Bottom toolbar (actually a stack view) outlet
    @IBOutlet weak var bottomStackView: UIStackView!
    
    
    // String constant for top text field
    let topDefaultText = "TOP"
    // String constant for bottom text field
    let bottomDefaultText = "BOTTOM"
    
    
    // The current text field being edited (out of the top and bottom)
    var activeTextField: UITextField? = nil
    // The final image with the text on the top and bottom of it
    var memedImage: UIImage = UIImage()
    
    // The attributes of the text in the text fields
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: 3.0
    ]
    
    // Memo object representing each Memo
    struct Meme {
        var topText: String?
        var bottomText: String?
        var originalImage: UIImage?
        var memedImage: UIImage?
        
    }
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTextField(topTextField, topDefaultText)
        setupTextField(bottomTextField, bottomDefaultText)
        
        shareButton.isEnabled = false
    }
    
    // Code sourced from my initial project submission reviewer, who suggested refactoring viewDidLoad() to use this method instead
    func setupTextField(_ textField: UITextField, _ defaultText: String) {
        textField.delegate = self
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.text = defaultText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: - Image Picking and Share Methods
    
    // Code refactored per source code of reviewer of projects first submission
    func pickFromSource(_ source: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = source
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImage(_ sender: Any) {
        pickFromSource(.photoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        pickFromSource(.camera)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            shareButton.isEnabled = true
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButton(_ sender: Any) {
        self.memedImage = generateMemedImage()
        let activityvc = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        activityvc.completionWithItemsHandler = { [weak self] type, completed, items, error in
            if completed {
                self?.save()
            }
            
            activityvc.dismiss(animated: true, completion: nil)
        }
        present(activityvc, animated: true, completion: save)
    }
    
    // MARK: - Text Field Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text! == topDefaultText || textField.text! == bottomDefaultText {
            textField.text! = ""
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.activeTextField = textField
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    // MARK: - Keyboard Methods
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let keyboardSize = getKeyboardHeight(notification)
        if let activeTextField = activeTextField {
            let bottomOfTextField = activeTextField.convert(activeTextField.bounds, to: self.view).maxY
            let topOfKeyboard = self.view.frame.height - keyboardSize
            
            if bottomOfTextField > topOfKeyboard {
                view.frame.origin.y = -keyboardSize
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
    
    @objc func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    // MARK: - Meme Object Methods
    
    // Inits a meme object
    func save() {
        let _ = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: memedImage)
    }
    
    // Combines meme text and image into a single image
    func generateMemedImage() -> UIImage {
        
        self.topToolbar.isHidden = true
        self.bottomStackView.isHidden = true
        
        //Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        self.topToolbar.isHidden = false
        self.bottomStackView.isHidden = false
        
        return memedImage
    }
    
    // MARK: - Cancel Button Method
    @IBAction func cancelButton(_ sender: Any) {
        self.imageView.image = nil
        self.topTextField.text = topDefaultText
        self.bottomTextField.text = bottomDefaultText
    }
}

