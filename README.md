# Update TNFT by itgold

Ссылка на оригиналую версию TNFT (https://github.com/tonlabs/True-NFT/tree/main/components/true-nft-core)

## Содержание
* [__Наши изменения__](#our_changes)
    * [Data](#ch_data)
    * [NftRoot](#ch_root)
* [__Смарт-контракты:__](#smart_contracts)
    * [Описание](#sm_description)
    * [NftRoot](#sm_nftroot)
    * [IndexBasis](#sm_indexBasis)
    * [Data](#sm_data)
    * [Index](#sm_index)
* [__Поиск контрактов в блокчейне:__](#search)
    * [Поиск NftRoot](#search_nftRoot)
    * [Поиск всех nft по владельцу и root адресу](#search_by_nftRoot&owner)
    * [Поиск всех nft владельца (без привязки к nftRoot address)](#search_nft_by_owner)
* [__Система интерфейсов__](#interfaces)

***

<h1 id="our_changes">Наши изменения</h1>

<h2 id="ch_data">Data:</h2>

**Проблема:**
Возможность передачи токена на нулевой адрес

**Решение:**
transferOwnership(address addrTo) - добавлена проверка, что addrTo != 0

***

**Проблема:**
Если нам нужно изменить Index контракт - нам нужно передеплоивать Data контракты т.к. в них не заложены возможности установки нового кода index и передеплоивания его.

**Решение:**

* Добавлена возможность делать редеплой Index (Уничтожаются старые индексы и деплоятся новые)

* Добавлена возможность изменять код индекса (setIndexCode)

* setIndexCode и redeployIndex работают только от Internal msg от адреса владельца
***

**Проблема:**
Нет возможности вызвать метод getInfo из других контрактов

**Решение:**
Добавлена функция getInfoResponsible для получения информации о nft из других контрактов

***

**Проблема:**
Нет возможности автоматизировать on-chain и off-chain приложения

**Решение:**
Добавлены 2 ивента: tokenWasMinted и ownershipTransferred

* При минте Data контракта выпускается ивент tokenWasMinted с адресом владельца

* transferOwnership(address addrTo) - при передаче nft выпускается ивент 
ownershipTransferred(addrOldOwner, addrNewOwner)

***

<h2 id="ch_root">NftRoot:</h2>

Для лучшего восприятия были изменены названия:

* _addrBasis -> _addrIndexBasis
* deployBasis -> deployIndexBasis
* deployBasis -> deployIndexBasis
    
**Проблема:**
Не защищены методы работы с indexBasis (deployIndexBasis и destructIndexBasis)

**Решение:**

* deployIndexBasis и destructIndexBasis работают только с проверкой публичного ключа ( tvm.pubkey() == _ownerPubkey )

**Проблема:**
Нет возможности автоматизировать on-chain и off-chain приложения

**Решение:**

* Добавлен event tokenWasMinted(address nftAddr, address creatorAddr) после минтинга Data контракта

**Проблема:**
Не возвращается сдача после минтинга Nft

**Решение:**

* Добавлен rawReserve()

**Проблема:**
Нет проверки на сумму, переданную в сообщение при минтинге. Можно вызвать mint даже ext msg без кристаллов, что может привести к обнулению кристаллов на аккаунте и последующей заморозке. 

**Решение:**
При минтинге проверяем, что сумма транзакции больше, чем минимум для деплоя, который считаем по формуле:
```
(_indexDeployValue * 2) + _remainOnData + _processingValue
```
* _indexDeployValue - Количество кристаллов, которые будут потрачены в Data контракте для деплоя Index. (x2 т.к. дата выпускает 2 индекса, подробнее <a href="#2_deploy">тут</a>)

* _remainOnData - Количество кристаллов, которые останутся на контракте Data после деплоя Data и деплоя 2 Index

* _processingValue - минимальное количество кристаллов, которое будет потрачено на выполнения процесса минтинга, после успешного минтинга сдача будет возвращена отправителю.

***

<h1 id="smart_contracts">Смарт-контракты</h1>

<h2 id="sm_description">Описание смарт-контрактов:</h2>

* NftRoot - смарт-контракт, который отвечает за выпуск NFT.

* Data - Контракт хранит информацию, которая по сути является NFT, а также отвечает за смену владельца.

* Index - контракт, который используется для поиска всех NFT для конкретного владельца.

* IndexBasis - Контракт, который используется для поиска всех корней и всех NFT.

<h2 id="sm_nftroot"><b>NftRoot:</b></h2>
Минтит Data контракты, а так же выпускает IndexBasis.
Используется для вычисления codeHash индексов ( при поиске )

***

<h2 id="sm_indexBasis"><b>IndexBasis:</b></h2>
Деплоится NftRoot контрактом. Хранит: 

* codeHash
* адрес NftRoot контракта

Используется для поиска коллекции ( В блокчейне можеть сколько угодно коллекций (NftRoot -> Data), но т.к. они выпускают indexBasis с одинаковым codeHash - можно найти по нему все контракты IndexBasis )

***

<h2 id="sm_data"><b>Data:</b></h2>

code Data контракта для минтинга формируется на основе:

* TvmCell кода Data контракта (передается в конструкторе)
* Адреса NftRoot контракта

```
    function _buildDataCode(address addrRoot) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeData, salt.toCell()); 
        // В код data контракта вшивается переменная addrRoot, чтобы изменить codehash
    }

    function _buildDataState(
        TvmCell code,
        uint256 id
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Data,
            varInit: {_id: id},
            code: code
        });
    }
```

Для уникальности адреса Data контракта используется static переменная _id, которая при минтинге заполняется засчет переменной totalMinted NftRoot контракта.

***

<h2 id="sm_index"><b>Index:</b></h2>

Для упрощенного поиска nft Data деплоит 2 контракта Index.
    
code Index формируется на основе:
* TvmCell кода Index контракта (передается в конструкторе)
* Адреса addrRoot (NftRoot контракта)
* Адреса addrOwner

```
    function _buildIndexCode(
        address addrRoot,
        address addrOwner
    ) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        salt.store(addrOwner);
        return tvm.setCodeSalt(_codeIndex, salt.toCell());
    }

    function _buildIndexState(
        TvmCell code,
        address addrData
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Index,
            varInit: {_addrData: addrData},
            code: code
        });
    }
```

Также для уникальности используется static переменная addrData. Таким образом можно выпустить только 2 индекса т.к. при попытке
задеплоить больше индексов ключевые переменные (использующееся для формирования адреса) будут повторяться.
    
<h1 id="2_deploy"></h1> <b>Data</b> контракт деплоит 2 index:

* **Первый** index с заполненными полями addrOwner и addrRoot, которые добавляются к коду контракта перед деплоем.
Такой index используется для быстрого поиска всех index, ссылающихся на Data контракт, относящийся к одной коллекции с одним владельцем. 

```
    TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
    TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
    new Index{stateInit: stateIndexOwner, value: 0.4 ton}(_addrRoot);
```

* **Второй** index с заполненным полем addrOwner и нулевым addRoot (addrRoot устанавливается в конструкторе, 
но не добавляется к коду и таким образом не влияет на формирование кода перед деплоем).
Такой index используется для быстрого поиска всех index, ссылащихся на Data контракт, относящийся к одному владельцу и к любой коллекции. 

```
    TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
    TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
    new Index{stateInit: stateIndexOwnerRoot, value: 0.4 ton}(_addrRoot);
```

<h1 id="search">Поиск контрактов в блокчейне:</h1>

Для упрощенного поиска используем codeHash контрактов.

<h2 id="search_nftRoot">Поиск NftRoot</h2>

Для поиска NftRoot контракта используется IndexBasis. Используя hash code контракта IndexBasis мы можем сделать запрос в graphql:

```
query { 
    accounts 
    (filter : {
        code_hash :{eq : "38f6d9b0e990df92b6275a2b06c0bb78a851c63f7fdf8753fd1292a6375de3a3"}
    })
{
    id
}}
```
**где** "38f6d9b0e990df92b6275a2b06c0bb78a851c63f7fdf8753fd1292a6375de3a3" - **codehash** контракта IndexBasis

```
Output: 

{
  "data": {
    "accounts": [
      {
        "id": "0:122343cf9d957cb02abf9520dac538f69d434331dd132d87389f8609572359f7"
      },
      {
        "id": "0:a7d18227878c71ab0caeb41e94007f3e2fe493226c1c904b91a8ee4048ae027c"
      },
      {
        "id": "0:eab62e2072f3cea01fd1c897eac91af90b307b488f62ea4e95add8d2e96aaa37"
      },
      {
        "id": "0:ab5c2d291e0611295f6ec06c2a33e31b1a28c8393114df11e70bb63cd7ff41e4"
      }
    ]
  }
}
```

Зная abi контракта IndexBasis вызовем его get метод getInfo:
```
tonos-cli run 0:122343cf9d957cb02abf9520dac538f69d434331dd132d87389f8609572359f7 getInfo '{}'--abi IndexBasis.abi.json

Input arguments:
 address: 0:122343cf9d957cb02abf9520dac538f69d434331dd132d87389f8609572359f7
  method: getInfo
  params: {}
     abi: IndexBasis.abi.json
     ...
Connecting to net.ton.dev
Running get-method...
Succeeded.

Result: {
  "addrRoot": "0:d5e4fc1c71d564ed3443d89f78f6fa0dcbe509a08c19b474678baf6abe10b6f9",
  "codeHashData": "0xf30abcc13d47cadd63c95f6322eb7bcef5222bc920a3d337198d4aa6f7286ea9"
}

```

В каждом таком **IndexBasis** хранится адрес **nftRoot** и **codeHash** всех data контрактов, по этому codeHash мы можем найти все Data контракты,
задеплоенным nftRoot, адрес которого хранится в IndexBasis.
    
```
query { 
    accounts (
    filter : {
    code_hash :{eq : "f30abcc13d47cadd63c95f6322eb7bcef5222bc920a3d337198d4aa6f7286ea9"}
    })
{
    id
}}
```
**где** "f30abcc13d47cadd63c95f6322eb7bcef5222bc920a3d337198d4aa6f7286ea9" - **codeHash** Data контракта

***

<h2 id="search_by_nftRoot&owner">Поиск всех nft по владельцу и root адресу</h2>

Зная адрес nftRoot контракта вызываем его геттер **resolveCodeHashIndex**(addrRoot, addrOwner):

- передаём addrRoot 0:2641d4664bc9a270c7556ee6b6443dda2de62b2a6df14a6d65c955fc389b6313
- передаём addrOwner 0:d3fe9e0c9c5e97c8692848873205802cb727be8235f4d9e2bdd1bb0247c70fda
Получаем 

```
Result: {
    "codeHashIndex": "0xad82b31be10c917311a00d0f15c7486bb7c002eb8dd7790c56dbd8a999680c77"
}
```

Получили code hash Index контракта (Метод высчитал code hash на основе TvmCell code + addrRoot)

**Получаем все index контракты этой коллекции:**

```
query { accounts (filter : {
    code_hash :{eq : "ad82b31be10c917311a00d0f15c7486bb7c002eb8dd7790c56dbd8a999680c77"}
})
{
    id
}}

{
"data": {
    "accounts": [
    {
        "id": "0:272fe2aeed1902ba133267e51500f764eabe900e0d955b91f6b7087f8ad9f358"
    },
    {
        "id": "0:d8f38f9cc9843522f67e27ba454cdc907c406db281661ba47e90b80b97c6866d"
    },
    {
        "id": "0:bc8fcec10ee3e321cdd71553bfb2f4c575d3a602f9954f3eb374920ac8486d7d"
    }
    ]
}
}
```

Затем вызвав у каждого index метод **getInfo** получим addrData, тот самый адрес Nft (addrData)
```
Input arguments:
 address: bc8fcec10ee3e321cdd71553bfb2f4c575d3a602f9954f3eb374920ac8486d7d
  method: getInfo
  params: {}
  ...
Connecting to net.ton.dev
Running get-method...
Succeeded.

Result: {
  "addrRoot": "0:2641d4664bc9a270c7556ee6b6443dda2de62b2a6df14a6d65c955fc389b6313",
  "addrOwner": "0:d3fe9e0c9c5e97c8692848873205802cb727be8235f4d9e2bdd1bb0247c70fda",
  "addrData": "0:715dd51093c1e82b97d88355285c011bbe75aad836ec276a9d3b25818e3f7edf"
}
```
***

<h2 id="search_nft_by_owner">Поиск всех nft владельца (без привязки к nftRoot address)</h2>

Зная адрес nftRoot контракта вызываем его геттер **resolveCodeHashIndex**(addrRoot, addrOwner):

- передаём addrRoot 0:0000000000000000000000000000000000000000000000000000000000000000
- передаём addrOwner 0:d3fe9e0c9c5e97c8692848873205802cb727be8235f4d9e2bdd1bb0247c70fda
Получаем 

```
Result: {
    "codeHashIndex": "0x6e3000dc81c18080267305ffd0da82ff20e80705cdcf540dfbd709006b2f7c01"
}
```

Получили code hash Index контракта (Метод высчитал code hash на основе TvmCell code + addrRoot)

**Получаем все index контракты владельца: (всех коллекций)**

```
Input:

query { accounts (filter : {
    code_hash :{eq : "6e3000dc81c18080267305ffd0da82ff20e80705cdcf540dfbd709006b2f7c01"}
})
{
    id
}}

Output:

{
  "data": {
    "accounts": [
      {
        "id": "0:8b8ce564309779f8a90db2bb0418354bbc698c2fce876c56a0fd4cbce26ba966"
      },
      {
        "id": "0:4ac2b077f2d188c44e119a43a8dc0473e4451e63679d3daac81767b6951a7d56"
      },
      {
        "id": "0:4ad2ef00e502c32a597218176d91a0cc9d4a6dab38a607edec5eb836bc27e84d"
      }
    ]
  }
}
```
Для того, чтобы узнать addrData - нужно у index вызвать метод getInfo

```
Input arguments:
 address: 8b8ce564309779f8a90db2bb0418354bbc698c2fce876c56a0fd4cbce26ba966
  method: getInfo
  params: {}
  ...
Connecting to net.ton.dev
Running get-method...
Succeeded.

Result: {
  "addrRoot": "0:2641d4664bc9a270c7556ee6b6443dda2de62b2a6df14a6d65c955fc389b6313",
  "addrOwner": "0:d3fe9e0c9c5e97c8692848873205802cb727be8235f4d9e2bdd1bb0247c70fda",
  "addrData": "0:45e3dbe901b7f9946d345ef959c9ff057d273800e033e836ec79d3a44a4f43c8"
}
```

<h1 id="interfaces">Система интерфейсов</h1>
Мы разработали систему интерфейсов для True-NFT. Подробнее <a href="https://gitlab.itglobal.com/everscale/tnft-interfaces">по ссылке.</a>