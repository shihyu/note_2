# 3.5 HTTPS 如何優化？


由裸數據傳輸的 HTTP 協議轉成加密數據傳輸的 HTTPS 協議，給應用數據套了個「保護傘」，提高安全性的同時也帶來了性能消耗。

因為 HTTPS 相比 HTTP 協議多一個 TLS 協議握手過程，**目的是為了通過非對稱加密握手協商或者交換出對稱加密密鑰**，這個過程最長可以花費掉 2 RTT，接著後續傳輸的應用數據都得使用對稱加密密鑰來加密/解密。

為了數據的安全性，我們不得不使用 HTTPS 協議，至今大部分網址都已從 HTTP 遷移至 HTTPS 協議，因此針對 HTTPS 的優化是非常重要的。

這次，就從多個角度來優化 HTTPS。


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/優化https提綱.png)

---

## 分析性能損耗

既然要對 HTTPS 優化，那得清楚哪些步驟會產生性能消耗，再對症下藥。

產生性能消耗的兩個環節：

- 第一個環節， TLS 協議握手過程；
- 第二個環節，握手後的對稱加密報文傳輸。

對於第二環節，現在主流的對稱加密算法 AES、ChaCha20 性能都是不錯的，而且一些 CPU 廠商還針對它們做了硬件級別的優化，因此這個環節的性能消耗可以說非常地小。

而第一個環節，TLS 協議握手過程不僅增加了網絡延時（最長可以花費掉 2 RTT），而且握手過程中的一些步驟也會產生性能損耗，比如：

- 對於 ECDHE 密鑰協商算法，握手過程中會客戶端和服務端都需要臨時生成橢圓曲線公私鑰；
- 客戶端驗證證書時，會訪問 CA 獲取 CRL 或者 OCSP，目的是驗證服務器的證書是否有被吊銷；
- 雙方計算 Pre-Master，也就是對稱加密密鑰；

為了大家更清楚這些步驟在 TLS 協議握手的哪一個階段，我畫出了這幅圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/tls性能損耗.png)


---

## 硬件優化

玩遊戲時，如果我們怎麼都戰勝不了對方，那麼有一個最有效、最快的方式來變強，那就是「充錢」，如果還是不行，那說明你充的錢還不夠多。


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/充錢.jpg)



對於計算機裡也是一樣，軟件都是跑在物理硬件上，硬件越牛逼，軟件跑的也越快，所以如果要優化 HTTPS 優化，最直接的方式就是花錢買性能參數更牛逼的硬件。

但是花錢也要花對方向，**HTTPS 協議是計算密集型，而不是 I/O 密集型**，所以不能把錢花在網卡、硬盤等地方，應該花在 CPU 上。

一個好的 CPU，可以提高計算性能，因為 HTTPS 連接過程中就有大量需要計算密鑰的過程，所以這樣可以加速 TLS 握手過程。


另外，如果可以，應該選擇可以**支持 AES-NI 特性的 CPU**，因為這種款式的 CPU 能在指令級別優化了 AES 算法，這樣便加速了數據的加解密傳輸過程。

如果你的服務器是 Linux 系統，那麼你可以使用下面這行命令查看 CPU 是否支持 AES-NI 指令集：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/aesni_intel.png)



如果我們的 CPU 支持 AES-NI 特性，那麼對於對稱加密的算法應該選擇 AES 算法。否則可以選擇 ChaCha20 對稱加密算法，因為 ChaCha20 算法的運算指令相比 AES 算法會對 CPU 更友好一點。

---

## 軟件優化

如果公司預算充足對於新的服務器是可以考慮購買更好的 CPU，但是對於已經在使用的服務器，硬件優化的方式可能就不太適合了，於是就要從軟件的方向來優化了。

軟件的優化方向可以分層兩種，一個是**軟件升級**，一個是**協議優化**。

先說第一個軟件升級，軟件升級就是將正在使用的軟件升級到最新版本，因為最新版本不僅提供了最新的特性，也優化了以前軟件的問題或性能。比如：

- 將 Linux 內核從 2.x 升級到 4.x；
- 將 OpenSSL 從 1.0.1 升級到 1.1.1；
- ...

看似簡單的軟件升級，對於有成百上千服務器的公司來說，軟件升級也跟硬件升級同樣是一個棘手的問題，因為要實行軟件升級，會花費時間和人力，同時也存在一定的風險，也可能會影響正常的線上服務。

既然如此，我們把目光放到協議優化，也就是在現有的環節下，通過較小的改動，來進行優化。


---

## 協議優化

協議的優化就是對「密鑰交換過程」進行優化。

### 密鑰交換算法優化

TLS 1.2 版本如果使用的是 RSA 密鑰交換算法，那麼需要 4 次握手，也就是要花費 2 RTT，才可以進行應用數據的傳輸，而且 RSA 密鑰交換算法不具備前向安全性。

總之使用 **RSA 密鑰交換算法的 TLS 握手過程，不僅慢，而且安全性也不高**。

因此如果可以，儘量**選用 ECDHE 密鑰交換**算法替換 RSA 算法，因為該算法由於支持「False Start」，它是“搶跑”的意思，客戶端可以在 TLS 協議的第 3 次握手後，第 4 次握手前，發送加密的應用數據，以此將 **TLS 握手的消息往返由 2 RTT 減少到 1 RTT，而且安全性也高，具備前向安全性**。

ECDHE 算法是基於橢圓曲線實現的，不同的橢圓曲線性能也不同，應該儘量**選擇 x25519 曲線**，該曲線是目前最快的橢圓曲線。

比如在 Nginx 上，可以使用 ssl_ecdh_curve 指令配置想使用的橢圓曲線，把優先使用的放在前面：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/ssl_ecdh_curve.png)


對於對稱加密算法方面，如果對安全性不是特別高的要求，可以**選用 AES_128_GCM**，它比 AES_256_GCM 快一些，因為密鑰的長度短一些。

比如在 Nginx 上，可以使用 ssl_ciphers 指令配置想使用的非對稱加密算法和對稱加密算法，也就是密鑰套件，而且把性能最快最安全的算法放在最前面：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/ssl_ciphers.png)



### TLS 升級

當然，如果可以，直接把 TLS 1.2 升級成 TLS 1.3，TLS 1.3 大幅度簡化了握手的步驟，**完成 TLS 握手只要 1 RTT**，而且安全性更高。

在 TLS 1.2 的握手中，一般是需要 4 次握手，先要通過 Client Hello （第 1 次握手）和 Server Hello（第 2 次握手） 消息協商出後續使用的加密算法，再互相交換公鑰（第 3 和 第 4 次握手），然後計算出最終的會話密鑰，下圖的左邊部分就是 TLS 1.2 的握手過程：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/tls1.2and1.3.png)


上圖的右邊部分就是 TLS 1.3 的握手過程，可以發現 **TLS 1.3 把 Hello 和公鑰交換這兩個消息合併成了一個消息，於是這樣就減少到只需 1 RTT 就能完成 TLS 握手**。

怎麼合併的呢？具體的做法是，客戶端在  Client Hello 消息裡帶上了支持的橢圓曲線，以及這些橢圓曲線對應的公鑰。

服務端收到後，選定一個橢圓曲線等參數，然後返回消息時，帶上服務端這邊的公鑰。經過這 1 個 RTT，雙方手上已經有生成會話密鑰的材料了，於是客戶端計算出會話密鑰，就可以進行應用數據的加密傳輸了。


而且，TLS1.3 對密碼套件進行“減肥”了，
**對於密鑰交換算法，廢除了不支持前向安全性的  RSA 和 DH 算法，只支持 ECDHE 算法**。

對於對稱加密和簽名算法，只支持目前最安全的幾個密碼套件，比如 openssl 中僅支持下面 5 種密碼套件：

- TLS_AES_256_GCM_SHA384
- TLS_CHACHA20_POLY1305_SHA256
- TLS_AES_128_GCM_SHA256
- TLS_AES_128_CCM_8_SHA256
- TLS_AES_128_CCM_SHA256

之所以 TLS1.3   僅支持這麼少的密碼套件，是因為 TLS1.2 由於支持各種古老且不安全的密碼套件，中間人可以利用降級攻擊，偽造客戶端的 Client Hello 消息，替換客戶端支持的密碼套件為一些不安全的密碼套件，使得服務器被迫使用這個密碼套件進行 HTTPS 連接，從而破解密文。

---

## 證書優化

為了驗證的服務器的身份，服務器會在 TLS 握手過程中，把自己的證書發給客戶端，以此證明自己身份是可信的。

對於證書的優化，可以有兩個方向：

- 一個是**證書傳輸**，
- 一個是**證書驗證**；

### 證書傳輸優化

要讓證書更便於傳輸，那必然是減少證書的大小，這樣可以節約帶寬，也能減少客戶端的運算量。所以，**對於服務器的證書應該選擇橢圓曲線（ECDSA）證書，而不是 RSA 證書，因為在相同安全強度下， ECC 密鑰長度比 RSA 短的多**。 

### 證書驗證優化

客戶端在驗證證書時，是個複雜的過程，會走證書鏈逐級驗證，驗證的過程不僅需要「用 CA 公鑰解密證書」以及「用簽名算法驗證證書的完整性」，而且為了知道證書是否被 CA 吊銷，客戶端有時還會再去訪問 CA， 下載 CRL 或者 OCSP 數據，以此確認證書的有效性。

這個訪問過程是 HTTP 訪問，因此又會產生一系列網絡通信的開銷，如 DNS 查詢、建立連接、收發數據等。

#### CRL 

CRL 稱為證書吊銷列表（*Certificate Revocation List*），這個列表是由 CA 定期更新，列表內容都是被撤銷信任的證書序號，如果服務器的證書在此列表，就認為證書已經失效，不在的話，則認為證書是有效的。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/crl.png)

但是 CRL 存在兩個問題：

- 第一個問題，由於 CRL 列表是由 CA 維護的，定期更新，如果一個證書剛被吊銷後，客戶端在更新 CRL 之前還是會信任這個證書，**實時性較差**；
- 第二個問題，**隨著吊銷證書的增多，列表會越來越大，下載的速度就會越慢**，下載完客戶端還得遍歷這麼大的列表，那麼就會導致客戶端在校驗證書這一環節的延時很大，進而拖慢了 HTTPS 連接。

#### OCSP 

因此，現在基本都是使用 OCSP ，名為在線證書狀態協議（*Online Certificate Status Protocol*）來查詢證書的有效性，它的工作方式是**向 CA 發送查詢請求，讓 CA 返回證書的有效狀態**。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/ocsp.png)


不必像 CRL 方式客戶端需要下載大大的列表，還要從列表查詢，同時因為可以實時查詢每一張證書的有效性，解決了 CRL 的實時性問題。


OCSP 需要向  CA 查詢，因此也是要發生網絡請求，而且還得看  CA 服務器的“臉色”，如果網絡狀態不好，或者 CA 服務器繁忙，也會導致客戶端在校驗證書這一環節的延時變大。

#### OCSP Stapling

於是為瞭解決這一個網絡開銷，就出現了 OCSP Stapling，其原理是：服務器向 CA 週期性地查詢證書狀態，獲得一個帶有時間戳和簽名的響應結果並緩存它。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/opscp-stapling.png)


當有客戶端發起連接請求時，服務器會把這個「響應結果」在 TLS 握手過程中發給客戶端。由於有簽名的存在，服務器無法篡改，因此客戶端就能得知證書是否已被吊銷了，這樣客戶端就不需要再去查詢。



---

## 會話複用

TLS 握手的目的就是為了協商出會話密鑰，也就是對稱加密密鑰，那我們如果我們把首次 TLS 握手協商的對稱加密密鑰緩存起來，待下次需要建立 HTTPS 連接時，直接「複用」這個密鑰，不就減少 TLS 握手的性能損耗了嗎？

這種方式就是**會話複用**（*TLS session resumption*），會話複用分兩種：

- 第一種叫 Session ID；
- 第二種叫 Session Ticket；

### Session ID

Session ID 的工作原理是，**客戶端和服務器首次  TLS 握手連接後，雙方會在內存緩存會話密鑰，並用唯一的 Session ID 來標識**，Session ID 和會話密鑰相當於 key-value 的關係。


當客戶端再次連接時，hello 消息裡會帶上 Session ID，服務器收到後就會從內存找，如果找到就直接用該會話密鑰恢復會話狀態，跳過其餘的過程，只用一個消息往返就可以建立安全通信。當然為了安全性，內存中的會話密鑰會定期失效。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/sessionid.png)


但是它有兩個缺點：

- 服務器必須保持每一個客戶端的會話密鑰，隨著客戶端的增多，**服務器的內存壓力也會越大**。
- 現在網站服務一般是由多臺服務器通過負載均衡提供服務的，**客戶端再次連接不一定會命中上次訪問過的服務器**，於是還要走完整的 TLS 握手過程；


### Session Ticket

為瞭解決 Session ID 的問題，就出現了 Session Ticket，**服務器不再緩存每個客戶端的會話密鑰，而是把緩存的工作交給了客戶端**，類似於 HTTP 的 Cookie。

客戶端與服務器首次建立連接時，服務器會加密「會話密鑰」作為 Ticket 發給客戶端，交給客戶端緩存該 Ticket。

客戶端再次連接服務器時，客戶端會發送 Ticket，服務器解密後就可以獲取上一次的會話密鑰，然後驗證有效期，如果沒問題，就可以恢復會話了，開始加密通信。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/ticket.png)

對於集群服務器的話，**要確保每臺服務器加密 「會話密鑰」的密鑰是一致的**，這樣客戶端攜帶 Ticket 訪問任意一臺服務器時，都能恢復會話。

Session ID 和 Session Ticket **都不具備前向安全性**，因為一旦加密「會話密鑰」的密鑰被破解或者服務器洩漏「會話密鑰」，前面劫持的通信密文都會被破解。

同時應對**重放攻擊**也很困難，這裡簡單介紹下重放攻擊工作的原理。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/重放攻擊.png)


假設 Alice 想向 Bob 證明自己的身份。 Bob 要求 Alice 的密碼作為身份證明，愛麗絲應盡全力提供（可能是在經過如哈希函數的轉換之後）。與此同時，Eve 竊聽了對話並保留了密碼（或哈希）。

交換結束後，Eve（冒充 Alice ）連接到 Bob。當被要求提供身份證明時，Eve 發送從 Bob 接受的最後一個會話中讀取的 Alice 的密碼（或哈希），從而授予 Eve 訪問權限。

重放攻擊的危險之處在於，如果中間人截獲了某個客戶端的 Session ID 或 Session Ticket 以及 POST 報文，而一般 POST 請求會改變數據庫的數據，中間人就可以利用此截獲的報文，不斷向服務器發送該報文，這樣就會導致數據庫的數據被中間人改變了，而客戶是不知情的。

避免重放攻擊的方式就是需要**對會話密鑰設定一個合理的過期時間**。


### Pre-shared Key

前面的 Session ID 和 Session Ticket 方式都需要在 1 RTT 才能恢復會話。

而 TLS1.3  更為牛逼，對於重連 TLS1.3 只需要 **0 RTT**，原理和 Ticket 類似，只不過在重連時，客戶端會把 Ticket 和 HTTP 請求一同發送給服務端，這種方式叫 **Pre-shared Key**。


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/0-RTT.png)

同樣的，Pre-shared Key 也有重放攻擊的危險。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https優化/0-rtt-attack.png)

如上圖，假設中間人通過某種方式，截獲了客戶端使用會話重用技術的 POST 請求，通常 POST 請求是會改變數據庫的數據，然後中間人就可以把截獲的這個報文發送給服務器，服務器收到後，也認為是合法的，於是就恢復會話，致使數據庫的數據又被更改，但是此時用戶是不知情的。

所以，應對重放攻擊可以給會話密鑰設定一個合理的過期時間，以及只針對安全的 HTTP 請求如 GET/HEAD 使用會話重用。

---


## 總結

對於硬件優化的方向，因為 HTTPS 是屬於計算密集型，應該選擇計算力更強的 CPU，而且最好選擇**支持 AES-NI 特性的 CPU**，這個特性可以在硬件級別優化 AES 對稱加密算法，加快應用數據的加解密。

對於軟件優化的方向，如果可以，把軟件升級成較新的版本，比如將 Linux 內核 2.X 升級成 4.X，將 openssl 1.0.1 升級到 1.1.1，因為新版本的軟件不僅會提供新的特性，而且還會修復老版本的問題。

對於協議優化的方向：

- 密鑰交換算法應該選擇 **ECDHE 算法**，而不用 RSA 算法，因為 ECDHE 算法具備前向安全性，而且客戶端可以在第三次握手之後，就發送加密應用數據，節省了 1 RTT。
- 將 TLS1.2 升級 **TLS1.3**，因為 TLS1.3 的握手過程只需要 1 RTT，而且安全性更強。

對於證書優化的方向：

- 服務器應該選用 **ECDSA 證書**，而非 RSA 證書，因為在相同安全級別下，ECC 的密鑰長度比 RSA 短很多，這樣可以提高證書傳輸的效率；
- 服務器應該開啟 **OCSP Stapling** 功能，由服務器預先獲得 OCSP 的響應，並把響應結果緩存起來，這樣 TLS 握手的時候就不用再訪問 CA 服務器，減少了網絡通信的開銷，提高了證書驗證的效率；

對於重連 HTTPS 時，我們可以使用一些技術讓客戶端和服務端使用上一次 HTTPS 連接使用的會話密鑰，直接恢復會話，而不用再重新走完整的 TLS 握手過程。

常見的**會話重用**技術有 Session ID 和 Session Ticket，用了會話重用技術，當再次重連 HTTPS 時，只需要 1 RTT 就可以恢復會話。對於 TLS1.3 使用 Pre-shared Key 會話重用技術，只需要 0 RTT 就可以恢復會話。

這些會話重用技術雖然好用，但是存在一定的安全風險，它們不僅不具備前向安全，而且有重放攻擊的風險，所以應當對會話密鑰設定一個合理的過期時間。

---

參考資料：

1. http://www.doc88.com/p-8621583210895.html
2. https://zhuanlan.zhihu.com/p/33685085
3. https://en.wikipedia.org/wiki/Replay_attack
4. https://en.wikipedia.org/wiki/Downgrade_attack
5. https://www.cnblogs.com/racent-Z/p/14011056.html
6. http://www.guoyanbin.com/a-detailed-look-at-rfc-8446-a-k-a-tls-1-3/
7. https://www.thesslstore.com/blog/crl-explained-what-is-a-certificate-revocation-list/

---

哈嘍，我是小林，就愛圖解計算機基礎，如果文章對你有幫助，別忘記關注哦！

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)
