# 索引常見面試題

大家好，我是小林。

面試中，MySQL 索引相關的問題基本都是一系列問題，都是先從索引的基本原理，再到索引的使用場景，比如：

- 索引底層使用了什麼數據結構和算法？
- 為什麼 MySQL InnoDB  選擇 B+tree 作為索引的數據結構？
- 什麼時候適用索引？
- 什麼時候不需要創建索引？
- 什麼情況下索引會失效？
- 有什麼優化索引的方法？
- .....

今天就帶大家，夯實 MySQL 索引的知識點。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/索引提綱.png)

## 什麼是索引？

當你想查閱書中某個知識的內容，你會選擇一頁一頁的找呢？還是在書的目錄去找呢？

傻瓜都知道時間是寶貴的，當然是選擇在書的目錄去找，找到後再翻到對應的頁。書中的**目錄**，就是充當**索引**的角色，方便我們快速查找書中的內容，所以索引是以空間換時間的設計思想。

那換到數據庫中，索引的定義就是幫助存儲引擎快速獲取數據的一種數據結構，形象的說就是**索引是數據的目錄**。

所謂的存儲引擎，說白了就是如何存儲數據、如何為存儲的數據建立索引和如何更新、查詢數據等技術的實現方法。MySQL 存儲引擎有 MyISAM 、InnoDB、Memory，其中 InnoDB 是在 MySQL 5.5 之後成為默認的存儲引擎。

下圖是 MySQL 的結構圖，索引和數據就是位於存儲引擎中：

![](https://myblog-tuchuang.oss-cn-shanghai.aliyuncs.com/1623727651911_20170928110355446.png)

## 索引的分類

你知道索引有哪些嗎？大家肯定都能霹靂啪啦地說出聚簇索引、主鍵索引、二級索引、普通索引、唯一索引、hash索引、B+樹索引等等。

然後再問你，你能將這些索引分一下類嗎？可能大家就有點模糊了。其實，要對這些索引進行分類，要清楚這些索引的使用和實現方式，然後再針對有相同特點的索引歸為一類。

我們可以按照四個角度來分類索引。

- 按「數據結構」分類：**B+tree索引、Hash索引、Full-text索引**。
- 按「物理存儲」分類：**聚簇索引（主鍵索引）、二級索引（輔助索引）**。
- 按「字段特性」分類：**主鍵索引、唯一索引、普通索引、前綴索引**。
- 按「字段個數」分類：**單列索引、聯合索引**。

接下來，按照這些角度來說說各類索引的特點。

### 按數據結構分類

從數據結構的角度來看，MySQL 常見索引有 B+Tree 索引、HASH 索引、Full-Text 索引。

每一種存儲引擎支持的索引類型不一定相同，我在表中總結了 MySQL 常見的存儲引擎 InnoDB、MyISAM 和 Memory 分別支持的索引類型。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/索引分類.drawio.png)

InnoDB 是在 MySQL 5.5 之後成為默認的 MySQL 存儲引擎，B+Tree 索引類型也是 MySQL 存儲引擎採用最多的索引類型。

在創建表時，InnoDB 存儲引擎會根據不同的場景選擇不同的列作為索引：

- 如果有主鍵，默認會使用主鍵作為聚簇索引的索引鍵（key）；
- 如果沒有主鍵，就選擇第一個不包含 NULL 值的唯一列作為聚簇索引的索引鍵（key）；
- 在上面兩個都沒有的情況下，InnoDB 將自動生成一個隱式自增 id 列作為聚簇索引的索引鍵（key）；

其它索引都屬於輔助索引（Secondary Index），也被稱為二級索引或非聚簇索引。**創建的主鍵索引和二級索引默認使用的是 B+Tree 索引**。

為了讓大家理解 B+Tree 索引的存儲和查詢的過程，接下來我通過一個簡單例子，說明一下 B+Tree 索引在存儲數據中的具體實現。

先創建一張商品表，id 為主鍵，如下：

```sql
CREATE TABLE `product`  (
  `id` int(11) NOT NULL,
  `product_no` varchar(20)  DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `price` decimal(10, 2) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
```

商品表裡，有這些行數據：

![](https://img-blog.csdnimg.cn/824c43b801c64e81acb0a9b042d50311.png)

這些行數據，存儲在 B+Tree 索引時是長什麼樣子的？

B+Tree 是一種多叉樹，葉子節點才存放數據，非葉子節點只存放索引，而且每個節點裡的數據是**按主鍵順序存放**的。每一層父節點的索引值都會出現在下層子節點的索引值中，因此在葉子節點中，包括了所有的索引值信息，並且每一個葉子節點都指向下一個葉子節點，形成一個鏈表。

主鍵索引的 B+Tree 如圖所示：

![主鍵索引 B+Tree](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/btree.drawio.png)

#### 通過主鍵查詢商品數據的過程

比如，我們執行了下面這條查詢語句，這條語句使用了主鍵索引查詢 id 號為 5 的商品。查詢過程是這樣的，B+Tree 會自頂向下逐層進行查找：

- 將 5 與根節點的索引數據 (1，10，20) 比較，5 在 1 和 10 之間，所以根據 B+Tree的搜索邏輯，找到第二層的索引數據 (1，4，7)；
- 在第二層的索引數據  (1，4，7)中進行查找，因為 5 在 4 和 7 之間，所以找到第三層的索引數據（4，5，6）；
- 在葉子節點的索引數據（4，5，6）中進行查找，然後我們找到了索引值為 5 的行數據。

數據庫的索引和數據都是存儲在硬盤的，我們可以把讀取一個節點當作一次磁盤 I/O 操作。那麼上面的整個查詢過程一共經歷了 3 個節點，也就是進行了 3 次 I/O 操作。

B+Tree 存儲千萬級的數據只需要 3-4 層高度就可以滿足，這意味著從千萬級的表查詢目標數據最多需要 3-4 次磁盤 I/O，所以**B+Tree 相比於 B 樹和二叉樹來說，最大的優勢在於查詢效率很高，因為即使在數據量很大的情況，查詢一個數據的磁盤 I/O 依然維持在 3-4次。**

#### 通過二級索引查詢商品數據的過程

主鍵索引的 B+Tree  和二級索引的 B+Tree 區別如下：

- 主鍵索引的 B+Tree  的葉子節點存放的是實際數據，所有完整的用戶記錄都存放在主鍵索引的 B+Tree 的葉子節點裡；
- 二級索引的 B+Tree  的葉子節點存放的是主鍵值，而不是實際數據。

我這裡將前面的商品表中的 product_no （商品編碼）字段設置為二級索引，那麼二級索引的 B+Tree 如下圖，其中非葉子的 key 值是 product_no（圖中橙色部分），葉子節點存儲的數據是主鍵值（圖中綠色部分）。

![二級索引 B+Tree](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/二級索引btree.drawio.png)

如果我用 product_no 二級索引查詢商品，如下查詢語句：

```sql
select * from product where product_no = '0002';
```

會先檢二級索引中的 B+Tree 的索引值（商品編碼，product_no），找到對應的葉子節點，然後獲取主鍵值，然後再通過主鍵索引中的 B+Tree 樹查詢到對應的葉子節點，然後獲取整行數據。**這個過程叫「回表」，也就是說要查兩個 B+Tree 才能查到數據**。如下圖：

![回表](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/回表.drawio.png)

不過，當查詢的數據是能在二級索引的 B+Tree 的葉子節點裡查詢到，這時就不用再查主鍵索引查，比如下面這條查詢語句：

```sql
select id from product where product_no = '0002';
```

**這種在二級索引的 B+Tree 就能查詢到結果的過程就叫作「覆蓋索引」，也就是隻需要查一個 B+Tree 就能找到數據**。

#### 為什麼 MySQL InnoDB  選擇 B+tree 作為索引的數據結構？

前面已經講了 B+Tree 的索引原理，現在就來回答一下 B+Tree 相比於 B 樹、二叉樹或 Hash 索引結構的優勢在哪兒？

之前我也專門寫過一篇文章，想詳細瞭解的可以看這篇：「[女朋友問我：為什麼 MySQL 喜歡 B+ 樹？我笑著畫了 20 張圖](https://mp.weixin.qq.com/s/w1ZFOug8-Sa7ThtMnlaUtQ)」，這裡就簡單做個比對。

***1、B+Tree vs B Tree***

B+Tree 只在葉子節點存儲數據，而 B 樹 的非葉子節點也要存儲數據，所以 B+Tree 的單個節點的數據量更小，在相同的磁盤 I/O 次數下，就能查詢更多的節點。

另外，B+Tree 葉子節點採用的是雙鏈表連接，適合 MySQL 中常見的基於範圍的順序查找，而 B 樹無法做到這一點。

***2、B+Tree vs 二叉樹***

對於有 N 個葉子節點的 B+Tree，其搜索複雜度為`O(logdN)`，其中 d 表示節點允許的最大子節點個數為 d 個。

在實際的應用當中， d 值是大於100的，這樣就保證了，即使數據達到千萬級別時，B+Tree 的高度依然維持在 3~4 層左右，也就是說一次數據查詢操作只需要做 3~4 次的磁盤 I/O 操作就能查詢到目標數據。

而二叉樹的每個父節點的兒子節點個數只能是 2 個，意味著其搜索複雜度為 `O(logN)`，這已經比 B+Tree 高出不少，因此二叉樹檢索到目標數據所經歷的磁盤 I/O 次數要更多。

***3、B+Tree vs Hash***

Hash 在做等值查詢的時候效率賊快，搜索複雜度為 O(1)。

但是 Hash 表不適合做範圍查詢，它更適合做等值的查詢，這也是 B+Tree 索引要比 Hash 表索引有著更廣泛的適用場景的原因。

### 按物理存儲分類

從物理存儲的角度來看，索引分為聚簇索引（主鍵索引）、二級索引（輔助索引）。

這兩個區別在前面也提到了：

- 主鍵索引的 B+Tree  的葉子節點存放的是實際數據，所有完整的用戶記錄都存放在主鍵索引的 B+Tree 的葉子節點裡；
- 二級索引的 B+Tree  的葉子節點存放的是主鍵值，而不是實際數據。

所以，在查詢時使用了二級索引，如果查詢的數據能在二級索引裡查詢的到，那麼就不需要回表，這個過程就是覆蓋索引。如果查詢的數據不在二級索引裡，就會先檢索二級索引，找到對應的葉子節點，獲取到主鍵值後，然後再檢索主鍵索引，就能查詢到數據了，這個過程就是回表。

### 按字段特性分類

從字段特性的角度來看，索引分為主鍵索引、唯一索引、普通索引、前綴索引。

#### 主鍵索引

主鍵索引就是建立在主鍵字段上的索引，通常在創建表的時候一起創建，一張表最多隻有一個主鍵索引，索引列的值不允許有空值。

在創建表時，創建主鍵索引的方式如下：

```sql
CREATE TABLE table_name  (
  ....
  PRIMARY KEY (index_column_1) USING BTREE
);
```

#### 唯一索引

唯一索引建立在 UNIQUE 字段上的索引，一張表可以有多個唯一索引，索引列的值必須唯一，但是允許有空值。

在創建表時，創建唯一索引的方式如下：

```sql
CREATE TABLE table_name  (
  ....
  UNIQUE KEY(index_column_1,index_column_2,...) 
);
```

建表後，如果要創建唯一索引，可以使用這面這條命令：

```sql
CREATE UNIQUE INDEX index_name
ON table_name(index_column_1,index_column_2,...); 
```

#### 普通索引

普通索引就是建立在普通字段上的索引，既不要求字段為主鍵，也不要求字段為 UNIQUE。

在創建表時，創建普通索引的方式如下：

```sql
CREATE TABLE table_name  (
  ....
  INDEX(index_column_1,index_column_2,...) 
);
```

建表後，如果要創建普通索引，可以使用這面這條命令：

```sql
CREATE INDEX index_name
ON table_name(index_column_1,index_column_2,...); 
```

#### 前綴索引

前綴索引是指對字符類型字段的前幾個字符建立的索引，而不是在整個字段上建立的索引，前綴索引可以建立在字段類型為 char、 varchar、binary、varbinary 的列上。

使用前綴索引的目的是為了減少索引佔用的存儲空間，提升查詢效率。

在創建表時，創建前綴索引的方式如下：

```sql
CREATE TABLE table_name(
    column_list,
    INDEX(column_name(length))
); 
```

建表後，如果要創建前綴索引，可以使用這面這條命令：

```sql
CREATE INDEX index_name
ON table_name(column_name(length)); 
```

### 按字段個數分類

從字段個數的角度來看，索引分為單列索引、聯合索引（複合索引）。

- 建立在單列上的索引稱為單列索引，比如主鍵索引；
- 建立在多列上的索引稱為聯合索引；

#### 聯合索引

通過將多個字段組合成一個索引，該索引就被稱為聯合索引。

比如，將商品表中的 product_no 和 name 字段組合成聯合索引` (product_no, name)`，創建聯合索引的方式如下：

```sql
CREATE INDEX index_product_no_name ON product(product_no, name);
```

聯合索引` (product_no, name)` 的 B+Tree 示意圖如下：

![聯合索引](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/聯合索引.drawio.png)

可以看到，聯合索引的非葉子節點用兩個字段的值作為  B+Tree 的 key 值。當在聯合索引查詢數據時，先按 product_no 字段比較，在 product_no 相同的情況下再按 name 字段比較。

也就是說，聯合索引查詢的 B+Tree 是先按 product_no 進行排序，然後再 product_no 相同的情況再按 name 字段排序。

因此，使用聯合索引時，存在**最左匹配原則**，也就是按照最左優先的方式進行索引的匹配。在使用聯合索引進行查詢的時候，如果不遵循「最左匹配原則」，聯合索引會失效，這樣就無法利用到索引快速查詢的特性了。

比如，如果創建了一個 `(a, b, c)` 聯合索引，如果查詢條件是以下這幾種，就可以匹配上聯合索引：

- where a=1；
- where a=1 and b=2 and c=3；
- where a=1 and b=2；

需要注意的是，因為有查詢優化器，所以 a 字段在 where 子句的順序並不重要。

但是，如果查詢條件是以下這幾種，因為不符合最左匹配原則，所以就無法匹配上聯合索引，聯合索引就會失效:

- where b=2；
- where c=3；
- where b=2 and c=3；

上面這些查詢條件之所以會失效，是因為`(a, b, c)` 聯合索引，是先按 a 排序，在 a 相同的情況再按 b 排序，在 b 相同的情況再按 c 排序。所以，**b 和 c 是全局無序，局部相對有序的**，這樣在沒有遵循最左匹配原則的情況下，是無法利用到索引的。

我這裡舉聯合索引（a，b）的例子，該聯合索引的 B+ Tree 如下：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/聯合索引案例.drawio.png)

可以看到，a 是全局有序的（1, 2, 2, 3, 4, 5, 6, 7 ,8），而 b 是全局是無序的（12，7，8，2，3，8，10，5，2）。因此，直接執行`where b = 2`這種查詢條件沒有辦法利用聯合索引的，**利用索引的前提是索引裡的 key 是有序的**。

只有在 a 相同的情況才，b 才是有序的，比如 a 等於 2 的時候，b 的值為（7，8），這時就是有序的，這個有序狀態是局部的，因此，執行`where a = 2 and b = 7`是 a 和 b 字段能用到聯合索引的，也就是聯合索引生效了。

##### 聯合索引範圍查詢

聯合索引有一些特殊情況，**並不是查詢過程使用了聯合索引查詢，就代表聯合索引中的所有字段都用到了聯合索引進行索引查詢**，也就是可能存在部分字段用到聯合索引的 B+Tree，部分字段沒有用到聯合索引的 B+Tree 的情況。

這種特殊情況就發生在範圍查詢。聯合索引的最左匹配原則會一直向右匹配直到遇到「範圍查詢」就會停止匹配。**也就是範圍查詢的字段可以用到聯合索引，但是在範圍查詢字段的後面的字段無法用到聯合索引**。

範圍查詢有很多種，那到底是哪些範圍查詢會導致聯合索引的最左匹配原則會停止匹配呢？

接下來，舉例幾個範圍查例子。

> Q1: `select * from t_table where a > 1 and b = 2`，聯合索引（a, b）哪一個字段用到了聯合索引的 B+Tree？

由於聯合索引（二級索引）是先按照 a 字段的值排序的，所以符合 a > 1 條件的二級索引記錄肯定是相鄰，於是在進行索引掃描的時候，可以定位到符合 a > 1 條件的第一條記錄，然後沿著記錄所在的鏈表向後掃描，直到某條記錄不符合 a > 1 條件位置。所以 a 字段可以在聯合索引的 B+Tree 中進行索引查詢。

**但是在符合 a > 1  條件的二級索引記錄的範圍裡，b 字段的值是無序的**。比如前面圖的聯合索引的 B+ Tree 裡，下面這三條記錄的 a 字段的值都符合 a > 1  查詢條件，而 b 字段的值是無序的：

- a 字段值為 5 的記錄，該記錄的 b 字段值為 8；
- a 字段值為 6 的記錄，該記錄的 b 字段值為 10；
- a 字段值為 7 的記錄，該記錄的 b 字段值為 5；

因此，我們不能根據查詢條件 b = 2 來進一步減少需要掃描的記錄數量（b 字段無法利用聯合索引進行索引查詢的意思）。

所以在執行 Q1 這條查詢語句的時候，對應的掃描區間是 (2, + ∞)，形成該掃描區間的邊界條件是 a > 1，與 b = 2 無關。

因此，**Q1 這條查詢語句只有 a 字段用到了聯合索引進行索引查詢，而 b 字段並沒有使用到聯合索引**。

我們也可以在執行計劃中的 key_len 知道這一點，在使用聯合索引進行查詢的時候，通過 key_len 我們可以知道優化器具體使用了多少個字段的搜索條件來形成掃描區間的邊界條件。

舉例個例子 ，a 和 b 都是 int 類型且不為 NULL 的字段，那麼 Q1 這條查詢語句執行計劃如下，可以看到 key_len 為 4 字節（如果字段允許為 NULL，就在字段類型佔用的字節數上加 1，也就是 5 字節），說明只有 a 字段用到了聯合索引進行索引查詢，而且可以看到，即使 b 字段沒用到聯合索引，key 為 idx_a_b，說明  Q1 查詢語句使用了 idx_a_b 聯合索引。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q1.png)

通過 Q1 查詢語句我們可以知道，a 字段使用了 > 進行範圍查詢，聯合索引的最左匹配原則在遇到 a 字段的範圍查詢（ >）後就停止匹配了，因此 b 字段並沒有使用到聯合索引。

> Q2: `select * from t_table where a >= 1 and b = 2`，聯合索引（a, b）哪一個字段用到了聯合索引的 B+Tree？

Q2 和 Q1 的查詢語句很像，唯一的區別就是 a 字段的查詢條件「大於等於」。

由於聯合索引（二級索引）是先按照 a 字段的值排序的，所以符合 >= 1 條件的二級索引記錄肯定是相鄰，於是在進行索引掃描的時候，可以定位到符合 >= 1 條件的第一條記錄，然後沿著記錄所在的鏈表向後掃描，直到某條記錄不符合 a>= 1 條件位置。所以 a 字段可以在聯合索引的 B+Tree 中進行索引查詢。

雖然在符合 a>= 1  條件的二級索引記錄的範圍裡，b 字段的值是「無序」的，**但是對於符合 a = 1 的二級索引記錄的範圍裡，b 字段的值是「有序」的**（因為對於聯合索引，是先按照 a 字段的值排序，然後在 a 字段的值相同的情況下，再按照 b 字段的值進行排序）。

於是，在確定需要掃描的二級索引的範圍時，當二級索引記錄的 a 字段值為 1 時，可以通過 b = 2 條件減少需要掃描的二級索引記錄範圍（b 字段可以利用聯合索引進行索引查詢的意思）。也就是說，從符合 a = 1 and b = 2 條件的第一條記錄開始掃描，而不需要從第一個 a 字段值為 1 的記錄開始掃描。

所以，**Q2 這條查詢語句 a 和 b 字段都用到了聯合索引進行索引查詢**。

我們也可以在執行計劃中的 key_len 知道這一點。執行計劃如下，可以看到 key_len 為 8 字節，說明優化器使用了 2 個字段的查詢條件來形成掃描區間的邊界條件，也就是  a 和 b 字段都用到了聯合索引進行索引查詢。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q2.png)

通過 Q2 查詢語句我們可以知道，雖然 a 字段使用了 >= 進行範圍查詢，但是聯合索引的最左匹配原則並沒有在遇到 a 字段的範圍查詢（ >=）後就停止匹配了，b 字段還是可以用到了聯合索引的。

> Q3: ` SELECT * FROM t_table WHERE a BETWEEN 2 AND 8 AND b = 2`，聯合索引（a, b）哪一個字段用到了聯合索引的 B+Tree？

Q3 查詢條件中 `a BETWEEN 2 AND 8` 的意思是查詢 a 字段的值在 2 和 8 之間的記錄。不同的數據庫對 BETWEEN ... AND 處理方式是有差異的。在 MySQL 中，BETWEEN 包含了 value1 和 value2 邊界值，類似於 \>= and =<。而有的數據庫則不包含 value1 和 value2 邊界值（類似於 > and <）。

這裡我們只討論 MySQL。由於 MySQL 的 BETWEEN 包含 value1 和 value2 邊界值，所以類似於 Q2 查詢語句，因此 **Q3 這條查詢語句 a 和 b 字段都用到了聯合索引進行索引查詢**。

我們也可以在執行計劃中的 key_len 知道這一點。執行計劃如下，可以看到 key_len 為 8 字節，說明優化器使用了 2 個字段的查詢條件來形成掃描區間的邊界條件，也就是  a 和 b 字段都用到了聯合索引進行索引查詢。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q3.png)

通過 Q3 查詢語句我們可以知道，雖然 a 字段使用了 BETWEEN 進行範圍查詢，但是聯合索引的最左匹配原則並沒有在遇到 a 字段的範圍查詢（ BETWEEN）後就停止匹配了，b 字段還是可以用到了聯合索引的。

> Q4: ` SELECT * FROM t_user WHERE name like 'j%' and age = 22`，聯合索引（name, age）哪一個字段用到了聯合索引的 B+Tree？

由於聯合索引（二級索引）是先按照 name 字段的值排序的，所以前綴為 ‘j’ 的 name 字段的二級索引記錄都是相鄰的， 於是在進行索引掃描的時候，可以定位到符合前綴為 ‘j’ 的 name 字段的第一條記錄，然後沿著記錄所在的鏈表向後掃描，直到某條記錄的 name 前綴不為 ‘j’  為止。

所以 a 字段可以在聯合索引的 B+Tree 中進行索引查詢，形成的掃描區間是['j','k')。注意， j 是閉區間。如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q4-1.drawio.png)

雖然在符合前綴為 ‘j’ 的 name 字段的二級索引記錄的範圍裡，age 字段的值是「無序」的，**但是對於符合 name = j 的二級索引記錄的範圍裡，age字段的值是「有序」的**（因為對於聯合索引，是先按照 name 字段的值排序，然後在 name 字段的值相同的情況下，再按照 age 字段的值進行排序）。

於是，在確定需要掃描的二級索引的範圍時，當二級索引記錄的 name 字段值為 ‘j’ 時，可以通過 age = 22 條件減少需要掃描的二級索引記錄範圍（age 字段可以利用聯合索引進行索引查詢的意思）。也就是說，從符合 `name = 'j' and age = 22` 條件的第一條記錄時開始掃描，而不需要從第一個 name 為 j 的記錄開始掃描 。如下圖的右邊：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q4-2.drawio.png)

所以，**Q4 這條查詢語句 a 和 b 字段都用到了聯合索引進行索引查詢**。

我們也可以在執行計劃中的 key_len 知道這一點。本次例子中：

- name 字段的類型是 varchar(30) 且不為 NULL，數據庫表使用了 utf8mb4 字符集，一個字符集為 utf8mb4 的字符是 4 個字節，因此 name 字段的實際數據最多佔用的存儲空間長度是 120 字節（30 x 4），然後因為 name 是變長類型的字段，需要再加 2，也就是 name 的 key_len 為 122。

- age 字段的類型是 int 且不為 NULL，key_len 為 4。

Q4 查詢語句的執行計劃如下，可以看到 key_len 為 126 字節，name 的 key_len 為 122，age 的 key_len 為 4，說明優化器使用了 2 個字段的查詢條件來形成掃描區間的邊界條件，也就是  name 和 age 字段都用到了聯合索引進行索引查詢。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/q4-執行計劃.png)

通過 Q4 查詢語句我們可以知道，雖然 name 字段使用了 like 前綴匹配進行範圍查詢，但是聯合索引的最左匹配原則並沒有在遇到 name 字段的範圍查詢（ like 'j%'）後就停止匹配了，age 字段還是可以用到了聯合索引的。

綜上所示，**聯合索引的最左匹配原則，在遇到範圍查詢（如 \>、<）的時候，就會停止匹配，也就是範圍查詢的字段可以用到聯合索引，但是在範圍查詢字段的後面的字段無法用到聯合索引。注意，對於 >=、<=、BETWEEN、like 前綴匹配的範圍查詢，並不會停止匹配，前面我也用了四個例子說明瞭**。

##### 索引下推

現在我們知道，對於聯合索引（a, b），在執行 `select * from table where a > 1 and b = 2` 語句的時候，只有 a 字段能用到索引，那在聯合索引的 B+Tree 找到第一個滿足條件的主鍵值（ID 為 2）後，還需要判斷其他條件是否滿足（看 b 是否等於 2），那是在聯合索引裡判斷？還是回主鍵索引去判斷呢？

- 在 MySQL 5.6 之前，只能從 ID2 （主鍵值）開始一個個回表，到「主鍵索引」上找出數據行，再對比 b 字段值。

- 而 MySQL 5.6 引入的**索引下推優化**（index condition pushdown)， **可以在聯合索引遍歷過程中，對聯合索引中包含的字段先做判斷，直接過濾掉不滿足條件的記錄，減少回表次數**。

當你的查詢語句的執行計劃裡，出現了  Extra 為 `Using index condition`，那麼說明使用了索引下推的優化。

##### 索引區分度

另外，建立聯合索引時的字段順序，對索引效率也有很大影響。越靠前的字段被用於索引過濾的概率越高，實際開發工作中**建立聯合索引時，要把區分度大的字段排在前面，這樣區分度大的字段越有可能被更多的 SQL 使用到**。

區分度就是某個字段 column 不同值的個數「除以」表的總行數，計算公式如下：

![區分度計算公式](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/區分度.png)

比如，性別的區分度就很小，不適合建立索引或不適合排在聯合索引列的靠前的位置，而 UUID 這類字段就比較適合做索引或排在聯合索引列的靠前的位置。

因為如果索引的區分度很小，假設字段的值分佈均勻，那麼無論搜索哪個值都可能得到一半的數據。在這些情況下，還不如不要索引，因為 MySQL 還有一個查詢優化器，查詢優化器發現某個值出現在表的數據行中的百分比（慣用的百分比界線是"30%"）很高的時候，它一般會忽略索引，進行全表掃描。

##### 聯合索引進行排序

這裡出一個題目，針對針對下面這條 SQL，你怎麼通過索引來提高查詢效率呢？

```sql
select * from order where status = 1 order by create_time asc
```

有的同學會認為，單獨給 status 建立一個索引就可以了。

但是更好的方式給 status 和 create_time 列建立一個聯合索引，因為這樣可以避免 MySQL 數據庫發生文件排序。

因為在查詢時，如果只用到 status 的索引，但是這條語句還要對 create_time 排序，這時就要用文件排序 filesort，也就是在 SQL 執行計劃中，Extra 列會出現 Using filesort。

所以，要利用索引的有序性，在 status 和 create_time 列建立聯合索引，這樣根據 status 篩選後的數據就是按照 create_time 排好序的，避免在文件排序，提高了查詢效率。

## 什麼時候需要 / 不需要創建索引？

索引最大的好處是提高查詢速度，但是索引也是有缺點的，比如：

- 需要佔用物理空間，數量越大，佔用空間越大；
- 創建索引和維護索引要耗費時間，這種時間隨著數據量的增加而增大；
- 會降低表的增刪改的效率，因為每次增刪改索引，B+ 樹為了維護索引有序性，都需要進行動態維護。

所以，索引不是萬能鑰匙，它也是根據場景來使用的。

#### 什麼時候適用索引？

- 字段有唯一性限制的，比如商品編碼；
- 經常用於 `WHERE` 查詢條件的字段，這樣能夠提高整個表的查詢速度，如果查詢條件不是一個字段，可以建立聯合索引。
- 經常用於 `GROUP BY` 和 `ORDER BY` 的字段，這樣在查詢的時候就不需要再去做一次排序了，因為我們都已經知道了建立索引之後在 B+Tree 中的記錄都是排序好的。

#### 什麼時候不需要創建索引？

- `WHERE` 條件，`GROUP BY`，`ORDER BY` 裡用不到的字段，索引的價值是快速定位，如果起不到定位的字段通常是不需要創建索引的，因為索引是會佔用物理空間的。
- 字段中存在大量重複數據，不需要創建索引，比如性別字段，只有男女，如果數據庫表中，男女的記錄分佈均勻，那麼無論搜索哪個值都可能得到一半的數據。在這些情況下，還不如不要索引，因為 MySQL 還有一個查詢優化器，查詢優化器發現某個值出現在表的數據行中的百分比很高的時候，它一般會忽略索引，進行全表掃描。
- 表數據太少的時候，不需要創建索引；
- 經常更新的字段不用創建索引，比如不要對電商項目的用戶餘額建立索引，因為索引字段頻繁修改，由於要維護 B+Tree的有序性，那麼就需要頻繁的重建索引，這個過程是會影響數據庫性能的。

## 有什麼優化索引的方法？

這裡說一下幾種常見優化索引的方法：

- 前綴索引優化；
- 覆蓋索引優化；
- 主鍵索引最好是自增的；
- 防止索引失效；

### 前綴索引優化

前綴索引顧名思義就是使用某個字段中字符串的前幾個字符建立索引，那我們為什麼需要使用前綴來建立索引呢？

使用前綴索引是為了減小索引字段大小，可以增加一個索引頁中存儲的索引值，有效提高索引的查詢速度。在一些大字符串的字段作為索引時，使用前綴索引可以幫助我們減小索引項的大小。

不過，前綴索引有一定的侷限性，例如：

- order by 就無法使用前綴索引；
- 無法把前綴索引用作覆蓋索引；

### 覆蓋索引優化

覆蓋索引是指 SQL 中 query 的所有字段，在索引 B+Tree  的葉子節點上都能找得到的那些索引，從二級索引中查詢得到記錄，而不需要通過聚簇索引查詢獲得，可以避免回表的操作。

假設我們只需要查詢商品的名稱、價格，有什麼方式可以避免回表呢？

我們可以建立一個聯合索引，即「商品ID、名稱、價格」作為一個聯合索引。如果索引中存在這些數據，查詢將不會再次檢索主鍵索引，從而避免回表。

所以，使用覆蓋索引的好處就是，不需要查詢出包含整行記錄的所有信息，也就減少了大量的 I/O 操作。

### 主鍵索引最好是自增的

我們在建表的時候，都會默認將主鍵索引設置為自增的，具體為什麼要這樣做呢？又什麼好處？

InnoDB 創建主鍵索引默認為聚簇索引，數據被存放在了 B+Tree 的葉子節點上。也就是說，同一個葉子節點內的各個數據是按主鍵順序存放的，因此，每當有一條新的數據插入時，數據庫會根據主鍵將其插入到對應的葉子節點中。

**如果我們使用自增主鍵**，那麼每次插入的新數據就會按順序添加到當前索引節點的位置，不需要移動已有的數據，當頁面寫滿，就會自動開闢一個新頁面。因為每次**插入一條新記錄，都是追加操作，不需要重新移動數據**，因此這種插入數據的方法效率非常高。

**如果我們使用非自增主鍵**，由於每次插入主鍵的索引值都是隨機的，因此每次插入新的數據時，就可能會插入到現有數據頁中間的某個位置，這將不得不移動其它數據來滿足新數據的插入，甚至需要從一個頁面複製數據到另外一個頁面，我們通常將這種情況稱為**頁分裂**。**頁分裂還有可能會造成大量的內存碎片，導致索引結構不緊湊，從而影響查詢效率**。

舉個例子，假設某個數據頁中的數據是1、3、5、9，且數據頁滿了，現在準備插入一個數據7，則需要把數據頁分割為兩個數據頁：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/頁分裂.png)

出現頁分裂時，需要將一個頁的記錄移動到另外一個頁，性能會受到影響，同時頁空間的利用率下降，造成存儲空間的浪費。

而如果記錄是順序插入的，例如插入數據11，則只需開闢新的數據頁，也就不會發生頁分裂：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/開闢新頁.png)

因此，在使用 InnoDB 存儲引擎時，如果沒有特別的業務需求，建議使用自增字段作為主鍵。

另外，主鍵字段的長度不要太大，因為**主鍵字段長度越小，意味著二級索引的葉子節點越小（二級索引的葉子節點存放的數據是主鍵值），這樣二級索引佔用的空間也就越小**。

### 索引最好設置為 NOT NULL

為了更好的利用索引，索引列要設置為 NOT NULL 約束。有兩個原因：

- 第一原因：索引列存在 NULL 就會導致優化器在做索引選擇的時候更加複雜，更加難以優化，因為可為 NULL 的列會使索引、索引統計和值比較都更復雜，比如進行索引統計時，count 會省略值為NULL 的行。

- 第二個原因：NULL 值是一個沒意義的值，但是它會佔用物理空間，所以會帶來的存儲空間的問題，會導致更多的存儲空間佔用，因為 InnoDB 默認行存儲格式`COMPACT`，會用 1 字節空間存儲 NULL 值列表，如下圖的黃色部分：

  ![](https://tva1.sinaimg.cn/large/008eGmZEgy1gp6pbo6xd7j30v602u3yq.jpg)

### 防止索引失效

用上了索引並不意味著查詢的時候會使用到索引，所以我們心裡要清楚有哪些情況會導致索引失效，從而避免寫出索引失效的查詢語句，否則這樣的查詢效率是很低的。

我之前寫過索引失效的文章，想詳細瞭解的可以去看這篇文章：[誰還沒碰過索引失效呢?](https://mp.weixin.qq.com/s/lEx6iRRP3MbwJ82Xwp675w)

這裡簡單說一下，發生索引失效的情況：

- 當我們使用左或者左右模糊匹配的時候，也就是 `like %xx` 或者 `like %xx%`這兩種方式都會造成索引失效；
- 當我們在查詢條件中對索引列做了計算、函數、類型轉換操作，這些情況下都會造成索引失效；
- 聯合索引要能正確使用需要遵循最左匹配原則，也就是按照最左優先的方式進行索引的匹配，否則就會導致索引失效。
- 在 WHERE 子句中，如果在 OR 前的條件列是索引列，而在 OR 後的條件列不是索引列，那麼索引會失效。

我上面說的是常見的索引失效場景，實際過程中，可能會出現其他的索引失效場景，這時我們就需要查看執行計劃，通過執行計劃顯示的數據判斷查詢語句是否使用了索引。

如下圖，就是一個沒有使用索引，並且是一個全表掃描的查詢語句。

![](https://img-blog.csdnimg.cn/img_convert/798ab1331d1d6dff026e262e788f1a28.png)

對於執行計劃，參數有：

- possible_keys 字段表示可能用到的索引；
- key 字段表示實際用的索引，如果這一項為 NULL，說明沒有使用索引；
- key_len 表示索引的長度；
- rows 表示掃描的數據行數。
- type 表示數據掃描類型，我們需要重點看這個。

type 字段就是描述了找到所需數據時使用的掃描方式是什麼，常見掃描類型的**執行效率從低到高的順序為**：

- All（全表掃描）；
- index（全索引掃描）；
- range（索引範圍掃描）；
- ref（非唯一索引掃描）；
- eq_ref（唯一索引掃描）；
- const（結果只有一條的主鍵或唯一索引掃描）。

在這些情況裡，all 是最壞的情況，因為採用了全表掃描的方式。index 和 all 差不多，只不過 index 對索引表進行全掃描，這樣做的好處是不再需要對數據進行排序，但是開銷依然很大。所以，要儘量避免全表掃描和全索引掃描。

range 表示採用了索引範圍掃描，一般在 where 子句中使用 < 、>、in、between 等關鍵詞，只檢索給定範圍的行，屬於範圍查找。**從這一級別開始，索引的作用會越來越明顯，因此我們需要儘量讓 SQL 查詢可以使用到 range 這一級別及以上的 type 訪問方式**。

ref 類型表示採用了非唯一索引，或者是唯一索引的非唯一性前綴，返回數據返回可能是多條。因為雖然使用了索引，但該索引列的值並不唯一，有重複。這樣即使使用索引快速查找到了第一條數據，仍然不能停止，要進行目標值附近的小範圍掃描。但它的好處是它並不需要掃全表，因為索引是有序的，即便有重複值，也是在一個非常小的範圍內掃描。

eq_ref 類型是使用主鍵或唯一索引時產生的訪問方式，通常使用在多表聯查中。比如，對兩張表進行聯查，關聯條件是兩張表的 user_id 相等，且 user_id 是唯一索引，那麼使用 EXPLAIN 進行執行計劃查看的時候，type 就會顯示 eq_ref。

const 類型表示使用了主鍵或者唯一索引與常量值進行比較，比如 select name  from product where id=1。

需要說明的是 const 類型和 eq_ref 都使用了主鍵或唯一索引，不過這兩個類型有所區別，**const 是與常量進行比較，查詢效率會更快，而 eq_ref 通常用於多表聯查中**。

> 除了關注 type，我們也要關注 extra 顯示的結果。

這裡說幾個重要的參考指標：

- Using filesort ：當查詢語句中包含 group by 操作，而且無法利用索引完成排序操作的時候， 這時不得不選擇相應的排序算法進行，甚至可能會通過文件排序，效率是很低的，所以要避免這種問題的出現。
- Using temporary：使了用臨時表保存中間結果，MySQL 在對查詢結果排序時使用臨時表，常見於排序 order by 和分組查詢 group by。效率低，要避免這種問題的出現。
- Using index：所需數據只需在索引即可全部獲得，不須要再到表中取數據，也就是使用了覆蓋索引，避免了回表操作，效率不錯。

## 總結

這次主要介紹了索引的原理、分類和使用。我把重點總結在了下面這個表格

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/mysql/索引/索引總結.drawio.png)

完！

---

最新的圖解文章都在公眾號首發，別忘記關注哦！！如果你想加入百人技術交流群，掃碼下方二維碼回覆「加群」。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/%E5%85%B6%E4%BB%96/%E5%85%AC%E4%BC%97%E5%8F%B7%E4%BB%8B%E7%BB%8D.png)