# 4.3 內存滿了，會發生什麼？

大家好，我是小林。

前幾天有位讀者留言說，面騰訊時，被問了兩個內存管理的問題：

![](https://img-blog.csdnimg.cn/cbe38428e4e644dd81ab5e85545cacf7.png)

![](https://img-blog.csdnimg.cn/90a7216d65b4454ba185db2a2d6c2b8a.png)

先來說說第一個問題：虛擬內存有什麼作用？

- 第一，虛擬內存可以使得進程對運行內存超過物理內存大小，因為程序運行符合局部性原理，CPU 訪問內存會有很明顯的重複訪問的傾向性，對於那些沒有被經常使用到的內存，我們可以把它換出到物理內存之外，比如硬盤上的 swap 區域。
- 第二，由於每個進程都有自己的頁表，所以每個進程的虛擬內存空間就是相互獨立的。進程也沒有辦法訪問其他進程的頁表，所以這些頁表是私有的，這就解決了多進程之間地址衝突的問題。
- 第三，頁表裡的頁表項中除了物理地址之外，還有一些標記屬性的比特，比如控制一個頁的讀寫權限，標記該頁是否存在等。在內存訪問方面，操作系統提供了更好的安全性。

然後今天主要是聊聊第二個問題，「**系統內存緊張時，會發生什麼？**」

發車！

![](https://img-blog.csdnimg.cn/e069da38c4b54ee98a585a176e2c342f.png)

## 內存分配的過程是怎樣的？

應用程序通過 malloc 函數申請內存的時候，實際上申請的是虛擬內存，此時並不會分配物理內存。

當應用程序讀寫了這塊虛擬內存，CPU 就會去訪問這個虛擬內存， 這時會發現這個虛擬內存沒有映射到物理內存， CPU 就會產生**缺頁中斷**，進程會從用戶態切換到內核態，並將缺頁中斷交給內核的 Page Fault Handler （缺頁中斷函數）處理。

缺頁中斷處理函數會看是否有空閒的物理內存，如果有，就直接分配物理內存，並建立虛擬內存與物理內存之間的映射關係。

如果沒有空閒的物理內存，那麼內核就會開始進行**回收內存**的工作，回收的方式主要是兩種：直接內存回收和後臺內存回收。

- **後臺內存回收**（kswapd）：在物理內存緊張的時候，會喚醒 kswapd 內核線程來回收內存，這個回收內存的過程**異步**的，不會阻塞進程的執行。
- **直接內存回收**（direct reclaim）：如果後臺異步回收跟不上進程內存申請的速度，就會開始直接回收，這個回收內存的過程是**同步**的，會阻塞進程的執行。

如果直接內存回收後，空閒的物理內存仍然無法滿足此次物理內存的申請，那麼內核就會放最後的大招了 ——**觸發 OOM （Out of Memory）機制**。

OOM Killer 機制會根據算法選擇一個佔用物理內存較高的進程，然後將其殺死，以便釋放內存資源，如果物理內存依然不足，OOM Killer 會繼續殺死佔用物理內存較高的進程，直到釋放足夠的內存位置。

申請物理內存的過程如下圖：

![](https://img-blog.csdnimg.cn/2f61b0822b3c4a359f99770231981b07.png)

## 哪些內存可以被回收？

系統內存緊張的時候，就會進行回收內存的工作，那具體哪些內存是可以被回收的呢？

主要有兩類內存可以被回收，而且它們的回收方式也不同。

- **文件頁**（File-backed Page）：內核緩存的磁盤數據（Buffer）和內核緩存的文件數據（Cache）都叫作文件頁。大部分文件頁，都可以直接釋放內存，以後有需要時，再從磁盤重新讀取就可以了。而那些被應用程序修改過，並且暫時還沒寫入磁盤的數據（也就是髒頁），就得先寫入磁盤，然後才能進行內存釋放。所以，**回收乾淨頁的方式是直接釋放內存，回收髒頁的方式是先寫回磁盤後再釋放內存**。
- **匿名頁**（Anonymous Page）：這部分內存沒有實際載體，不像文件緩存有硬盤文件這樣一個載體，比如堆、棧數據等。這部分內存很可能還要再次被訪問，所以不能直接釋放內存，它們**回收的方式是通過 Linux 的 Swap 機制**，Swap 會把不常訪問的內存先寫到磁盤中，然後釋放這些內存，給其他更需要的進程使用。再次訪問這些內存時，重新從磁盤讀入內存就可以了。

文件頁和匿名頁的回收都是基於 LRU 算法，也就是優先回收不常訪問的內存。LRU 回收算法，實際上維護著 active 和 inactive 兩個雙向鏈表，其中：

- **active_list** 活躍內存頁鏈表，這裡存放的是最近被訪問過（活躍）的內存頁；
- **inactive_list** 不活躍內存頁鏈表，這裡存放的是很少被訪問（非活躍）的內存頁；

越接近鏈表尾部，就表示內存頁越不常訪問。這樣，在回收內存時，系統就可以根據活躍程度，優先回收不活躍的內存。

活躍和非活躍的內存頁，按照類型的不同，又分別分為文件頁和匿名頁。可以從 /proc/meminfo 中，查詢它們的大小，比如：

```shell
# grep表示只保留包含active的指標（忽略大小寫）
# sort表示按照字母順序排序
[root@xiaolin ~]# cat /proc/meminfo | grep -i active | sort
Active:           901456 kB
Active(anon):     227252 kB
Active(file):     674204 kB
Inactive:         226232 kB
Inactive(anon):    41948 kB
Inactive(file):   184284 kB
```

## 回收內存帶來的性能影響

在前面我們知道了回收內存有兩種方式。

- 一種是後臺內存回收，也就是喚醒 kswapd 內核線程，這種方式是異步回收的，不會阻塞進程。
- 一種是直接內存回收，這種方式是同步回收的，會阻塞進程，這樣就會造成很長時間的延遲，以及系統的 CPU 利用率會升高，最終引起系統負荷飆高。

可被回收的內存類型有文件頁和匿名頁：

- 文件頁的回收：對於乾淨頁是直接釋放內存，這個操作不會影響性能，而對於髒頁會先寫回到磁盤再釋放內存，這個操作會發生磁盤 I/O 的，這個操作是會影響系統性能的。
- 匿名頁的回收：如果開啟了 Swap 機制，那麼 Swap 機制會將不常訪問的匿名頁換出到磁盤中，下次訪問時，再從磁盤換入到內存中，這個操作是會影響系統性能的。

可以看到，回收內存的操作基本都會發生磁盤 I/O 的，如果回收內存的操作很頻繁，意味著磁盤 I/O 次數會很多，這個過程勢必會影響系統的性能，整個系統給人的感覺就是很卡。

下面針對回收內存導致的性能影響，說說常見的解決方式。

### 調整文件頁和匿名頁的回收傾向

從文件頁和匿名頁的回收操作來看，文件頁的回收操作對系統的影響相比匿名頁的回收操作會少一點，因為文件頁對於乾淨頁回收是不會發生磁盤 I/O 的，而匿名頁的 Swap 換入換出這兩個操作都會發生磁盤 I/O。

Linux 提供了一個 `/proc/sys/vm/swappiness` 選項，用來調整文件頁和匿名頁的回收傾向。

swappiness 的範圍是 0-100，數值越大，越積極使用 Swap，也就是更傾向於回收匿名頁；數值越小，越消極使用 Swap，也就是更傾向於回收文件頁。

```shell
[root@xiaolin ~]# cat /proc/sys/vm/swappiness
0
```

一般建議 swappiness 設置為 0（默認值是 60），這樣在回收內存的時候，會更傾向於文件頁的回收，但是並不代表不會回收匿名頁。

### 儘早觸發 kswapd 內核線程異步回收內存

> 如何查看系統的直接內存回收和後臺內存回收的指標？

我們可以使用 `sar -B 1` 命令來觀察：

![](https://img-blog.csdnimg.cn/8acb6b28d0fc4858bd57be147d087def.png)

圖中紅色框住的就是後臺內存回收和直接內存回收的指標，它們分別表示：

- pgscank/s : kswapd(後臺回收線程) 每秒掃描的 page 個數。
- pgscand/s: 應用程序在內存申請過程中每秒直接掃描的 page 個數。
- pgsteal/s: 掃描的 page 中每秒被回收的個數（pgscank+pgscand）。

如果系統時不時發生抖動，並且在抖動的時間段裡如果通過 sar -B 觀察到 pgscand 數值很大，那大概率是因為「直接內存回收」導致的。

針對這個問題，解決的辦法就是，可以通過儘早的觸發「後臺內存回收」來避免應用程序進行直接內存回收。

> 什麼條件下才能觸發 kswapd 內核線程回收內存呢？

內核定義了三個內存閾值（watermark，也稱為水位），用來衡量當前剩餘內存（pages_free）是否充裕或者緊張，分別是：

- 頁最小閾值（pages_min）；
- 頁低閾值（pages_low）；
- 頁高閾值（pages_high）；

這三個內存閾值會劃分為四種內存使用情況，如下圖：

![](https://img-blog.csdnimg.cn/166bc9f5b7c545d89f1e36ab8dd772cf.png)

kswapd 會定期掃描內存的使用情況，根據剩餘內存（pages_free）的情況來進行內存回收的工作。

- 圖中綠色部分：如果剩餘內存（pages_free）大於 頁高閾值（pages_high），說明剩餘內存是充足的；

- 圖中藍色部分：如果剩餘內存（pages_free）在頁高閾值（pages_high）和頁低閾值（pages_low）之間，說明內存有一定壓力，但還可以滿足應用程序申請內存的請求；
- 圖中橙色部分：如果剩餘內存（pages_free）在頁低閾值（pages_low）和頁最小閾值（pages_min）之間，說明內存壓力比較大，剩餘內存不多了。**這時 kswapd0 會執行內存回收，直到剩餘內存大於高閾值（pages_high）為止**。雖然會觸發內存回收，但是不會阻塞應用程序，因為兩者關係是異步的。
- 圖中紅色部分：如果剩餘內存（pages_free）小於頁最小閾值（pages_min），說明用戶可用內存都耗盡了，此時就會**觸發直接內存回收**，這時應用程序就會被阻塞，因為兩者關係是同步的。

可以看到，當剩餘內存頁（pages_free）小於頁低閾值（pages_low），就會觸發 kswapd 進行後臺回收，然後 kswapd 會一直回收到剩餘內存頁（pages_free）大於頁高閾值（pages_high）。

也就是說 kswapd 的活動空間只有 pages_low 與 pages_min 之間的這段區域，如果剩餘內存低於了 pages_min 會觸發直接內存回收，高於了 pages_high 又不會喚醒 kswapd。

頁低閾值（pages_low）可以通過內核選項  `/proc/sys/vm/min_free_kbytes` （該參數代表系統所保留空閒內存的最低限）來間接設置。

min_free_kbytes 雖然設置的是頁最小閾值（pages_min），但是頁高閾值（pages_high）和頁低閾值（pages_low）都是根據頁最小閾值（pages_min）計算生成的，它們之間的計算關係如下：

```
pages_min = min_free_kbytes
pages_low = pages_min*5/4
pages_high = pages_min*3/2
```

如果系統時不時發生抖動，並且通過 sar -B 觀察到 pgscand 數值很大，那大概率是因為直接內存回收導致的，這時可以增大 min_free_kbytes 這個配置選項來及早地觸發後臺回收，然後繼續觀察 pgscand 是否會降為 0。

增大了 min_free_kbytes 配置後，這會使得系統預留過多的空閒內存，從而在一定程度上降低了應用程序可使用的內存量，這在一定程度上浪費了內存。極端情況下設置 min_free_kbytes 接近實際物理內存大小時，留給應用程序的內存就會太少而可能會頻繁地導致 OOM 的發生。

所以在調整 min_free_kbytes 之前，需要先思考一下，應用程序更加關注什麼，如果關注延遲那就適當地增大 min_free_kbytes，如果關注內存的使用量那就適當地調小 min_free_kbytes。

### NUMA 架構下的內存回收策略

> 什麼是 NUMA 架構？

再說 NUMA 架構前，先給大家說說 SMP 架構，這兩個架構都是針對 CPU 的。

 SMP 指的是一種**多個 CPU 處理器共享資源的電腦硬件架構**，也就是說每個 CPU 地位平等，它們共享相同的物理資源，包括總線、內存、IO、操作系統等。每個 CPU 訪問內存所用時間都是相同的，因此，這種系統也被稱為一致存儲訪問結構（UMA，Uniform Memory Access）。

隨著 CPU 處理器核數的增多，多個 CPU 都通過一個總線訪問內存，這樣總線的帶寬壓力會越來越大，同時每個 CPU 可用帶寬會減少，這也就是 SMP 架構的問題。

![SMP 與 NUMA 架構](https://img-blog.csdnimg.cn/img_convert/feec409868070d8cd79aecad2895b531.png)

為瞭解決 SMP 架構的問題，就研製出了 NUMA 結構，即非一致存儲訪問結構（Non-uniform memory access，NUMA）。

NUMA 架構將每個 CPU  進行了分組，每一組 CPU 用 Node 來表示，一個 Node 可能包含多個 CPU 。

**每個 Node 有自己獨立的資源，包括內存、IO 等**，每個 Node 之間可以通過互聯模塊總線（QPI）進行通信，所以，也就意味著每個 Node 上的 CPU 都可以訪問到整個系統中的所有內存。但是，訪問遠端 Node 的內存比訪問本地內存要耗時很多。

> NUMA 架構跟回收內存有什麼關係？

在 NUMA 架構下，當某個 Node 內存不足時，系統可以從其他 Node 尋找空閒內存，也可以從本地內存中回收內存。

具體選哪種模式，可以通過 /proc/sys/vm/zone_reclaim_mode 來控制。它支持以下幾個選項：

- 0 （默認值）：在回收本地內存之前，在其他 Node 尋找空閒內存；
- 1：只回收本地內存；
- 2：只回收本地內存，在本地回收內存時，可以將文件頁中的髒頁寫回硬盤，以回收內存。
- 4：只回收本地內存，在本地回收內存時，可以用 swap 方式回收內存。

在使用 NUMA 架構的服務器，如果系統出現還有一半內存的時候，卻發現系統頻繁觸發「直接內存回收」，導致了影響了系統性能，那麼大概率是因為 zone_reclaim_mode 沒有設置為 0 ，導致當本地內存不足的時候，只選擇回收本地內存的方式，而不去使用其他 Node 的空閒內存。

雖然說訪問遠端 Node 的內存比訪問本地內存要耗時很多，但是相比內存回收的危害而言，訪問遠端 Node 的內存帶來的性能影響還是比較小的。因此，zone_reclaim_mode 一般建議設置為 0。

## 如何保護一個進程不被 OOM 殺掉呢？

在系統空閒內存不足的情況，進程申請了一個很大的內存，如果直接內存回收都無法回收出足夠大的空閒內存，那麼就會觸發 OOM 機制，內核就會根據算法選擇一個進程殺掉。

Linux 到底是根據什麼標準來選擇被殺的進程呢？這就要提到一個在 Linux 內核裡有一個 `oom_badness()` 函數，它會把系統中可以被殺掉的進程掃描一遍，並對每個進程打分，得分最高的進程就會被首先殺掉。

進程得分的結果受下面這兩個方面影響：

- 第一，進程已經使用的物理內存頁面數。
- 第二，每個進程的 OOM 校準值 oom_score_adj。它是可以通過 `/proc/[pid]/oom_score_adj` 來配置的。我們可以在設置 -1000 到 1000 之間的任意一個數值，調整進程被 OOM Kill 的機率。

函數 oom_badness() 裡的最終計算方法是這樣的：

```c
// points 代表打分的結果
// process_pages 代表進程已經使用的物理內存頁面數
// oom_score_adj 代表 OOM 校準值
// totalpages 代表系統總的可用頁面數
points = process_pages + oom_score_adj*totalpages/1000
```

**用「系統總的可用頁面數」乘以 「OOM 校準值 oom_score_adj」再除以 1000，最後再加上進程已經使用的物理頁面數，計算出來的值越大，那麼這個進程被 OOM Kill 的機率也就越大**。

每個進程的 oom_score_adj 默認值都為 0，所以最終得分跟進程自身消耗的內存有關，消耗的內存越大越容易被殺掉。我們可以通過調整 oom_score_adj 的數值，來改成進程的得分結果：

- 如果你不想某個進程被首先殺掉，那你可以調整該進程的 oom_score_adj，從而改變這個進程的得分結果，降低該進程被 OOM 殺死的概率。
- 如果你想某個進程無論如何都不能被殺掉，那你可以將 oom_score_adj 配置為 -1000。

我們最好將一些很重要的系統服務的 oom_score_adj 配置為 -1000，比如 sshd，因為這些系統服務一旦被殺掉，我們就很難再登陸進系統了。

但是，不建議將我們自己的業務程序的 oom_score_adj 設置為 -1000，因為業務程序一旦發生了內存洩漏，而它又不能被殺掉，這就會導致隨著它的內存開銷變大，OOM killer 不停地被喚醒，從而把其他進程一個個給殺掉。

參考資料：

- https://time.geekbang.org/column/article/277358
- https://time.geekbang.org/column/article/75797
- https://www.jianshu.com/p/e40e8813842f

## 總結

內核在給應用程序分配物理內存的時候，如果空閒物理內存不夠，那麼就會進行內存回收的工作，主要有兩種方式：

- 後臺內存回收：在物理內存緊張的時候，會喚醒 kswapd 內核線程來回收內存，這個回收內存的過程異步的，不會阻塞進程的執行。
- 直接內存回收：如果後臺異步回收跟不上進程內存申請的速度，就會開始直接回收，這個回收內存的過程是同步的，會阻塞進程的執行。

可被回收的內存類型有文件頁和匿名頁：

- 文件頁的回收：對於乾淨頁是直接釋放內存，這個操作不會影響性能，而對於髒頁會先寫回到磁盤再釋放內存，這個操作會發生磁盤 I/O 的，這個操作是會影響系統性能的。
- 匿名頁的回收：如果開啟了 Swap 機制，那麼 Swap 機制會將不常訪問的匿名頁換出到磁盤中，下次訪問時，再從磁盤換入到內存中，這個操作是會影響系統性能的。

文件頁和匿名頁的回收都是基於 LRU 算法，也就是優先回收不常訪問的內存。回收內存的操作基本都會發生磁盤 I/O 的，如果回收內存的操作很頻繁，意味著磁盤 I/O 次數會很多，這個過程勢必會影響系統的性能。

針對回收內存導致的性能影響，常見的解決方式。

- 設置 /proc/sys/vm/swappiness，調整文件頁和匿名頁的回收傾向，儘量傾向於回收文件頁；
- 設置 /proc/sys/vm/min_free_kbytes，調整 kswapd 內核線程異步回收內存的時機；
- 設置  /proc/sys/vm/zone_reclaim_mode，調整 NUMA 架構下內存回收策略，建議設置為 0，這樣在回收本地內存之前，會在其他 Node 尋找空閒內存，從而避免在系統還有很多空閒內存的情況下，因本地 Node 的本地內存不足，發生頻繁直接內存回收導致性能下降的問題；

在經歷完直接內存回收後，空閒的物理內存大小依然不夠，那麼就會觸發 OOM 機制，OOM killer 就會根據每個進程的內存佔用情況和 oom_score_adj 的值進行打分，得分最高的進程就會被首先殺掉。

我們可以通過調整進程的 /proc/[pid]/oom_score_adj 值，來降低被 OOM killer 殺掉的概率。

完！

---

新的圖解文章都在公眾號首發，別忘記關注了哦！如果你想加入百人技術交流群，掃碼下方二維碼回覆「加群」。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)