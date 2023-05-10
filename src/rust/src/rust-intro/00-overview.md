Overview
========

這是我第一次參加鐵人賽，那因為平常比較沒有分享文章的習慣  
就想趁這個機會讓自己多寫一點文章，同時介紹一下這個之前意外讓我入坑  
很有趣的一個程式語言 Rust  

這系列會假設你有基礎的程式能力，不管是什麼語言都行
至少知道一下比如「參考 (reference) 」是什麼，雖說我也會盡量以初學程式的角度講解  
只是 Rust 這個語言本身就包含了不少比較進階的觀念，加上我很可能會舉其它程式語言當對照  
同時本系列會以類 Unix (Linux, Mac) 的環境為主，如果你使用的是 Windows 大部份情況下應該不會有什麼問題  
本系列的程式都會在 Ubuntu 18.04 下測試過，如果有任何問題歡迎回報
如果你有任何問題歡迎留言問我，我很樂意解答的，或是你有任何建議也行，我會很高興的

Rust 是由 Mozilla 所主導的系統程式語言  
旨在快速，同時保證記憶體與多執行緒的安全  
這代表者使用 Rust 開發基本上不會再看到諸如 Segmentation Fault 等等的記憶體錯誤了  
強大的 trait 系統，可以方便的擴充標準函式庫，這讓 Rust 雖然是靜態的程式語言，卻也有極大的靈活性  
同時目前也有不少的應用，比如網頁後端、系統程式還有 WebAssembly  
另外也因為其速度快與語法簡潔跟豐富的生態，也有不少公司用來處理極需要速度的部份  
比如 Dropbox, npm 想知道還有誰用可以去看看 https://www.rust-lang.org/en-US/friends.html  

預計會花 20 篇左右把 Rust 語言介紹完，剩下的則是來實作一些實際的專案  
以及介紹一些 Rust 的套件與生態系  
預計會做的有：

- 連結 c 函式庫以及與 c 連結
- 寫一個 python 的 native extension
- 寫個指令列的程式
- 寫個網頁後端

或是有任何建議，或者你覺得改做什麼樣的專案會更有趣的也歡迎提出

```rust
fn main() {
    println!("Let's start");
}
```