# 3.2 HTTP/1.1 如何優化？

問你一句：「**你知道 HTTP/1.1 該如何優化嗎？**」

我們可以從下面這三種優化思路來優化 HTTP/1.1 協議：

- *儘量避免發送 HTTP 請求*；
- *在需要發送 HTTP 請求時，考慮如何減少請求次數*；
- *減少服務器的 HTTP 響應的數據大小*；

下面，就針對這三種思路具體看看有哪些優化方法。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/優化http1.1提綱.png)


---

## 如何避免發送 HTTP 請求？

這個思路你看到是不是覺得很奇怪，不發送 HTTP 請求，那客戶端還怎麼和服務器交互數據？小林你這不是耍流氓嘛？

冷靜冷靜，你說的沒錯，客戶端當然要向服務器發送請求的。

但是，對於一些具有重複性的 HTTP 請求，比如每次請求得到的數據都一樣的，我們可以把這對「請求-響應」的數據都**緩存在本地**，那麼下次就直接讀取本地的數據，不必在通過網絡獲取服務器的響應了，這樣的話 HTTP/1.1 的性能肯定肉眼可見的提升。

所以，避免發送 HTTP 請求的方法就是通過**緩存技術**，HTTP 設計者早在之前就考慮到了這點，因此 HTTP 協議的頭部有不少是針對緩存的字段。

那緩存是如何做到的呢？

客戶端會把第一次請求以及響應的數據保存在本地磁盤上，其中將請求的 URL 作為 key，而響應作為 value，兩者形成映射關係。


這樣當後續發起相同的請求時，就可以先在本地磁盤上通過 key 查到對應的 value，也就是響應，如果找到了，就直接從本地讀取該響應。毋庸置疑，讀取本地磁盤的速度肯定比網絡請求快得多，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/緩存訪問.png)

聰明的你可能想到了，萬一緩存的響應不是最新的，而客戶端並不知情，那麼該怎麼辦呢？

放心，這個問題 HTTP 設計者早已考慮到。

所以，服務器在發送 HTTP 響應時，會估算一個過期的時間，並把這個信息放到響應頭部中，這樣客戶端在查看響應頭部的信息時，一旦發現緩存的響應是過期的，則就會重新發送網絡請求。

如果客戶端從第一次請求得到的響應頭部中發現該響應過期了，客戶端重新發送請求，假設服務器上的資源並沒有變更，還是老樣子，那麼你覺得還要在服務器的響應帶上這個資源嗎？

很顯然不帶的話，可以提高 HTTP 協議的性能，那具體如何做到呢？ 

只需要客戶端在重新發送請求時，在請求的 `Etag` 頭部帶上第一次請求的響應頭部中的摘要，這個摘要是唯一標識響應的資源，當服務器收到請求後，會將本地資源的摘要與請求中的摘要做個比較。

如果不同，那麼說明客戶端的緩存已經沒有價值，服務器在響應中帶上最新的資源。

如果相同，說明客戶端的緩存還是可以繼續使用的，那麼服務器**僅返回不含有包體的 `304 Not Modified` 響應**，告訴客戶端仍然有效，這樣就可以減少響應資源在網絡中傳輸的延時，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/緩存etag.png)

緩存真的是性能優化的一把萬能鑰匙，小到 CPU Cache、Page Cache、Redis Cache，大到 HTTP 協議的緩存。


---

## 如何減少 HTTP 請求次數？

減少 HTTP 請求次數自然也就提升了 HTTP 性能，可以從這 3 個方面入手：

- *減少重定向請求次數*；
- *合併請求*；
- *延遲發送請求*；

### 減少重定向請求次數

我們先來看看什麼是**重定向請求**？

服務器上的一個資源可能由於遷移、維護等原因從 url1 移至 url2 後，而客戶端不知情，它還是繼續請求 url1，這時服務器不能粗暴地返回錯誤，而是通過 `302` 響應碼和 `Location` 頭部，告訴客戶端該資源已經遷移至 url2 了，於是客戶端需要再發送 url2 請求以獲得服務器的資源。

那麼，如果重定向請求越多，那麼客戶端就要多次發起 HTTP 請求，每一次的 HTTP 請求都得經過網絡，這無疑會越降低網絡性能。

另外，服務端這一方往往不只有一臺服務器，比如源服務器上一級是代理服務器，然後代理服務器才與客戶端通信，這時客戶端重定向就會導致客戶端與代理服務器之間需要 2 次消息傳遞，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/客戶端重定向.png)


如果**重定向的工作交由代理服務器完成，就能減少 HTTP 請求次數了**，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/代理服務器重定向.png)

而且當代理服務器知曉了重定向規則後，可以進一步減少消息傳遞次數，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/代理服務器重定向2.png)

除了 `302` 重定向響應碼，還有其他一些重定向的響應碼，你可以從下圖看到：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/重定向響應碼.png)

其中，`301` 和 `308` 響應碼是告訴客戶端可以將重定向響應緩存到本地磁盤，之後客戶端就自動用 url2 替代 url1 訪問服務器的資源。



### 合併請求

如果把多個訪問小文件的請求合併成一個大的請求，雖然傳輸的總資源還是一樣，但是減少請求，也就意味著**減少了重複發送的 HTTP 頭部**。

另外由於 HTTP/1.1 是請求響應模型，如果第一個發送的請求，未收到對應的響應，那麼後續的請求就不會發送（PS：HTTP/1.1 管道模式是默認不使用的，所以討論 HTTP/1.1  的隊頭阻塞問題，是不考慮管道模式的），於是為了防止單個請求的阻塞，所以**一般瀏覽器會同時發起 5-6 個請求，每一個請求都是不同的 TCP 連接**，那麼如果合併了請求，也就會**減少 TCP 連接的數量，因而省去了  TCP 握手和慢啟動過程耗費的時間**。


接下來，具體看看合併請求的幾種方式。

有的網頁會含有很多小圖片、小圖標，有多少個小圖片，客戶端就要發起多少次請求。那麼對於這些小圖片，我們可以考慮使用 `CSS Image Sprites` 技術把它們合成一個大圖片，這樣瀏覽器就可以用一次請求獲得一個大圖片，然後再根據 CSS 數據把大圖片切割成多張小圖片。

![圖來源於：墨染楓林的CSDN](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/css精靈.png)

這種方式就是**通過將多個小圖片合併成一個大圖片來減少 HTTP 請求的次數，以減少 HTTP 請求的次數，從而減少網絡的開銷**。


除了將小圖片合併成大圖片的方式，還有服務端使用 `webpack` 等打包工具將 js、css 等資源合併打包成大文件，也是能達到類似的效果。

另外，還可以將圖片的二進制數據用 `base64` 編碼後，以 URL 的形式嵌入到 HTML 文件，跟隨 HTML 文件一併發送.


```
<image src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAAFKCAIAAAC7M9WrAAAACXBIWXMAA ... />
```



這樣客戶端收到 HTML 後，就可以直接解碼出數據，然後直接顯示圖片，就不用再發起圖片相關的請求，這樣便減少了請求的次數。

![圖來源於：陳健平的CSDN ](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/base64圖片.png)



可以看到，**合併請求的方式就是合併資源，以一個大資源的請求替換多個小資源的請求**。

但是這樣的合併請求會帶來新的問題，**當大資源中的某一個小資源發生變化後，客戶端必須重新下載整個完整的大資源文件**，這顯然帶來了額外的網絡消耗。


### 延遲發送請求

不要一口氣吃成大胖子，一般 HTML 裡會含有很多 HTTP 的 URL，當前不需要的資源，我們沒必要也獲取過來，於是可以通過「**按需獲取**」的方式，來減少第一時間的 HTTP 請求次數。

請求網頁的時候，沒必要把全部資源都獲取到，而是隻獲取當前用戶所看到的頁面資源，當用戶向下滑動頁面的時候，再向服務器獲取接下來的資源，這樣就達到了延遲發送請求的效果。

----


## 如何減少 HTTP 響應的數據大小？

對於 HTTP 的請求和響應，通常 HTTP 的響應的數據大小會比較大，也就是服務器返回的資源會比較大。

於是，我們可以考慮對響應的資源進行**壓縮**，這樣就可以減少響應的數據大小，從而提高網絡傳輸的效率。

壓縮的方式一般分為 2 種，分別是：

- *無損壓縮*；
- *有損壓縮*；

### 無損壓縮

無損壓縮是指資源經過壓縮後，信息不被破壞，還能完全恢復到壓縮前的原樣，適合用在文本文件、程序可執行文件、程序源代碼。

首先，我們針對代碼的語法規則進行壓縮，因為通常代碼文件都有很多換行符或者空格，這些是為了幫助程序員更好的閱讀，但是機器執行時並不要這些符，把這些多餘的符號給去除掉。

接下來，就是無損壓縮了，需要對原始資源建立統計模型，利用這個統計模型，將常出現的數據用較短的二進制比特序列表示，將不常出現的數據用較長的二進制比特序列表示，生成二進制比特序列一般是「霍夫曼編碼」算法。

gzip 就是比較常見的無損壓縮。客戶端支持的壓縮算法，會在 HTTP 請求中通過頭部中的 `Accept-Encoding` 字段告訴服務器：


```
Accept-Encoding: gzip, deflate, br
```

服務器收到後，會從中選擇一個服務器支持的或者合適的壓縮算法，然後使用此壓縮算法對響應資源進行壓縮，最後通過響應頭部中的 `Content-Encoding` 字段告訴客戶端該資源使用的壓縮算法。


```
Content-Encoding: gzip
```

gzip 的壓縮效率相比 Google 推出的 Brotli 算法還是差點意思，也就是上文中的 br，所以如果可以，服務器應該選擇壓縮效率更高的 br 壓縮算法。

### 有損壓縮

與無損壓縮相對的就是有損壓縮，經過此方法壓縮，解壓的數據會與原始數據不同但是非常接近。

有損壓縮主要將次要的數據捨棄，犧牲一些質量來減少數據量、提高壓縮比，這種方法經常用於壓縮多媒體數據，比如音頻、視頻、圖片。

可以通過 HTTP 請求頭部中的 `Accept` 字段裡的「 q 質量因子」，告訴服務器期望的資源質量。

```
Accept: audio/*; q=0.2, audio/basic
```

關於圖片的壓縮，目前壓縮比較高的是 Google 推出的 **WebP 格式**，它與常見的 Png 格式圖片的壓縮比例對比如下圖：

![來源於：https://isparta.github.io/compare-webp/index.html](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/網絡/http1.1優化/webp與png.png)

可以發現，相同圖片質量下，WebP 格式的圖片大小都比 Png 格式的圖片小，所以對於大量圖片的網站，可以考慮使用 WebP 格式的圖片，這將大幅度提升網絡傳輸的性能。

關於音視頻的壓縮，音視頻主要是動態的，每個幀都有時序的關係，通常時間連續的幀之間的變化是很小的。

比如，一個在看書的視頻，畫面通常只有人物的手和書桌上的書是會有變化的，而其他地方通常都是靜態的，於是隻需要在一個靜態的關鍵幀，使用**增量數據**來表達後續的幀，這樣便減少了很多數據，提高了網絡傳輸的性能。對於視頻常見的編碼格式有 H264、H265 等，音頻常見的編碼格式有 AAC、AC3。


---

## 總結

這次主要從 3 個方面介紹了優化 HTTP/1.1 協議的思路。

第一個思路是，通過緩存技術來避免發送 HTTP 請求。客戶端收到第一個請求的響應後，可以將其緩存在本地磁盤，下次請求的時候，如果緩存沒過期，就直接讀取本地緩存的響應數據。如果緩存過期，客戶端發送請求的時候帶上響應數據的摘要，服務器比對後發現資源沒有變化，就發出不帶包體的 304 響應，告訴客戶端緩存的響應仍然有效。

第二個思路是，減少 HTTP 請求的次數，有以下的方法：

1. 將原本由客戶端處理的重定向請求，交給代理服務器處理，這樣可以減少重定向請求的次數；
2. 將多個小資源合併成一個大資源再傳輸，能夠減少 HTTP 請求次數以及 頭部的重複傳輸，再來減少 TCP 連接數量，進而省去 TCP 握手和慢啟動的網絡消耗；
3. 按需訪問資源，只訪問當前用戶看得到/用得到的資源，當客戶往下滑動，再訪問接下來的資源，以此達到延遲請求，也就減少了同一時間的 HTTP 請求次數。

第三思路是，通過壓縮響應資源，降低傳輸資源的大小，從而提高傳輸效率，所以應當選擇更優秀的壓縮算法。


不管怎麼優化 HTTP/1.1 協議都是有限的，不然也不會出現 HTTP/2 和 HTTP/3 協議，後續我們再來介紹 HTTP/2 和 HTTP/3 協議。

好了，此次分享到這就結束了，如果這篇文章對你有幫助，歡迎來個三連，你們的支持就是小林的最大動力，我們下次見！

---

參考資料：

1. https://isparta.github.io/compare-webp/index.html
2. https://zh.wikipedia.org/wiki/https://en.wikipedia.org/wiki/Lossy_compression
3. https://en.wikipedia.org/wiki/Lossless_compression
4. https://time.geekbang.org/column/article/242667
5. https://www.tutorialrepublic.com/css-tutorial/css-sprites.php
6. https://blog.csdn.net/weixin_38055381/article/details/81504716
7. https://blog.csdn.net/weixin_44151887/article/details/106278559

---

哈嘍，我是小林，就愛圖解計算機基礎，如果文章對你有幫助，別忘記關注哦！

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)
