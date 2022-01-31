# TNFT Interfaces

Ссылка на описание технологии True-NFT - https://github.com/itgoldio/everscale-tnft

## Содержание
* [__Описание__](#description)
* [__Интерфейсы:__](#smart_contracts)
    * [Data Interfaces](#dataint)
      * [IRequiredInterfaces](#ireqint)
      * [IName](#idescription)
      * [IBurnByOwner](#iburnbyowner)
      * [ICustomInterfaces](#icustominterfaces)

<h1 id="description">Описание технологии интерфейсов</h1>

Проблема:

* <a href="https://github.com/itgoldio/everscale-tnft">True-NFT стандарт</a> слишком простой и требует доработки под нужный use-case.
* При добавлении нового функционала разработчики off-chain приложений должны искать интерфейсы для взаимодействия с новыми механиками.

Наше решение состоит из простых интерфейсов (модулей), у которых есть ID и abstract contract, который имплементирует методы интерфейса.
У каждого интерфейса есть уникальный идентификатор (ID), собранный по правилам:

* 1 - интерфейс getInterfaces
* от 2 до 4999 - стандартные интерфейсы (из этого репозитория)
* 41000 - интерфейс getCustomInterfaces, который содержит переменную - url кастомных интерфейсов.
* от 41001 до ∞ - кастомные интерфейсы, написанные разработчиками для своего продукта (которые можно найти по url кастомных интерфейсов) 
  
Если в контрактах используются какие-то интерфейсы (кастомные или из этого репозитория) - необходимо имплементировать абстрактный контракт RequiredInterfaces и в конструкторе
переменной _requiredInterfaces установить значения всех используемых интерфейсов:

```
 _requiredInterfaces = [RequiredInterfacesLib.ID, INameLib.ID ...];
```

Контракт должен имплементировать абстрактный контракт, не интерфейс:

```
    Yes: 
    contract Name is RequiredInterfaces, Name

    No: 
    contract Name is IRequiredInterfaces, IName
```

Каждый интерфейс должен содержать в себе такую структуру:

```
interface IName {
    function getName() external returns (string dataName);
}

library NameLib {
    int constant ID = 2;        
}

abstract contract Name is IName {

    string _dataName;

    function getName() public override returns (string dataName) {
        return _dataName;
    }   

}

```

Если вы имплементируете какой-то интерфейс - в конструкторе необходимо установить значения из их абстрактного контракта

```
contract Name is RequiredInterfaces, Name { 
    // Не забываем имплементировать интерфейс RequiredInterfaces
    constructor(
        ...
        string dataName
    ) {
        _dataName = dataName;
        _requiredInterfaces = [RequiredInterfacesLib.ID, NameLib.ID ...];
        // Не забываем устанавливать значение _requiredInterfaces
    }
}
```

<h1 id="smart_contracts">Интерфейсы</h1>

<h1 id="dataint">Data Interfaces</h1>

<h2 id="ireqint">IRequiredInterfaces</h2>

Возвращает массив ID всех использующихся интерфейсов в контракте
```
int[] _requiredInterfaces;

function getRequiredInterfaces() external returns(int[] requiredInterfaces);
function getRequiredInterfacesResponsible() external responsible returns(int[] requiredInterfaces);
```

<h2 id="iname">IName</h2>

Используется для добавления названия Nft в Data контракт
```
string _dataName;

function getName() external returns (string dataName);
function getNameResponsible() external responsible returns (string dataName);
```

<h2 id="iburnbyowner">IBurnByOwner</h2>

Содержит метод burn, который может вызвать только владелец, работает от internal messages
```
function burnByOwner() external;
```

<h2 id="icustominterfaces">ICustomInterfaces</h2>

Используется в случае, если вы написали свои интерфейсы. В параметр _customInterfacesUrl необходимо вписать url на репозиторий с интерфейсами. Кастомные интерфейсы должны содержать ID > 41000
```
string _customInterfacesUrl;

function getCustomInterfacesUrl() external returns (string url);
function getCustomInterfacesUrlResponsible() external responsible returns (string url);
```