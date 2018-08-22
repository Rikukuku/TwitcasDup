//
//  ViewController.swift
//  TwitComeDup
//
//  Created by 中原陸 on 2018/08/20.
//  Copyright © 2018年 中原陸. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage
import DZNEmptyDataSet

class ViewController: UIViewController,UISearchBarDelegate,UITableViewDataSource, UITableViewDelegate {
    
    var datas: [Result] = []
    //Twitcastingのアクセストークン
    let access_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijg3ODk1NzE4ZjlmYzRjZDYxMjQzOTVlOGVhYTdkYWVhYzg4Y2NjMGNmZTlmYTY0YTRmYWZhZjRhYTZhM2Y5MDgyNGZjYjljZTdkNzQ5MTQ3In0.eyJhdWQiOiJmMTgzNjI3NzEyMDAyMjY4OS5kM2I3ZTQwZGE4MzRhZWQ3MjY1NzU5MzJjY2Y1ODMwMTBlOTEyNmQ4N2FiZTBlM2QyZGVhYmY5MGE3MDVhMjdjIiwianRpIjoiODc4OTU3MThmOWZjNGNkNjEyNDM5NWU4ZWFhN2RhZWFjODhjY2MwY2ZlOWZhNjRhNGZhZmFmNGFhNmEzZjkwODI0ZmNiOWNlN2Q3NDkxNDciLCJpYXQiOjE1MzQ4MjEyNDcsIm5iZiI6MTUzNDgyMTI0NywiZXhwIjoxNTUwMzczMjQ3LCJzdWIiOiJmOjE4MzYyNzcxMjAwMjI2ODkiLCJzY29wZXMiOlsicmVhZCIsIndyaXRlIl19.iRgTeIrnRxyjQqPd01PCFZRpyIJHxnJ4-FwqkMBCkCVxZJPpeVg5ARIMCvGhFIefY2orNk-HqpNCiuoaya8YqBP7EmN8D-zWulLjijlrKDS4yOFfLglnyIKosL_ydeiCTD4oUPJmtLKTxgncrD8G6bB_I5UlobXhWt1J7X_oiw4PQX6MmNZxiIFKfsJD47BDQ4yOkRGwxEsj0TQokdYyWxzBJSfPNjBicufdeduudGVAZm4WnojFTp2wlKB366Ylgw40RBZEsXpdy9ZAT-wDtLuvZlr16YvWeifHBIWDRN3kdJdsFwdiQX4JACx9XLWJlKgkca-4HERZHt5wI1vc8Q"
    
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var myTableView: UITableView!
    
    var refreshControl:UIRefreshControl!
    let semaphore = DispatchSemaphore(value:1)
    var flag = 0
    var backTweetView: UIView!
    var textView: UITextView!
    var nowMovieId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.delegate = self
        myTableView.dataSource = self
        searchText.placeholder = "好きな配信者を入力してください"
        searchText.delegate = self
//        myTableView.emptyDataSetSource = self
//        myTableView.emptyDataSetDelegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "再読み込み中")
        refreshControl.addTarget(self, action: #selector(ViewController.refresh), for: UIControlEvents.valueChanged)
        myTableView.addSubview(refreshControl)
        thumbnailImage.image = UIImage(named: "headerIcon3.png")
        myTableView.tableFooterView = UIView(frame: .zero)
        veryfyCredential()

    }
    func updateTable () {
        //時間がかかる処理と想定してグローバルキューで実行
        DispatchQueue.global().async {
            
            self.datas.removeAll()
                self.searchComment(keyword: self.searchText.text!)
            
            DispatchQueue.main.async {
                // UI更新はメインスレッドで実行
                self.myTableView.reloadData()
                self.semaphore.signal()
            }
        }
    }
    @objc func refresh() {
        updateTable()
        // 別スレッドでの処理が終了するのを待つ
        semaphore.wait()
        semaphore.signal()
        //この処理の前にbeginRefreshingが呼ばれているはずなので終了する
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    //部品を作成するメソッド
    func makeBackTweetView() -> UIView {
        backTweetView = UIView()
        backTweetView.frame = CGRect(x:0, y:0, width: self.view.frame.width, height: self.view.frame.height)
        backTweetView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.6)
        return backTweetView
    }
    
    func  makeTweetView() -> UIView {
        let  tweetView = UIView()
        tweetView.frame.size = CGSize(width: 300, height: 300)
        tweetView.center.x = self.view.center.x
        tweetView.center.y = 250
        tweetView.backgroundColor = UIColor.white
        tweetView.layer.shadowOpacity = 0.3
        tweetView.layer.cornerRadius = 3
        return tweetView
    }
    func makeTextView() -> UITextView {
        textView = UITextView()
        textView.frame = CGRect(x:10, y:45, width: 280, height: 140)
        textView.font = UIFont(name: "HiraKakuProN-W6", size: 15)
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).cgColor
        textView.layer.borderWidth = 1
        return textView
    }
    func makeLabel(text: String, y: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x:10, y:y, width:280, height: 40))
        label.text = text
        label.font = UIFont(name: "HiraKakuProN-W6", size:15)
        return label
    }
    func makeCancelBtn(tweetView: UIView) -> UIButton {
        let cancelBtn = UIButton()
        cancelBtn.frame.size = CGSize(width: 20, height:20)
        cancelBtn.center.x = tweetView.frame.width - 15
        cancelBtn.center.y = 15
        cancelBtn.setBackgroundImage(UIImage(named: "cancel.png"), for: .normal)
        cancelBtn.backgroundColor = UIColor(red: 0.14, green: 0.3, blue: 0.68, alpha: 1.0)
        cancelBtn.layer.cornerRadius = cancelBtn.frame.width / 2
        cancelBtn.addTarget(self, action: #selector(self.tappedCancelBtn(_:)), for:.touchUpInside)
        return cancelBtn
    }
    
    func makeSubmitBtn() -> UIButton {
        let submitBtn = UIButton()
        submitBtn.frame = CGRect(x: 10, y: 250, width: 280, height: 40)
        submitBtn.setTitle("Dupする", for: .normal)
        submitBtn.titleLabel?.font = UIFont(name: "HirakakuProN-W6", size:15)
        submitBtn.backgroundColor = UIColor(red: 0.14, green: 0.3, blue: 0.68, alpha: 1.0)
        submitBtn.setTitleColor(UIColor.gray, for: UIControlState.highlighted)
        submitBtn.layer.cornerRadius = 3
        submitBtn.addTarget(self, action: #selector(self.tappedSubmit(_:)), for:.touchUpInside)
        return submitBtn
    }
    func makeTextAddBtn() -> UIButton {
        let submitBtn = UIButton()
        submitBtn.frame = CGRect(x: 10, y: 200, width: 280, height: 24)
        submitBtn.setTitle("お気に入り文字を追加する", for: .normal)
        submitBtn.titleLabel?.font = UIFont(name: "HirakakuProN-W6", size:15)
        submitBtn.backgroundColor = UIColor(red: 0.14, green: 0.3, blue: 0.68, alpha: 1.0)
        submitBtn.setTitleColor(UIColor.gray, for: UIControlState.highlighted)
        submitBtn.layer.cornerRadius = 3
        submitBtn.addTarget(self, action: #selector(self.tappedSubmit2(_:)), for:.touchUpInside)
        return submitBtn
    }
    //------------------ 部品作成するメソッド END ----------------------//
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",for: indexPath) as! TableViewCell
        let data = self.datas[indexPath.row]
        cell.commentLabel.text = data.comment
        //cell.imageView?.image = UIImage(named: "noImage.jpg")
        cell.iconimageView.sd_setImage(with: URL(string: data.iconImage!))
//        cell.iconimageView.layer.cornerRadius = 20
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.datas[indexPath.row]
        print(data.comment!)
        print("-------------------------")
        let  backTweetView = makeBackTweetView()
        self.view.addSubview(backTweetView)
        
        let tweetView = makeTweetView()
        backTweetView.addSubview(tweetView)
        
        let textView = makeTextView()
        textView.text = data.comment!
        tweetView.addSubview(textView)
        let tweetLabel = makeLabel(text: "コメント内容", y: 5)
        tweetView.addSubview(tweetLabel)
        
        let cancelBtn = makeCancelBtn(tweetView: tweetView)
        tweetView.addSubview(cancelBtn)
        let addTextBtn = makeTextAddBtn()
        tweetView.addSubview(addTextBtn)
        
        let submitBtn = makeSubmitBtn()
        tweetView.addSubview(submitBtn)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        if let searchWord = searchText.text {
            print(searchWord)
            searchComment(keyword: searchWord)
        }
    }
    //アクセストークンを検証し、ユーザー情報を取得する
    func veryfyCredential(){
        guard let req_url = URL(string: "https://apiv2.twitcasting.tv/verify_credentials") else {
            return
        }
        print("アクセストークンリクエストは\(req_url)")
        let Auth_header: HTTPHeaders = [
            "Authorization" : "Bearer " + access_token,
            "X-Api-Version" : "2.0",
            "Accept" : "application/json"
        ]
        Alamofire.request(req_url, method: .get, parameters: nil, headers: Auth_header)
            .responseJSON{(response) -> Void in
                if let object = response.result.value {
                    let jsonObject = JSON(object)
                    print(jsonObject)
                }
        }
    }
    //現在配信されているキャス主を取得
    func searchComment(keyword : String){
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else  {
            return
        }
        guard let req_url = URL(string: "https://apiv2.twitcasting.tv/users/\(keyword_encode)/current_live") else {
            return
        }
        print(req_url)
        
        let Auth_header: HTTPHeaders = [
            "Authorization" : "Bearer " + access_token,
            "X-Api-Version" : "2.0",
            "Accept" : "application/json"
        ]
        Alamofire.request(req_url, method: .get, parameters: nil, headers: Auth_header)
            .responseJSON{(response) -> Void in
                if let object = response.result.value {
                    let jsonObject = JSON(object)
                    print(jsonObject)
                    let movie_id = jsonObject["movie"]["id"].string!
                    //let user_id = jsonObject["movie"]["user_id"].string!
                    let image_data = jsonObject["movie"]["large_thumbnail"].string!
                    self.nowMovieId = movie_id
                    self.thumbnailImage.sd_setImage(with: URL(string: image_data))
                    self.getRealtimeComment(movie_id: movie_id)
                    
//                    self.getThumbnail(user_id: user_id)
                }
        }
        
    }
    //動画に対するコメントを取得
    func getRealtimeComment(movie_id: String){
        guard let req_url = URL(string: "https://apiv2.twitcasting.tv/movies/\(movie_id)/comments") else{
            return
        }
        print(req_url)
        let Auth_header: HTTPHeaders = [
            "Authorization" : "Bearer " + access_token,
            "X-Api-Version" : "2.0",
            "Accept" : "application/json"
        ]
        Alamofire.request(req_url, method: .get, parameters: nil, headers: Auth_header)
            .responseJSON{(response) -> Void in
                if let object = response.result.value {
                    let jsonObject = JSON(object)
                    print(jsonObject)
                    let rests = jsonObject["comments"].array
                    for rest in rests! {
                        let result = Result()
                        result.comment = rest["message"].string!
                        result.iconImage = rest["from_user"]["image"].string!
                        self.datas.append(result)
                    }
                    
                    self.myTableView.reloadData()
                        
                    
                }
    }

  }
    //コメントを投稿する
    func postComment(movie_id: String, messageText: String){
        guard let req_url = URL(string: "https://apiv2.twitcasting.tv/movies/\(movie_id)/comments") else{
            return
        }
        print(movie_id)
        print(req_url)
        print(messageText)
        let Auth_header: HTTPHeaders = [
            "Authorization" : "Bearer " + access_token,
            "X-Api-Version" : "2.0",
            "Accept" : "application/json"
        ]
        let params = [
            "comment": "\(messageText)",
        ]
        Alamofire.request(req_url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: Auth_header)
            .responseJSON{(response) -> Void in
                if let object = response.result.value {
                    let jsonObject = JSON(object)
                    print(jsonObject)
                }
            }
        }
    
    @objc func tappedCancelBtn(_: AnyObject){
        backTweetView.removeFromSuperview()
    }
    @objc func tappedSubmit(_ sender : AnyObject){
        if textView.text.isEmpty {
            let alertController = UIAlertController(title:"Error", message: "name or text is empty", preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
        }
        postComment(movie_id: nowMovieId, messageText: textView.text!)
        print("コメントを投稿しました")
        backTweetView.removeFromSuperview()
    }
     @objc func tappedSubmit2(_ sender : AnyObject){
        print("aaaaa")
        let nowText = textView.text!
        textView.text = "\(nowText)(￣▽￣) ﾆﾔ"
        
    }
    
}

//extension ViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
//    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
//        print("画像を表示しています。")
//        return UIImage(named: "top2.png")
//    }
//}

