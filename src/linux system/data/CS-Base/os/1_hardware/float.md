# 2.7  為什麼 0.1 + 0.2 不等於 0.3 ？

我們來思考幾個問題：

- 為什麼負數要用補碼錶示？
- 十進制小數怎麼轉成二進制？
- 計算機是怎麼存小數的？
- 0.1 + 0.2 == 0.3 嗎？
- ...

別看這些問題都看似簡單，但是其實還是有點東西的這些問題。

---

## 為什麼負數要用補碼錶示？

十進制轉換二進制的方法相信大家都熟能生巧了，如果你說你還不知道，我覺得你還是太謙虛，可能你只是忘記了，即使你真的忘記了，不怕，貼心的小林在和你一起回憶一下。

 十進制數轉二進制採用的是**除 2 取餘法**，比如數字 8 轉二進制的過程如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/十進制轉二進制.png)


接著，我們看看「整數類型」的數字在計算機的存儲方式，這其實很簡單，也很直觀，就是將十進制的數字轉換成二進制即可。

我們以 `int` 類型的數字作為例子，int 類型是 `32` 位的，其中**最高位是作為「符號標誌位」**，正數的符號位是 `0`，負數的符號位是 `1`，**剩餘的 31 位則表示二進制數據**。

那麼，對於 int 類型的數字 1 的二進制數表示如下：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/int1.png)

而負數就比較特殊了點，負數在計算機中是以「補碼」表示的，**所謂的補碼就是把正數的二進制全部取反再加 1**，比如 -1 的二進制是把數字 1 的二進製取反後再加 1，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/反碼.png)


不知道你有沒有想過，為什麼計算機要用補碼的方式來表示負數？在回答這個問題前，我們假設不用補碼的方式來表示負數，而只是把最高位的符號標誌位變為 1 表示負數，如下圖過程：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/非反碼.png)


如果採用這種方式來表示負數的二進制的話，試想一下 `-2 + 1` 的運算過程，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/非反碼運算.png)


按道理，`-2 + 1 = -1`，但是上面的運算過程中得到結果卻是 `-3`，所可以發現，這種負數的表示方式是不能用常規的加法來計算了，就需要特殊處理，要先判斷數字是否為負數，如果是負數就要把加法操作變成減法操作才可以得到正確對結果。


到這裡，我們就可以回答前面提到的「負數為什麼要用補碼方式來表示」的問題了。

如果負數不是使用補碼的方式表示，則在做基本對加減法運算的時候，**還需要多一步操作來判斷是否為負數，如果為負數，還得把加法反轉成減法，或者把減法反轉成加法**，這就非常不好了，畢竟加減法運算在計算機裡是很常使用的，所以為了性能考慮，應該要儘量簡化這個運算過程。

**而用了補碼的表示方式，對於負數的加減法操作，實際上是和正數加減法操作一樣的**。你可以看到下圖，用補碼錶示的負數在運算 `-2 + 1` 過程的時候，其結果是正確的：



![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/補碼運算過程.png)

---

## 十進制小數與二進制的轉換

好了，整數十進制轉二進制我們知道了，接下來看看小數是怎麼轉二進制的，小數部分的轉換不同於整數部分，它採用的是**乘 2 取整法**，將十進制中的小數部分乘以 2 作為二進制的一位，然後繼續取小數部分乘以 2 作為下一位，直到不存在小數為止。


話不多說，我們就以 `8.625` 轉二進製作為例子，直接上圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/十進制小數轉二進制.png)


最後把「整數部分 + 小數部分」結合在一起後，其結果就是 `1000.101`。

但是，並不是所有小數都可以用二進製表示，前面提到的 0.625 小數是一個特例，剛好通過乘 2 取整法的方式完整的轉換成二進制。

如果我們用相同的方式，來把 `0.1` 轉換成二進制，過程如下：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/無限小數.png)

可以發現，`0.1` 的二進製表示是無限循環的。

**由於計算機的資源是有限的，所以是沒辦法用二進制精確的表示 0.1，只能用「近似值」來表示，就是在有限的精度情況下，最大化接近 0.1 的二進制數，於是就會造成精度缺失的情況**。

對於二進制小數轉十進制時，需要注意一點，小數點後面的指數冪是**負數**。

比如，二進制 `0.1` 轉成十進制就是 `2^(-1)`，也就是十進制 `0.5`，二進制 `0.01` 轉成十進制就是 `2^-2`，也就是十進制 `0.25`，以此類推。

舉個例子，二進制 `1010.101` 轉十進制的過程，如下圖：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/小數轉二進制2.png)


---

## 計算機是怎麼存小數的？

`1000.101` 這種二進制小數是「定點數」形式，代表著小數點是定死的，不能移動，如果你移動了它的小數點，這個數就變了， 就不再是它原來的值了。

然而，計算機並不是這樣存儲的小數的，計算機存儲小數的採用的是**浮點數**，名字裡的「浮點」表示小數點是可以浮動的。

比如 `1000.101` 這個二進制數，可以表示成 `1.000101 x 2^3`，類似於數學上的科學記數法。

既然提到了科學計數法，我再幫大家複習一下。

比如有個很大的十進制數 1230000，我們可以也可以表示成 `1.23 x 10^6`，這種方式就稱為科學記數法。

該方法在小數點左邊只有一個數字，而且把這種整數部分沒有前導 0 的數字稱為**規格化**，比如 `1.0 x 10^(-9)` 是規格化的科學記數法，而 `0.1 x 10^(-9)` 和 `10.0 x 10^(-9)` 就不是了。

因此，如果二進制要用到科學記數法，同時要規範化，那麼不僅要保證基數為 2，還要保證小數點左側只有 1 位，而且必須為 1。

所以通常將 `1000.101` 這種二進制數，規格化表示成 `1.000101 x 2^3`，其中，最為關鍵的是 000101 和 3 這兩個東西，它就可以包含了這個二進制小數的所有信息：

- `000101` 稱為**尾數**，即小數點後面的數字；
- `3` 稱為**指數**，指定了小數點在數據中的位置；



現在絕大多數計算機使用的浮點數，一般採用的是 IEEE 制定的國際標準，這種標準形式如下圖：


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/IEEE標準.png)


這三個重要部分的意義如下：

- *符號位*：表示數字是正數還是負數，為 0 表示正數，為 1 表示負數；
- *指數位*：指定了小數點在數據中的位置，指數可以是負數，也可以是正數，**指數位的長度越長則數值的表達範圍就越大**；
- *尾數位*：小數點右側的數字，也就是小數部分，比如二進制 1.0011 x 2^(-2)，尾數部分就是 0011，而且**尾數的長度決定了這個數的精度**，因此如果要表示精度更高的小數，則就要提高尾數位的長度；



用 `32` 位來表示的浮點數，則稱為**單精度浮點數**，也就是我們編程語言中的 `float` 變量，而用 `64` 位來表示的浮點數，稱為**雙精度浮點數**，也就是 `double`  變量，它們的結構如下：


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/float.png)


可以看到：

- double 的尾數部分是 52 位，float 的尾數部分是 23 位，由於同時都帶有一個固定隱含位（這個後面會說），所以 double 有 53 個二進制有效位，float 有 24 個二進制有效位，所以所以它們的精度在十進制中分別是 `log10(2^53)` 約等於 `15.95` 和 `log10(2^24)` 約等於 `7.22`  位，因此 double 的有效數字是 `15~16` 位，float 的有效數字是 `7~8` 位，這些有效位是包含整數部分和小數部分；
- double 的指數部分是 11 位，而 float 的指數位是 8 位，意味著 double 相比 float 能表示更大的數值範圍；


那二進制小數，是如何轉換成二進制浮點數的呢？

我們就以 `10.625` 作為例子，看看這個數字在 float 裡是如何存儲的。

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/float存儲.png)

首先，我們計算出 10.625 的二進制小數為 1010.101。

然後**把小數點，移動到第一個有效數字後面**，即將 1010.101 右移 `3` 位成 `1.010101`，右移 3 位就代表 +3，左移 3 位就是 -3。

**float 中的「指數位」就跟這裡移動的位數有關係，把移動的位數再加上「偏移量」，float 的話偏移量是 127，相加後就是指數位的值了**，即指數位這 8 位存的是 `10000010`（十進制 130），因此你可以認為「指數位」相當於指明瞭小數點在數據中的位置。

`1.010101` 這個數的**小數點右側的數字就是 float 裡的「尾數位」**，由於尾數位是 23 位，則後面要補充 0，所以最終尾數位存儲的數字是 `01010100000000000000000`。


在算指數的時候，你可能會有疑問為什麼要加上偏移量呢？

前面也提到，指數可能是正數，也可能是負數，即指數是有符號的整數，而有符號整數的計算是比無符號整數麻煩的，所以為了減少不必要的麻煩，在實際存儲指數的時候，需要把指數轉換成**無符號整數**。

float 的指數部分是 8 位，IEEE 標準規定單精度浮點的指數取值範圍是 `-126 ~ +127`，於是為了把指數轉換成無符號整數，就要加個**偏移量**，比如 float 的指數偏移量是 `127`，這樣指數就不會出現負數了。

比如，指數如果是 8，則實際存儲的指數是 8 + 127（偏移量）= 135，即把 135 轉換為二進制之後再存儲，而當我們需要計算實際的十進制數的時候，再把指數減去「偏移量」即可。


細心的朋友肯定發現，移動後的小數點左側的有效位（即 1）消失了，它並沒有存儲到 float 裡。

這是因為 IEEE 標準規定，二進制浮點數的小數點左側只能有 1 位，並且還只能是 1，**既然這一位永遠都是 1，那就可以不用存起來了**。

於是就讓 23 位尾數只存儲小數部分，然後在計算時會**自動把這個 1 加上，這樣就可以節約 1 位的空間，尾數就能多存一位小數，相應的精度就更高了一點**。

那麼，對於我們在從 float 的二進制浮點數轉換成十進制時，要考慮到這個隱含的 1，轉換公式如下：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/float公式.png)

舉個例子，我們把下圖這個 float 的數據轉換成十進制，過程如下：


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/float轉二進制例子.png)

---

## 0.1 + 0.2 == 0.3 ?

前面提到過，並不是所有小數都可以用「完整」的二進制來表示的，比如十進制 0.1 在轉換成二進制小數的時候，是一串無限循環的二進制數，計算機是無法表達無限循環的二進制數的，畢竟計算機的資源是有限。

因此，計算機只能用「近似值」來表示該二進制，那麼意味著計算機存放的小數可能不是一個真實值。

現在基本都是用  IEEE 754 規範的「單精度浮點類型」或「雙精度浮點類型」來存儲小數的，根據精度的不同，近似值也會不同。

那計算機是存儲 0.1 是一個怎麼樣的二進制浮點數呢？

偷個懶，我就不自己手動算了，可以使用 binaryconvert 這個工具，將十進制 0.1 小數轉換成 float 浮點數：


![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/0.1工具.png)


可以看到，8 位指數部分是 `01111011`，23 位的尾數部分是 `10011001100110011001101`，可以看到尾數部分是 `0011` 是一直循環的，只不過尾數是有長度限制的，所以只會顯示一部分，所以是一個近似值，精度十分有限。


接下來，我們看看 0.2 的 float 浮點數：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/0.2工具.png)


可以看到，8 位指數部分是 `01111100`，稍微和 0.1 的指數不同，23 位的尾數部分是 `10011001100110011001101` 和 0.1 的尾數部分是相同的，也是一個近似值。



 0.1 的二進制浮點數轉換成十進制的結果是 `0.100000001490116119384765625`：

  ![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/0.1浮點數轉二進制小數.png)

 0.2 的二進制浮點數轉換成十進制的結果是 `0.20000000298023223876953125`：

 ![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/0.2浮點數轉換.png)

 這兩個結果相加就是 `0.300000004470348358154296875`：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/0.1%2B0.2.png)


所以，你會看到**在計算機中 0.1 + 0.2 並不等於完整的 0.3**。

這主要是**因為有的小數無法可以用「完整」的二進制來表示，所以計算機裡只能採用近似數的方式來保存，那兩個近似數相加，得到的必然也是一個近似數**。


我們在 JavaScript 裡執行 0.1 + 0.2，你會得到下面這個結果：

![](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost3@main/操作系統/浮點/js0.1%2B0.2.png)

結果和我們前面推到的類似，因為 JavaScript 對於數字都是使用 IEEE 754 標準下的雙精度浮點類型來存儲的。

而我們二進制只能精準表達 2 除盡的數字 1/2, 1/4, 1/8，但是對於 0.1(1/10) 和 0.2(1/5)，在二進制中都無法精準表示時，需要根據精度舍入。

我們人類熟悉的十進制運算系統，可以精準表達 2 和 5 除盡的數字，例如 1/2, 1/4, 1/5(0.2), 1/8, 1/10(0.1)。

當然，十進制也有無法除盡的地方，例如 1/3, 1/7，也需要根據精度舍入。

---

## 總結

最後，再來回答開頭的問題。

> 為什麼負數要用補碼錶示？

負數之所以用補碼的方式來表示，主要是為了統一和正數的加減法操作一樣，畢竟數字的加減法是很常用的一個操作，就不要搞特殊化，儘量以統一的方式來運算。

> 十進制小數怎麼轉成二進制？

十進制整數轉二進制使用的是「除 2 取餘法」，十進制小數使用的是「乘 2 取整法」。

> 計算機是怎麼存小數的？

計算機是以浮點數的形式存儲小數的，大多數計算機都是 IEEE 754 標準定義的浮點數格式，包含三個部分：

- 符號位：表示數字是正數還是負數，為 0 表示正數，為 1 表示負數；
- 指數位：指定了小數點在數據中的位置，指數可以是負數，也可以是正數，指數位的長度越長則數值的表達範圍就越大；
- 尾數位：小數點右側的數字，也就是小數部分，比如二進制 1.0011 x 2^(-2)，尾數部分就是 0011，而且尾數的長度決定了這個數的精度，因此如果要表示精度更高的小數，則就要提高尾數位的長度；

用 32 位來表示的浮點數，則稱為單精度浮點數，也就是我們編程語言中的 float 變量，而用 64 位來表示的浮點數，稱為雙精度浮點數，也就是 double 變量。

> 0.1 + 0.2 == 0.3 嗎？

不是的，0.1 和 0.2 這兩個數字用二進製表達會是一個一直循環的二進制數，比如 0.1 的二進製表示為 0.0 0011 0011 0011… （0011 無限循環)，對於計算機而言，0.1 無法精確表達，這是浮點數計算造成精度損失的根源。

因此，IEEE 754 標準定義的浮點數只能根據精度舍入，然後用「近似值」來表示該二進制，那麼意味著計算機存放的小數可能不是一個真實值。

 0.1 + 0.2 並不等於完整的 0.3，這主要是因為這兩個小數無法用「完整」的二進制來表示，只能根據精度舍入，所以計算機裡只能採用近似數的方式來保存，那兩個近似數相加，得到的必然也是一個近似數。