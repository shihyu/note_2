# 9.4 什麼是一致性哈希？

大家好，我是小林。

在逛牛客網的面經的時候，發現有位同學在面微信的時候，被問到這個問題：

![](https://img-blog.csdnimg.cn/img_convert/2ad888cd9ca79d8d68fbd7ff29a6e088.png)

第一個問題就是：**一致性哈希是什麼，使用場景，解決了什麼問題？**

這個問題還挺有意思的，所以今天就來聊聊這個。

發車！

![](https://img-blog.csdnimg.cn/img_convert/7de125e1b754aa50132e1fa385ad5c0a.png)

## 如何分配請求？

大多數網站背後肯定不是隻有一臺服務器提供服務，因為單機的併發量和數據量都是有限的，所以都會用多臺服務器構成集群來對外提供服務。

但是問題來了，現在有那麼多個節點（後面統稱服務器為節點，因為少一個字），要如何分配客戶端的請求呢？

![](https://img-blog.csdnimg.cn/img_convert/b752a4f8dcaab8ed4d941ebcc6f606c5.png)

其實這個問題就是「負載均衡問題」。解決負載均衡問題的算法很多，不同的負載均衡算法，對應的就是不同的分配策略，適應的業務場景也不同。

最簡單的方式，引入一箇中間的負載均衡層，讓它將外界的請求「輪流」的轉發給內部的集群。比如集群有 3 個節點，外界請求有 3 個，那麼每個節點都會處理 1 個請求，達到了分配請求的目的。

![](https://img-blog.csdnimg.cn/img_convert/d3279ad754257977f98e702cb156e9cf.png)

考慮到每個節點的硬件配置有所區別，我們可以引入權重值，將硬件配置更好的節點的權重值設高，然後根據各個節點的權重值，按照一定比重分配在不同的節點上，讓硬件配置更好的節點承擔更多的請求，這種算法叫做加權輪詢。

加權輪詢算法使用場景是建立在每個節點存儲的數據都是相同的前提。所以，每次讀數據的請求，訪問任意一個節點都能得到結果。

但是，加權輪詢算法是無法應對「分佈式系統」的，因為分佈式系統中，每個節點存儲的數據是不同的。

當我們想提高系統的容量，就會將數據水平切分到不同的節點來存儲，也就是將數據分佈到了不同的節點。比如**一個分佈式 KV（key-valu）  緩存系統，某個 key 應該到哪個或者哪些節點上獲得，應該是確定的**，不是說任意訪問一個節點都可以得到緩存結果的。

因此，我們要想一個能應對分佈式系統的負載均衡算法。

## 使用哈希算法有什麼問題？

有的同學可能很快就想到了：**哈希算法**。因為對同一個關鍵字進行哈希計算，每次計算都是相同的值，這樣就可以將某個 key 確定到一個節點了，可以滿足分佈式系統的負載均衡需求。

哈希算法最簡單的做法就是進行取模運算，比如分佈式系統中有 3 個節點，基於 `hash(key) % 3` 公式對數據進行了映射。

如果客戶端要獲取指定 key 的數據，通過下面的公式可以定位節點：

```
hash(key) % 3
```

如果經過上面這個公式計算後得到的值是 0，就說明該 key 需要去第一個節點獲取。

但是有一個很致命的問題，**如果節點數量發生了變化，也就是在對系統做擴容或者縮容時，必須遷移改變了映射關係的數據**，否則會出現查詢不到數據的問題。

舉個例子，假設我們有一個由 A、B、C 三個節點組成分佈式 KV 緩存系統，基於計算公式 `hash(key) % 3` 將數據進行了映射，每個節點存儲了不同的數據：



![](https://img-blog.csdnimg.cn/img_convert/025ddcaabece1f4b5823dfb1fb7340ef.png)



現在有 3 個查詢 key 的請求，分別查詢 key-01，key-02，key-03 的數據，這三個 key 分別經過 hash() 函數計算後的值為 hash( key-01) = 6、hash( key-02) = 7、hash(key-03) = 8，然後再對這些值進行取模運算。

通過這樣的哈希算法，每個 key 都可以定位到對應的節點。

![](https://img-blog.csdnimg.cn/img_convert/ed14c96417e08b4f916e0cd23d12b7bd.png)



當 3 個節點不能滿足業務需求了，這時我們增加了一個節點，節點的數量從 3 變化為 4，意味取模哈希函數中基數的變化，這樣會導致**大部分映射關係改變**，如下圖：

![](https://img-blog.csdnimg.cn/img_convert/392c54cfb9ec47f5191008aa1d27d6b5.png)



比如，之前的 hash(key-01) % `3` = 0，就變成了 hash(key-01) % `4` = 2，查詢 key-01 數據時，尋址到了節點 C，而  key-01 的數據是存儲在節點 A 上的，不是在節點 C，所以會查詢不到數據。

同樣的道理，如果我們對分佈式系統進行縮容，比如移除一個節點，也會因為取模哈希函數中基數的變化，可能出現查詢不到數據的問題。

要解決這個問題的辦法，就需要我們進行**遷移數據**，比如節點的數量從 3 變化為 4 時，要基於新的計算公式 hash(key) % 4 ，重新對數據和節點做映射。

假設總數據條數為 M，哈希算法在面對節點數量變化時，**最壞情況下所有數據都需要遷移，所以它的數據遷移規模是 O(M)**，這樣數據的遷移成本太高了。

所以，我們應該要重新想一個新的算法，來避免分佈式系統在擴容或者縮容時，發生過多的數據遷移。

## 使用一致性哈希算法有什麼問題？

一致性哈希算法就很好地解決了分佈式系統在擴容或者縮容時，發生過多的數據遷移的問題。

一致哈希算法也用了取模運算，但與哈希算法不同的是，哈希算法是對節點的數量進行取模運算，而**一致哈希算法是對 2^32 進行取模運算，是一個固定的值**。

我們可以把一致哈希算法是對 2^32 進行取模運算的結果值組織成一個圓環，就像鐘錶一樣，鐘錶的圓可以理解成由 60 個點組成的圓，而此處我們把這個圓想象成由 2^32 個點組成的圓，這個圓環被稱為**哈希環**，如下圖：

![](https://img-blog.csdnimg.cn/img_convert/0ea3960fef48d4cbaeb4bec4345301e7.png)

一致性哈希要進行兩步哈希：

- 第一步：對存儲節點進行哈希計算，也就是對存儲節點做哈希映射，比如根據節點的 IP 地址進行哈希；
- 第二步：當對數據進行存儲或訪問時，對數據進行哈希映射；

所以，**一致性哈希是指將「存儲節點」和「數據」都映射到一個首尾相連的哈希環上**。

問題來了，對「數據」進行哈希映射得到一個結果要怎麼找到存儲該數據的節點呢？

答案是，映射的結果值往**順時針的方向的找到第一個節點**，就是存儲該數據的節點。

舉個例子，有 3 個節點經過哈希計算，映射到了如下圖的位置：

![](https://img-blog.csdnimg.cn/img_convert/83d7f363643353c92d252e34f1d4f687.png)

接著，對要查詢的 key-01 進行哈希計算，確定此  key-01 映射在哈希環的位置，然後從這個位置往順時針的方向找到第一個節點，就是存儲該  key-01 數據的節點。

比如，下圖中的  key-01 映射的位置，往順時針的方向找到第一個節點就是節點 A。

![](https://img-blog.csdnimg.cn/img_convert/30c2c70721c12f9c140358fbdc5f2282.png)

所以，當需要對指定 key 的值進行讀寫的時候，要通過下面 2 步進行尋址：

- 首先，對 key 進行哈希計算，確定此 key 在環上的位置；
- 然後，從這個位置沿著順時針方向走，遇到的第一節點就是存儲 key 的節點。

知道了一致哈希尋址的方式，我們來看看，如果增加一個節點或者減少一個節點會發生大量的數據遷移嗎？

假設節點數量從 3 增加到了 4，新的節點 D 經過哈希計算後映射到了下圖中的位置：

![](https://img-blog.csdnimg.cn/img_convert/f8909edef2f3949f8945bb99380baab3.png)

你可以看到，key-01、key-03 都不受影響，只有 key-02  需要被遷移節點 D。

假設節點數量從 3 減少到了 2，比如將節點 A 移除：

![](https://img-blog.csdnimg.cn/img_convert/31485046f1303b57d8aaeaab103ea7ab.png)

你可以看到，key-02 和 key-03 不會受到影響，只有 key-01 需要被遷移節點 B。

因此，**在一致哈希算法中，如果增加或者移除一個節點，僅影響該節點在哈希環上順時針相鄰的後繼節點，其它數據也不會受到影響**。

上面這些圖中 3 個節點映射在哈希環還是比較分散的，所以看起來請求都會「均衡」到每個節點。

但是**一致性哈希算法並不保證節點能夠在哈希環上分佈均勻**，這樣就會帶來一個問題，會有大量的請求集中在一個節點上。

比如，下圖中 3 個節點的映射位置都在哈希環的右半邊：

![](https://img-blog.csdnimg.cn/img_convert/d528bae6fcec2357ba2eb8f324ad9fd5.png)

這時候有一半以上的數據的尋址都會找節點 A，也就是訪問請求主要集中的節點 A 上，這肯定不行的呀，說好的負載均衡呢，這種情況一點都不均衡。

另外，在這種節點分佈不均勻的情況下，進行容災與擴容時，哈希環上的相鄰節點容易受到過大影響，容易發生雪崩式的連鎖反應。

比如，上圖中如果節點 A 被移除了，當節點 A 宕機後，根據一致性哈希算法的規則，其上數據應該全部遷移到相鄰的節點 B 上，這樣，節點 B 的數據量、訪問量都會迅速增加很多倍，一旦新增的壓力超過了節點 B 的處理能力上限，就會導致節點 B 崩潰，進而形成雪崩式的連鎖反應。

所以，**一致性哈希算法雖然減少了數據遷移量，但是存在節點分佈不均勻的問題**。

### 

## 如何通過虛擬節點提高均衡度？

要想解決節點能在哈希環上分配不均勻的問題，就是要有大量的節點，節點數越多，哈希環上的節點分佈的就越均勻。

但問題是，實際中我們沒有那麼多節點。所以這個時候我們就加入**虛擬節點**，也就是對一個真實節點做多個副本。

具體做法是，**不再將真實節點映射到哈希環上，而是將虛擬節點映射到哈希環上，並將虛擬節點映射到實際節點，所以這裡有「兩層」映射關係。**

比如對每個節點分別設置 3 個虛擬節點：

- 對節點 A 加上編號來作為虛擬節點：A-01、A-02、A-03
- 對節點 B 加上編號來作為虛擬節點：B-01、B-02、B-03
- 對節點 C 加上編號來作為虛擬節點：C-01、C-02、C-03

引入虛擬節點後，原本哈希環上只有 3 個節點的情況，就會變成有 9 個虛擬節點映射到哈希環上，哈希環上的節點數量多了 3 倍。

![](https://img-blog.csdnimg.cn/img_convert/dbb57b8d6071d011d05eeadd93269e13.png)

你可以看到，**節點數量多了後，節點在哈希環上的分佈就相對均勻了**。這時候，如果有訪問請求尋址到「A-01」這個虛擬節點，接著再通過「A-01」虛擬節點找到真實節點 A，這樣請求就能訪問到真實節點 A 了。

上面為了方便你理解，每個真實節點僅包含 3 個虛擬節點，這樣能起到的均衡效果其實很有限。而在實際的工程中，虛擬節點的數量會大很多，比如 Nginx 的一致性哈希算法，每個權重為 1 的真實節點就含有160 個虛擬節點。

另外，虛擬節點除了會提高節點的均衡度，還會提高系統的穩定性。**當節點變化時，會有不同的節點共同分擔系統的變化，因此穩定性更高**。

比如，當某個節點被移除時，對應該節點的多個虛擬節點均會移除，而這些虛擬節點按順時針方向的下一個虛擬節點，可能會對應不同的真實節點，即這些不同的真實節點共同分擔了節點變化導致的壓力。

而且，有了虛擬節點後，還可以為硬件配置更好的節點增加權重，比如對權重更高的節點增加更多的虛擬機節點即可。

因此，**帶虛擬節點的一致性哈希方法不僅適合硬件配置不同的節點的場景，而且適合節點規模會發生變化的場景**。

## 總結

不同的負載均衡算法適用的業務場景也不同的。

輪訓這類的策略只能適用與每個節點的數據都是相同的場景，訪問任意節點都能請求到數據。但是不適用分佈式系統，因為分佈式系統意味著數據水平切分到了不同的節點上，訪問數據的時候，一定要尋址存儲該數據的節點。

哈希算法雖然能建立數據和節點的映射關係，但是每次在節點數量發生變化的時候，最壞情況下所有數據都需要遷移，這樣太麻煩了，所以不適用節點數量變化的場景。

為了減少遷移的數據量，就出現了一致性哈希算法。

一致性哈希是指將「存儲節點」和「數據」都映射到一個首尾相連的哈希環上，如果增加或者移除一個節點，僅影響該節點在哈希環上順時針相鄰的後繼節點，其它數據也不會受到影響。

但是一致性哈希算法不能夠均勻的分佈節點，會出現大量請求都集中在一個節點的情況，在這種情況下進行容災與擴容時，容易出現雪崩的連鎖反應。

為瞭解決一致性哈希算法不能夠均勻的分佈節點的問題，就需要引入虛擬節點，對一個真實節點做多個副本。不再將真實節點映射到哈希環上，而是將虛擬節點映射到哈希環上，並將虛擬節點映射到實際節點，所以這裡有「兩層」映射關係。

引入虛擬節點後，可以會提高節點的均衡度，還會提高系統的穩定性。所以，帶虛擬節點的一致性哈希方法不僅適合硬件配置不同的節點的場景，而且適合節點規模會發生變化的場景。

完！

## 關注作者

***哈嘍，我是小林，就愛圖解計算機基礎，如果覺得文章對你有幫助，歡迎微信搜索「小林coding」，關注後，回覆「網絡」再送你圖解網絡 PDF***

![](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost3@main/其他/公眾號介紹.png)