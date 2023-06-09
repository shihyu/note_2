# 2.1 TCP/IP 網絡模型有哪幾層？

問大家，為什麼要有 TCP/IP 網絡模型？

對於同一臺設備上的進程間通信，有很多種方式，比如有管道、消息隊列、共享內存、信號等方式，而對於不同設備上的進程間通信，就需要網絡通信，而設備是多樣性的，所以要兼容多種多樣的設備，就協商出了一套**通用的網絡協議**。

這個網絡協議是分層的，每一層都有各自的作用和職責，接下來就根據「 TCP/IP 網絡模型」分別對每一層進行介紹。

## 應用層

最上層的，也是我們能直接接觸到的就是**應用層**（*Application Layer*），我們電腦或手機使用的應用軟件都是在應用層實現。那麼，當兩個不同設備的應用需要通信的時候，應用就把應用數據傳給下一層，也就是傳輸層。

所以，應用層只需要專注於為用戶提供應用功能，比如 HTTP、FTP、Telnet、DNS、SMTP等。

應用層是不用去關心數據是如何傳輸的，就類似於，我們寄快遞的時候，只需要把包裹交給快遞員，由他負責運輸快遞，我們不需要關心快遞是如何被運輸的。

而且應用層是工作在操作系統中的用戶態，傳輸層及以下則工作在內核態。


## 傳輸層

應用層的數據包會傳給傳輸層，**傳輸層**（*Transport Layer*）是為應用層提供網絡支持的。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https/應用層.png)


在傳輸層會有兩個傳輸協議，分別是 TCP 和 UDP。

TCP 的全稱叫傳輸控制協議（*Transmission Control Protocol*），大部分應用使用的正是 TCP 傳輸層協議，比如 HTTP 應用層協議。TCP 相比  UDP 多了很多特性，比如流量控制、超時重傳、擁塞控制等，這些都是為了保證數據包能可靠地傳輸給對方。 

UDP 相對來說就很簡單，簡單到只負責發送數據包，不保證數據包是否能抵達對方，但它實時性相對更好，傳輸效率也高。當然，UDP 也可以實現可靠傳輸，把 TCP 的特性在應用層上實現就可以，不過要實現一個商用的可靠 UDP 傳輸協議，也不是一件簡單的事情。


應用需要傳輸的數據可能會非常大，如果直接傳輸就不好控制，因此當傳輸層的數據包大小超過 MSS（TCP 最大報文段長度） ，就要將數據包分塊，這樣即使中途有一個分塊丟失或損壞了，只需要重新發送這一個分塊，而不用重新發送整個數據包。在 TCP 協議中，我們把每個分塊稱為一個 **TCP 段**（*TCP Segment*）。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https/TCP段.png)

當設備作為接收方時，傳輸層則要負責把數據包傳給應用，但是一臺設備上可能會有很多應用在接收或者傳輸數據，因此需要用一個編號將應用區分開來，這個編號就是**端口**。

比如 80 端口通常是 Web 服務器用的，22 端口通常是遠程登錄服務器用的。而對於瀏覽器（客戶端）中的每個標籤欄都是一個獨立的進程，操作系統會為這些進程分配臨時的端口號。

由於傳輸層的報文中會攜帶端口號，因此接收方可以識別出該報文是發送給哪個應用。


## 網絡層


傳輸層可能大家剛接觸的時候，會認為它負責將數據從一個設備傳輸到另一個設備，事實上它並不負責。

實際場景中的網絡環節是錯綜複雜的，中間有各種各樣的線路和分叉路口，如果一個設備的數據要傳輸給另一個設備，就需要在各種各樣的路徑和節點進行選擇，而傳輸層的設計理念是簡單、高效、專注，如果傳輸層還負責這一塊功能就有點違背設計原則了。

也就是說，我們不希望傳輸層協議處理太多的事情，只需要服務好應用即可，讓其作為應用間數據傳輸的媒介，幫助實現應用到應用的通信，而實際的傳輸功能就交給下一層，也就是**網絡層**（*Internet Layer*）。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https/網絡層.png)

網絡層最常使用的是 IP 協議（*Internet Protocol*），IP 協議會將傳輸層的報文作為數據部分，再加上 IP 包頭組裝成 IP 報文，如果 IP 報文大小超過 MTU（以太網中一般為 1500 字節）就會**再次進行分片**，得到一個即將發送到網絡的 IP 報文。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost/計算機網絡/鍵入網址過程/12.jpg)


網絡層負責將數據從一個設備傳輸到另一個設備，世界上那麼多設備，又該如何找到對方呢？因此，網絡層需要有區分設備的編號。

我們一般用 IP 地址給設備進行編號，對於 IPv4 協議， IP 地址共 32 位，分成了四段（比如，192.168.100.1），每段是 8 位。只有一個單純的 IP 地址雖然做到了區分設備，但是尋址起來就特別麻煩，全世界那麼多臺設備，難道一個一個去匹配？這顯然不科學。

因此，需要將 IP 地址分成兩種意義：

- 一個是**網絡號**，負責標識該 IP 地址是屬於哪個「子網」的；
- 一個是**主機號**，負責標識同一「子網」下的不同主機；

怎麼分的呢？這需要配合**子網掩碼**才能算出 IP 地址 的網絡號和主機號。

舉個例子，比如 10.100.122.0/24，後面的`/24`表示就是 `255.255.255.0` 子網掩碼，255.255.255.0 二進制是「11111111-11111111-11111111-00000000」，大家數數一共多少個1？不用數了，是 24 個1，為了簡化子網掩碼的表示，用/24代替255.255.255.0。

知道了子網掩碼，該怎麼計算出網絡地址和主機地址呢？

將 10.100.122.2 和 255.255.255.0 進行**按位與運算**，就可以得到網絡號，如下圖：

![img](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BD%91%E7%BB%9C/IP/16.jpg)

將 255.255.255.0 取反後與IP地址進行進行**按位與運算**，就可以得到主機號。

大家可以去搜索下子網掩碼計算器，自己改變下「掩碼位」的數值，就能體會到子網掩碼的作用了。

![子網掩碼計算器](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4/網絡/子網掩碼計算器.png)

那麼在尋址的過程中，先匹配到相同的網絡號（表示要找到同一個子網），才會去找對應的主機。

除了尋址能力， IP 協議還有另一個重要的能力就是**路由**。實際場景中，兩臺設備並不是用一條網線連接起來的，而是通過很多網關、路由器、交換機等眾多網絡設備連接起來的，那麼就會形成很多條網絡的路徑，因此當數據包到達一個網絡節點，就需要通過路由算法決定下一步走哪條路徑。

路由器尋址工作中，就是要找到目標地址的子網，找到後進而把數據包轉發給對應的網絡內。

![IP地址的網絡號](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BD%91%E7%BB%9C/IP/17.jpg)

所以，**IP 協議的尋址作用是告訴我們去往下一個目的地該朝哪個方向走，路由則是根據「下一個目的地」選擇路徑。尋址更像在導航，路由更像在操作方向盤**。


## 網絡接口層

生成了 IP 頭部之後，接下來要交給**網絡接口層**（*Link Layer*）在 IP 頭部的前面加上 MAC 頭部，並封裝成數據幀（Data frame）發送到網絡上。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/https/網絡接口層.png)

IP 頭部中的接收方 IP 地址表示網絡包的目的地，通過這個地址我們就可以判斷要將包發到哪裡，但在以太網的世界中，這個思路是行不通的。

什麼是以太網呢？電腦上的以太網接口，Wi-Fi 接口，以太網交換機、路由器上的千兆，萬兆以太網口，還有網線，它們都是以太網的組成部分。以太網就是一種在「局域網」內，把附近的設備連接起來，使它們之間可以進行通訊的技術。

以太網在判斷網絡包目的地時和 IP 的方式不同，因此必須採用相匹配的方式才能在以太網中將包發往目的地，而 MAC 頭部就是幹這個用的，所以，在以太網進行通訊要用到 MAC 地址。

MAC 頭部是以太網使用的頭部，它包含了接收方和發送方的 MAC 地址等信息，我們可以通過 ARP 協議獲取對方的 MAC 地址。

所以說，網絡接口層主要為網絡層提供「鏈路級別」傳輸的服務，負責在以太網、WiFi 這樣的底層網絡上發送原始數據包，工作在網卡這個層次，使用 MAC 地址來標識網絡上的設備。

## 總結


綜上所述，TCP/IP 網絡通常是由上到下分成 4 層，分別是**應用層，傳輸層，網絡層和網絡接口層**。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/tcpip參考模型.drawio.png)

再給大家貼一下每一層的封裝格式：

![img](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F/%E6%B5%AE%E7%82%B9/%E5%B0%81%E8%A3%85.png)

網絡接口層的傳輸單位是幀（frame），IP 層的傳輸單位是包（packet），TCP 層的傳輸單位是段（segment），HTTP 的傳輸單位則是消息或報文（message）。但這些名詞並沒有什麼本質的區分，可以統稱為數據包。

---

最新的圖解文章都在公眾號首發，別忘記關注哦！！如果你想加入百人技術交流群，掃碼下方二維碼回覆「加群」。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)

