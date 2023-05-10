# 2.3 Linux 系統是如何收發網絡包的？

這次，就圍繞一個問題來說。

**Linux 系統是如何收發網絡包的？**

## 網絡模型

為了使得多種設備能通過網絡相互通信，和為瞭解決各種不同設備在網絡互聯中的兼容性問題，國際標準化組織制定了開放式系統互聯通信參考模型（*Open System Interconnection Reference Model*），也就是 OSI 網絡模型，該模型主要有 7 層，分別是應用層、表示層、會話層、傳輸層、網絡層、數據鏈路層以及物理層。

每一層負責的職能都不同，如下：

- 應用層，負責給應用程序提供統一的接口；
- 表示層，負責把數據轉換成兼容另一個系統能識別的格式；
- 會話層，負責建立、管理和終止表示層實體之間的通信會話；
- 傳輸層，負責端到端的數據傳輸；
- 網絡層，負責數據的路由、轉發、分片；
- 數據鏈路層，負責數據的封幀和差錯檢測，以及 MAC 尋址；
- 物理層，負責在物理網絡中傳輸數據幀；

由於 OSI 模型實在太複雜，提出的也只是概念理論上的分層，並沒有提供具體的實現方案。

事實上，我們比較常見，也比較實用的是四層模型，即 TCP/IP 網絡模型，Linux 系統正是按照這套網絡模型來實現網絡協議棧的。

TCP/IP 網絡模型共有 4 層，分別是應用層、傳輸層、網絡層和網絡接口層，每一層負責的職能如下：

- 應用層，負責向用戶提供一組應用程序，比如 HTTP、DNS、FTP 等;
- 傳輸層，負責端到端的通信，比如 TCP、UDP 等；
- 網絡層，負責網絡包的封裝、分片、路由、轉發，比如 IP、ICMP 等；
- 網絡接口層，負責網絡包在物理網絡中的傳輸，比如網絡包的封幀、 MAC 尋址、差錯檢測，以及通過網卡傳輸網絡幀等；

TCP/IP 網絡模型相比 OSI 網絡模型簡化了不少，也更加易記，它們之間的關係如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/OSI與TCP.png)

不過，我們常說的七層和四層負載均衡，是用 OSI 網絡模型來描述的，七層對應的是應用層，四層對應的是傳輸層。

---

## Linux 網絡協議棧


我們可以把自己的身體比作應用層中的數據，打底衣服比作傳輸層中的 TCP 頭，外套比作網絡層中 IP 頭，帽子和鞋子分別比作網絡接口層的幀頭和幀尾。

在冬天這個季節，當我們要從家裡出去玩的時候，自然要先穿個打底衣服，再套上保暖外套，最後穿上帽子和鞋子才出門，這個過程就好像我們把 TCP 協議通信的網絡包發出去的時候，會把應用層的數據按照網絡協議棧層層封裝和處理。

你從下面這張圖可以看到，應用層數據在每一層的封裝格式。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/封裝.png)

其中：

- 傳輸層，給應用數據前面增加了 TCP  頭；
- 網絡層，給 TCP 數據包前面增加了 IP  頭；
- 網絡接口層，給 IP 數據包前後分別增加了幀頭和幀尾；

這些新增的頭部和尾部，都有各自的作用，也都是按照特定的協議格式填充，這每一層都增加了各自的協議頭，那自然網絡包的大小就增大了，但物理鏈路並不能傳輸任意大小的數據包，所以在以太網中，規定了最大傳輸單元（MTU）是 `1500` 字節，也就是規定了單次傳輸的最大 IP 包大小。

當網絡包超過 MTU 的大小，就會在網絡層分片，以確保分片後的 IP 包不會超過 MTU 大小，如果 MTU 越小，需要的分包就越多，那麼網絡吞吐能力就越差，相反的，如果 MTU 越大，需要的分包就越少，那麼網絡吞吐能力就越好。

知道了 TCP/IP 網絡模型，以及網絡包的封裝原理後，那麼 Linux 網絡協議棧的樣子，你想必猜到了大概，它其實就類似於 TCP/IP 的四層結構：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/協議棧.png)


從上圖的的網絡協議棧，你可以看到：

- 應用程序需要通過系統調用，來跟 Socket 層進行數據交互；
- Socket 層的下面就是傳輸層、網絡層和網絡接口層；
- 最下面的一層，則是網卡驅動程序和硬件網卡設備；


## Linux 接收網絡包的流程


網卡是計算機裡的一個硬件，專門負責接收和發送網絡包，當網卡接收到一個網絡包後，會通過 DMA 技術，將網絡包寫入到指定的內存地址，也就是寫入到 Ring Buffer ，這個是一個環形緩衝區，接著就會告訴操作系統這個網絡包已經到達。

>  那應該怎麼告訴操作系統這個網絡包已經到達了呢？

最簡單的一種方式就是觸發中斷，也就是每當網卡收到一個網絡包，就觸發一箇中斷告訴操作系統。

但是，這存在一個問題，在高性能網絡場景下，網絡包的數量會非常多，那麼就會觸發非常多的中斷，要知道當 CPU  收到了中斷，就會停下手裡的事情，而去處理這些網絡包，處理完畢後，才會回去繼續其他事情，那麼頻繁地觸發中斷，則會導致 CPU 一直沒完沒了的處理中斷，而導致其他任務可能無法繼續前進，從而影響系統的整體效率。

所以為瞭解決頻繁中斷帶來的性能開銷，Linux 內核在 2.6 版本中引入了 **NAPI 機制**，它是混合「中斷和輪詢」的方式來接收網絡包，它的核心概念就是**不採用中斷的方式讀取數據**，而是首先採用中斷喚醒數據接收的服務程序，然後 `poll` 的方法來輪詢數據。

因此，當有網絡包到達時，會通過 DMA 技術，將網絡包寫入到指定的內存地址，接著網卡向 CPU 發起硬件中斷，當 CPU 收到硬件中斷請求後，根據中斷表，調用已經註冊的中斷處理函數。

硬件中斷處理函數會做如下的事情：

- 需要先「暫時屏蔽中斷」，表示已經知道內存中有數據了，告訴網卡下次再收到數據包直接寫內存就可以了，不要再通知 CPU 了，這樣可以提高效率，避免 CPU 不停的被中斷。
- 接著，發起「軟中斷」，然後恢復剛才屏蔽的中斷。

至此，硬件中斷處理函數的工作就已經完成。

硬件中斷處理函數做的事情很少，主要耗時的工作都交給軟中斷處理函數了。

> 軟中斷的處理

內核中的 ksoftirqd 線程專門負責軟中斷的處理，當 ksoftirqd 內核線程收到軟中斷後，就會來輪詢處理數據。

ksoftirqd 線程會從 Ring Buffer 中獲取一個數據幀，用 sk_buff 表示，從而可以作為一個網絡包交給網絡協議棧進行逐層處理。

> 網絡協議棧

首先，會先進入到網絡接口層，在這一層會檢查報文的合法性，如果不合法則丟棄，合法則會找出該網絡包的上層協議的類型，比如是 IPv4，還是 IPv6，接著再去掉幀頭和幀尾，然後交給網絡層。

到了網絡層，則取出 IP 包，判斷網絡包下一步的走向，比如是交給上層處理還是轉發出去。當確認這個網絡包要發送給本機後，就會從 IP 頭裡看看上一層協議的類型是 TCP 還是 UDP，接著去掉 IP 頭，然後交給傳輸層。

傳輸層取出 TCP 頭或 UDP 頭，根據四元組「源 IP、源端口、目的 IP、目的端口」 作為標識，找出對應的 Socket，並把數據放到 Socket 的接收緩衝區。

最後，應用層程序調用 Socket 接口，將內核的 Socket 接收緩衝區的數據「拷貝」到應用層的緩衝區，然後喚醒用戶進程。

至此，一個網絡包的接收過程就已經結束了，你也可以從下圖左邊部分看到網絡包接收的流程，右邊部分剛好反過來，它是網絡包發送的流程。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/收發流程.png)

## Linux 發送網絡包的流程

如上圖的右半部分，發送網絡包的流程正好和接收流程相反。


首先，應用程序會調用 Socket 發送數據包的接口，由於這個是系統調用，所以會從用戶態陷入到內核態中的 Socket 層，內核會申請一個內核態的 sk_buff 內存，**將用戶待發送的數據拷貝到 sk_buff 內存，並將其加入到發送緩衝區**。

接下來，網絡協議棧從 Socket 發送緩衝區中取出 sk_buff，並按照 TCP/IP 協議棧從上到下逐層處理。

如果使用的是 TCP 傳輸協議發送數據，那麼**先拷貝一個新的 sk_buff 副本** ，這是因為 sk_buff 後續在調用網絡層，最後到達網卡發送完成的時候，這個 sk_buff 會被釋放掉。而 TCP 協議是支持丟失重傳的，在收到對方的 ACK 之前，這個 sk_buff 不能被刪除。所以內核的做法就是每次調用網卡發送的時候，實際上傳遞出去的是 sk_buff 的一個拷貝，等收到 ACK 再真正刪除。

接著，對 sk_buff 填充 TCP 頭。這裡提一下，sk_buff 可以表示各個層的數據包，在應用層數據包叫 data，在 TCP 層我們稱為 segment，在 IP 層我們叫 packet，在數據鏈路層稱為 frame。

你可能會好奇，為什麼全部數據包只用一個結構體來描述呢？協議棧採用的是分層結構，上層向下層傳遞數據時需要增加包頭，下層向上層數據時又需要去掉包頭，如果每一層都用一個結構體，那在層之間傳遞數據的時候，就要發生多次拷貝，這將大大降低 CPU 效率。

於是，為了在層級之間傳遞數據時，不發生拷貝，只用 sk_buff 一個結構體來描述所有的網絡包，那它是如何做到的呢？是通過調整 sk_buff 中 `data` 的指針，比如：

- 當接收報文時，從網卡驅動開始，通過協議棧層層往上傳送數據報，通過增加 skb->data 的值，來逐步剝離協議首部。
- 當要發送報文時，創建 sk_buff 結構體，數據緩存區的頭部預留足夠的空間，用來填充各層首部，在經過各下層協議時，通過減少 skb->data 的值來增加協議首部。

你可以從下面這張圖看到，當發送報文時，data 指針的移動過程。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F/%E5%A4%9A%E8%B7%AF%E5%A4%8D%E7%94%A8/sk_buff.jpg)

至此，傳輸層的工作也就都完成了。

然後交給網絡層，在網絡層裡會做這些工作：選取路由（確認下一跳的 IP）、填充 IP 頭、netfilter 過濾、對超過 MTU 大小的數據包進行分片。處理完這些工作後會交給網絡接口層處理。

網絡接口層會通過 ARP 協議獲得下一跳的 MAC 地址，然後對 sk_buff 填充幀頭和幀尾，接著將 sk_buff 放到網卡的發送隊列中。

這一些工作準備好後，會觸發「軟中斷」告訴網卡驅動程序，這裡有新的網絡包需要發送，驅動程序會從發送隊列中讀取 sk_buff，將這個 sk_buff 掛到 RingBuffer 中，接著將 sk_buff 數據映射到網卡可訪問的內存 DMA 區域，最後觸發真實的發送。

當數據發送完成以後，其實工作並沒有結束，因為內存還沒有清理。當發送完成的時候，網卡設備會觸發一個硬中斷來釋放內存，主要是釋放 sk_buff 內存和清理  RingBuffer 內存。

最後，當收到這個 TCP 報文的 ACK 應答時，傳輸層就會釋放原始的 sk_buff 。

> 發送網絡數據的時候，涉及幾次內存拷貝操作？

第一次，調用發送數據的系統調用的時候，內核會申請一個內核態的 sk_buff 內存，將用戶待發送的數據拷貝到 sk_buff 內存，並將其加入到發送緩衝區。

第二次，在使用 TCP 傳輸協議的情況下，從傳輸層進入網絡層的時候，每一個 sk_buff 都會被克隆一個新的副本出來。副本 sk_buff 會被送往網絡層，等它發送完的時候就會釋放掉，然後原始的 sk_buff 還保留在傳輸層，目的是為了實現 TCP 的可靠傳輸，等收到這個數據包的 ACK 時，才會釋放原始的 sk_buff 。

第三次，當 IP 層發現 sk_buff 大於 MTU 時才需要進行。會再申請額外的 sk_buff，並將原來的 sk_buff 拷貝為多個小的 sk_buff。

## 總結

電腦與電腦之間通常都是通過話網卡、交換機、路由器等網絡設備連接到一起，那由於網絡設備的異構性，國際標準化組織定義了一個七層的 OSI 網絡模型，但是這個模型由於比較複雜，實際應用中並沒有採用，而是採用了更為簡化的 TCP/IP 模型，Linux 網絡協議棧就是按照了該模型來實現的。

TCP/IP 模型主要分為應用層、傳輸層、網絡層、網絡接口層四層，每一層負責的職責都不同，這也是 Linux 網絡協議棧主要構成部分。

當應用程序通過 Socket 接口發送數據包，數據包會被網絡協議棧從上到下進行逐層處理後，才會被送到網卡隊列中，隨後由網卡將網絡包發送出去。

而在接收網絡包時，同樣也要先經過網絡協議棧從下到上的逐層處理，最後才會被送到應用程序。

----

參考資料：

- Linux 網絡包發送過程：https://mp.weixin.qq.com/s/wThfD9th9e_-YGHJJ3HXNQ
- Linux 網絡數據接收流程（TCP）- NAPI：https://wenfh2020.com/2021/12/29/kernel-tcp-receive/
- Linux網絡-數據包接收過程：https://blog.csdn.net/frank_jb/article/details/115841622

---

哈嘍，我是小林，就愛圖解計算機基礎，如果覺得文章對你有幫助，別忘記關注我哦！

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)
