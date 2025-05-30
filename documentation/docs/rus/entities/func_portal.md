﻿# func_portal

Брашевая энтити для реализации порталов, через которые могут проходить игроки, а также все другие игровые сущности. Также, через порталы осуществляется видимость.

## Настройки

- **`Name`** - Имя энтити
- **`Parent`** - Имя энтити, к которой будет прикреплен данный объект
- **`Reflection`** - Тип отражения энтити в зеркалах
- **`Pitch Yaw Roll`** - Угол поворота
- **`ZHLT Lightflags`** - Флаги освещения для компилятора карт
- **`Light Origin Target`** - Источник направления света
- **`Invisible`** - Вкл/выкл видимость браша
- **`Non Solid`** - Вкл/выкл коллизию браша
- **`Destination`** - Имя для **info_portal_destination** (точки куда телепортирует)
- **`Fire on Pass Thru`** - Активирует цель, когда кто-то или что-то успешно проходит сквозь портал

## Спаунфлаги

- **`Start Off`** - Изначально выключен

## Примечания

- Все порталы обязательно должны иметь origin-браш, в противном случае портал будет удалён с карты.
- Порталы используют специальную текстуру, которая начинается с **portal**. Текстура должна быть точно выровнена по краям браша, иначе возможны искажения картинки.
- Сам портал должен быть всегда развернут «лицом», относительно угла YAW игрока, равного нулю. Иными словами, текстура портала должна быть нанесена таким образом, чтобы оказаться лицом к **info_player_start** с углами 0 0 0. Несоблюдение этого требования приведет к неконтролируемому искажению изображения с портала. Развернуть портал в игре так, как вам необходимо, вы можете при помощи его **angles**.
- Также на искажение изображения влияет и толщина портала. Минимальные искажения получаются при толщине в 1–2 юнита.
- При проходе сквозь портал игрок или любой другой объект сохраняет направление движения, ускорение и угол взгляда, но с учётом углов **info_portal_destination**.
- Портал без особых проблем можно привязать при помощи parent-системы, однако остерегайтесь вращения по ROLL.
- Если что-то в точке спауна может помешать пройти сквозь портал (например, выход загорожен ящиками), то перенос осуществлён не будет до тех пор, пока блокирующий предмет не исчезнет. Таким образом достигается гарантированное незастревание после телепортации.
- Для двухсторонних порталов (как на карте **qstyle**, например) имеется система отслеживания направления движения игрока и ориентировки самого портала, что делает невозможным проход в него через заднюю часть.
- Сам по себе проход выглядит достаточно бесшовным, если не обращать внимания на боковые стены.
- Портал можно включать и выключать. Выключенный портал невидим и неосязаем.
