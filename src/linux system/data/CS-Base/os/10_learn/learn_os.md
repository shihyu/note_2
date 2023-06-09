# 11.1 操作系統怎麼學？

操作系統真的可以說是 `Super Man`，它為了我們做了非常厲害的事情，以至於我們根本察覺不到，只有通過學習它，我們才能深刻體會到它的精妙之處，甚至會被計算機科學家設計思想所震撼，有些思想實際上也是可以應用於我們工作開發中。

操作系統比較重要的四大模塊，分別是[內存管理](https://mp.weixin.qq.com/s/HJB_ATQFNqG82YBCRr97CA)、[進程管理](https://mp.weixin.qq.com/s/YXl6WZVzRKCfxzerJWyfrg)、[文件系統管理](https://mp.weixin.qq.com/s/qJdoXTv_XS_4ts9YuzMNIw)、[輸入輸出設備管理](https://mp.weixin.qq.com/s/04BkLtnPBmmx6CtdQPXiRA)。這是我學習操作系統的順序，也是我推薦給大家的學習順序，因為內存管理不僅是最重要、最難的模塊，也是和其他模塊關聯性最大的模塊，先把它搞定，後續的模塊學起來我認為會相對輕鬆一些。  

學習的過程中，你可能會遇到很多「虛擬」的概念，比如虛擬內存、虛擬文件系統，實際上它們的本質上都是一樣的，都是**向下屏蔽差異，向上提供統一的東西**，以方便我們程序員使用。

還有，你也遇到各種各樣的[調度算法](https://mp.weixin.qq.com/s/JWj6_BF9Xc84kQcyx6Nf_g)，在這裡你可以看到數據結構與算法的魅力，重要的是我們要理解為什麼要提出那麼多調度算法，你當然可以說是為了更快更有效率，但是因什麼問題而因此引入新算法的這個過程，更是我們重點學習的地方。

你也會開始明白進程與線程最大的區別在於上下文切換過程中，**線程不用切換虛擬內存**，因為同一個進程內的線程都是共享虛擬內存空間的，線程就單這一點不用切換，就相比進程上下文切換的性能開銷減少了很多。由於虛擬內存與物理內存的映射關係需要查詢頁表，頁表的查詢是很慢的過程，因此會把常用的地址映射關係緩存在 TLB 裡的，這樣便可以提高頁表的查詢速度，如果發生了進程切換，那 TLB 緩存的地址映射關係就會失效，緩存失效就意味著命中率降低，於是虛擬地址轉為物理地址這一過程就會很慢。


你也開始不會傻傻的認為 read 或 write 之後數據就直接寫到硬盤了，更不會覺得多次操作 read 或 write 方法性能會很低，因為你發現操作系統會有個「**磁盤高速緩衝區**」，它已經幫我們做了緩存的工作，它會預讀數據、緩存最近訪問的數據，以及使用 I/O 調度算法來合併和排隊磁盤調度 I/O，這些都是為了減少操作系統對磁盤的訪問頻率。

……

還有太多太多了，我在這裡就不贅述了，剩下的就交給你們在學習操作系統的途中去探索和發現了。


還有一點需要注意，學操作系統的時候，不要誤以為它是在說 Linux 操作系統，這也是我初學的時候犯的一個錯誤，操作系統是集合大多數操作系統實現的思想，跟實際具體實現的 Linux 操作系統多少都會有點差別，如果要想 Linux 操作系統的具體實現方式，可以選擇看 Linux 內核相關的資料，但是在這之前你先掌握了操作系統的基本知識，這樣學起來才能事半功倍。




## 入門系列

對於沒學過操作系統的小白，我建議學的時候，不要直接悶頭看書。相信我，你不用幾分鐘就會打退堂鼓，然後就把厚厚的書拿去墊顯示器了，從此再無後續，畢竟直接看書太特喵的枯燥了，當然不如用來墊顯示器玩遊戲來著香。

B 站關於操作系統課程資源很多，我在裡面也看了不同老師講的課程，覺得比較好的入門級課程是《**操作系統 - 清華大學**》，該課程由清華大學老師向勇和陳渝授課，雖然我們上不了清華大學，但是至少我們可以在網上選擇聽清華大學的課嘛。課程授課的順序，就如我前面推薦的學習順序：「內存管理 -> 進程管理 -> 文件系統管理 -> 輸入輸出設備管理」。

![《操作系統 - 清華大學》](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F-%E6%B8%85%E5%8D%8E%E5%A4%A7%E5%AD%A6.png)

> B 站清華大學操作系統視頻地址：https://www.bilibili.com/video/BV1js411b7vg?from=search&seid=2361361014547524697

該清華大學的視頻教學搭配的書應該是《**現代操作系統**》，你可以視頻和書籍兩者結合一起學，比如看完視頻的內存管理，然後就看書上對應的章節，這樣相比直接啃書相對會比較好。


![《現代操作系統》](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E7%8E%B0%E4%BB%A3%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F.png)

清華大學的操作系統視頻課講的比較精煉，涉及到的內容沒有那麼細，《**操作系統 - 哈工大**》李治軍老師授課的視頻課程相對就會比較細節，老師會用 Linux 內核代碼的角度帶你進一步理解操作系統，也會用生活小例子幫助你理解。

![《操作系統 - 哈工大》](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F-%E5%93%88%E5%B7%A5%E5%A4%A7.png)

> B 站哈工大操作系統視頻地址：https://www.bilibili.com/video/BV1d4411v7u7?from=search&seid=2361361014547524697


## 深入學習系列

《現代操作系統》這本書我感覺缺少比較多細節，說的還是比較籠統，而且書也好無聊。

推薦一個說的更細的操作系統書 —— 《**操作系統導論**》，這本書不僅告訴你 What，還會告訴你 How，書的內容都是循序漸進，層層遞進的，閱讀起來還是覺得挺有意思的，這本書的內存管理和併發這兩個部分說的很棒，這本書的中文版本我也沒找到資源，不過微信讀書可以免費看這本書。

![《操作系統導論》](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AF%BC%E8%AE%BA.png)

當然，少不了這本被稱為神書的《**深入理解計算機系統**》，豆瓣評分高達 `9.8` 分，這本書嚴格來說不算操作系統書，它是以程序員視角理解計算機系統，不只是涉及到操作系統，還涉及到了計算機組成、C 語言、彙編語言等知識，是一本綜合性比較強的書。

![《深入理解計算機系統》](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%B3%BB%E7%BB%9F.jpg)

它告訴我們計算機是如何設計和工作的，操作系統有哪些重點，它們的作用又是什麼，這本書的目標其實便是要講清楚原理，但並不會把某個話題挖掘地過於深入，過於細節。看看這本書後，我們就可以對計算機系統各組件的工作方式有了理性的認識。在一定程度上，其實它是在鍛鍊一種思維方式 —— 計算思維。


----

## 最後

文中推薦的書，小林都已經把電子書整理好給大家了，只需要在小林的公眾號後臺回覆「**我要學習**」，即可獲取百度網盤下載鏈接。

![](https://cdn.jsdelivr.net/gh/xiaolincoder/ImageHost2/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)