Solutions to SQL-EX.ru excercises

#32
#1 вариант
SELECT country, cast(avg((power(bore,3)/2)) AS numeric(6,2)) AS weight 
FROM (SELECT country, classes.class, bore, name FROM classes JOIN ships ON classes.class=ships.class 
	UNION ALL 
	SELECT DISTINCT country, class, bore, ship FROM classes t1 JOIN outcomes t2 ON t1.class=t2.ship 
	WHERE ship=class and ship not in (SELECT name FROM ships) 
) a
GROUP BY country

#2 вариант
WITH ship_list AS
 (SELECT class, name 
    FROM ships
   UNION
  SELECT ship AS class, ship AS name 
    FROM outcomes)

SELECT c.country, cast(AVG(POWER(c.bore, 3) / 2) as NUMERIC(6, 2)) AS weight
  FROM ship_list AS s
  JOIN classes AS c
    ON s.class = c.class
 GROUP BY c.country

#35
SELECT model, type
FROM Product
WHERE model not LIKE '%[^A-Z]%'
OR model not LIKE '%[^0-9]%'

#37
WITH ship_list AS
 (SELECT class, name 
    FROM ships
   UNION
  SELECT ship AS class, ship AS name 
    FROM outcomes)
select c.class
from Classes c
join 
ship_list s on c.class=s.class
group by c.class
having count(*)=1

#38
Найдите страны, имевшие когда-либо классы обычных боевых кораблей ('bb') и имевшие когда-либо классы крейсеров ('bc').
Пересечение и разность http://www.sql-tutorial.ru/ru/book_intersect_except.html

Select
country
from Classes 
where type in ('bb')
intersect
Select
country
from Classes 
where type in ('bc')

#39
Найдите корабли, `сохранившиеся для будущих сражений`; т.е. выведенные из строя в одной битве (damaged), они участвовали в другой, произошедшей позже.
Предикат EXISTS http://www.sql-tutorial.ru/ru/book_exists_predicate.html

#1 вариант
with damag as (
Select
	o.ship, b.date
from Outcomes o
join Battles b on 
	o.battle=b.name
where result='damaged')

Select distinct
	o.ship
from Outcomes o
join Battles b on o.battle=b.name
join damag d on 
	o.ship=d.ship
	and d.date<b.date

#2 вариант
WITH table1 AS (
	SELECT * FROM 
	Outcomes JOIN Battles ON name = battle
	WHERE result = 'damaged'
)

SELECT distinct ship  FROM table1
WHERE EXISTS (	SELECT * FROM Outcomes  JOIN Battles ON name = battle
				WHERE table1.ship = ship AND table1.date < date)

#40
Найти производителей, которые выпускают более одной модели, при этом все выпускаемые производителем модели являются продуктами одного типа.
Вывести: maker, type

with type as (
	Select maker
	from Product
	group by maker
	having count(distinct type)=1),
model as (
	Select maker
	from Product
	group by maker
	having count(*)>1)
select distinct 
	t.maker, p.type
from type t join model m on 
	t.maker=m.maker
join Product p on 
	t.maker=p.maker



#41
Для каждого производителя, у которого присутствуют модели хотя бы в одной из таблиц PC, Laptop или Printer,
определить максимальную цену на его продукцию.
Вывод: имя производителя, если среди цен на продукцию данного производителя присутствует NULL, то выводить для этого производителя NULL,
иначе максимальную цену.

with t1 as (
select
 p.maker, p.model, price from pc join product p on p.model=pc.model
union all 
select 
 p2.maker, p2.model, price from Laptop l join product p2 on p2.model=l.model
union all 
select 
 p3.maker, p3.model, price from Printer pr join product p3 on p3.model=pr.model
)
select 
 maker, 
CASE
WHEN maker IN (SELECT maker FROM t1 WHERE price IS NULL)
THEN NULL
ELSE MAX(price)
END price
FROM t1 GROUP BY maker


#43
Укажите сражения, которые произошли в годы, не совпадающие ни с одним из годов спуска кораблей на воду.

Select
	name
from battles
where datepart(year, date) not in (select launched from ships)

#46
Для каждого корабля, участвовавшего в сражении при Гвадалканале (Guadalcanal), вывести название, водоизмещение и число орудий.

Select
 name, displacement, numGuns
from Classes c
right join (
	select ship as class, ship as name from Outcomes o where battle='Guadalcanal' and ship not in (select name from ships)
	union all
	select class, name from Outcomes o join ships s on 
	o.ship=s.name
 	where battle='Guadalcanal') a on a.class=c.class


#46
Определить страны, которые потеряли в сражениях все свои корабли.

with sh as (
  select c.country, s.name from classes c join ships s on c.class=s.class
  union
  select c.country, o.ship from outcomes o join classes c on c.class=o.ship
),
shs as(
  -- number of sunked ships
  select
    country
    , count(*) as total
  from sh
    join outcomes o on sh.name=o.ship
  where result = 'sunk'
  group by country
),
sht as (
  -- total number of ships
  select
    country
    , count(*) as total
  from sh
  group by country
)
select x.country from sht x join shs y on x.country=y.country
where x.total=y.total


#53
Определите среднее число орудий для классов линейных кораблей.
Получить результат с точностью до 2-х десятичных знаков.

Select cast(avg(numGuns*1.0) as decimal(4,2)) as avg_guns
from Classes
where type='bb'


#56
Для каждого класса определите число кораблей этого класса, потопленных в сражениях. Вывести: класс и число потопленных кораблей.

with sh as (
  select c.class, s.name from classes c join ships s on c.class=s.class
  union
  select c.class, o.ship from outcomes o join classes c on c.class=o.ship
  union 
  select c.class, null as name from classes c
)
Select
 class,
 count(o.ship) as s_qnt
from sh left join Outcomes o on sh.name=o.ship
 and result = 'sunk'
group by class


#57
Для классов, имеющих потери в виде потопленных кораблей и не менее 3 кораблей в базе данных, вывести имя класса и число потопленных кораблей.
with sh as (
select c.class, s.name from classes c join ships s on c.class=s.class
  union
  select c.class, o.ship from outcomes o join classes c on c.class=o.ship
),
t1 as (
 select class from sh group by class having count(*)>=3
)
select sh.class, count(o.ship) as s_qnt
from sh 
join Outcomes o on sh.name=o.ship
 and result = 'sunk'
join t1 on t1.class=sh.class
group by sh.class


#58
Для каждого типа продукции и каждого производителя из таблицы Product c точностью до двух десятичных знаков найти процентное отношение числа моделей данного типа данного производителя к общему числу моделей этого производителя.
Вывод: maker, type, процентное отношение числа моделей данного типа к общему числу моделей производителя

select p.maker, p.type, coalesce(cast((cast(t1.qnt as DEC(12,4))/cast(t2.qnt as DEC(12,4))*100) as numeric(6,2)),0.00) as perc
from
 (select distinct p.maker, p2.type from product p,
 (select distinct type from product) p2) p
left join 
(
select
maker, type, count(distinct model) qnt
from product
group by maker, type) t1 on p.maker=t1.maker and p.type=t1.type
left join (
select
maker, count(distinct model) qnt
from product
group by maker
) t2 on t1.maker=t2.maker


#2 вариант
SELECT p1.maker, p2.type, CAST( 100.00*
  
(SELECT COUNT(1) FROM product p WHERE p.maker = p1.maker AND p.type=  p2.type)
 / 
(SELECT COUNT(1) FROM product p WHERE p.maker = p1.maker) AS decimal (12,2))
 prc
FROM product p1, product p2
GROUP BY p1.maker, p2.type


#60
Посчитать остаток денежных средств на начало дня 15/04/01 на каждом пункте приема для базы данных с отчетностью не чаще одного раза в день. Вывод: пункт, остаток.
Замечание. Не учитывать пункты, информации о которых нет до указанной даты.

select point, sum(inc) from (
Select
point, -sum(out) inc
from Outcome_o
where date < '20010415'
group by point
union all
Select
point, sum(inc) inc
from  Income_o
where date < '20010415'
group by point
)x
group by point


#63
Определить имена разных пассажиров, когда-либо летевших на одном и том же месте более одного раза.

SELECT name
FROM passenger
WHERE id_psg IN 
(SELECT distinct t.id_psg
FROM Pass_in_trip t  
GROUP by t.id_psg, t.place
HAVING  
COUNT(*) > 1)


#65
Пронумеровать уникальные пары {maker, type} из Product, упорядочив их следующим образом:
- имя производителя (maker) по возрастанию;
- тип продукта (type) в порядке PC, Laptop, Printer.
Если некий производитель выпускает несколько типов продукции, то выводить его имя только в первой строке;
остальные строки для ЭТОГО производителя должны содержать пустую строку символов ('').
Функция ROW_NUMBER http://www.sql-tutorial.ru/ru/book_row_number_function.html

select num, case when num2 = 1 then maker end as maker, type
from (
Select 
row_number () over(order by maker, type_no) num,
row_number () over(partition by maker order by maker, type_no) num2,
maker, type
from (select distinct maker, type, 
case when type='PC' then 1 
when type='Laptop' then 2 
when type='Printer' then 3 end as type_no
from Product)x
)x2



Select
count(trip_no) count,
DATE(time_out) date
from Trip
where town_from='Rostov'
--and time_out>='20030401'
--and time_out<='20030407'
group by DATE(time_out)

#65
Для всех дней в интервале с 01/04/2003 по 07/04/2003 определить число рейсов из Rostov.
Вывод: дата, количество рейсов

WITH t1 AS (
SELECT CAST('2003-04-01' AS DATETIME) 'date' 
     UNION ALL
     SELECT DATEADD(dd, 1, t.date) 
       FROM t1 t
where t.date <'2003-04-07'
)

SELECT tt.date, (SELECT COUNT(1) FROM (SELECT DISTINCT t.trip_no
FROM pass_in_trip pip, trip t
WHERE pip.trip_no = t.trip_no
AND t.town_from = 'rostov'
AND tt.date = pip.date) trips )Qty
FROM t1 tt

#65
Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
Замечания.
1) A - B и B - A считать РАЗНЫМИ маршрутами.
2) Использовать только таблицу Trip

with t1 as 
(
Select
 count(trip_no) qnt,
town_from, town_to
from trip
group by town_from, town_to
),
t2 as (
select max(qnt) mqnt from t1
)
select count(*) from t1
join t2 on t2.mqnt=t1.qnt

#68
Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
Замечания.
1) A - B и B - A считать ОДНИМ И ТЕМ ЖЕ маршрутом.
2) Использовать только таблицу Trip
with table1 as (
select CASE WHEN town_from<=town_to 
THEN town_from+town_to 
ELSE town_to+town_from END ab,
count(*) ct from trip 
group by CASE WHEN town_from<=town_to 
THEN town_from+town_to 
ELSE town_to+town_from END ) 

select count(*) from table1 where ct=(select max(ct) from table1)



#66
По таблицам Income и Outcome для каждого пункта приема найти остатки денежных средств на конец каждого дня,
в который выполнялись операции по приходу и/или расходу на данном пункте.
Учесть при этом, что деньги не изымаются, а остатки/задолженность переходят на следующий день.
Вывод: пункт приема, день в формате "dd/mm/yyyy", остатки/задолженность на конец этого дня.
Функция CONVERT http://www.sql-tutorial.ru/ru/book_type_conversion_and_cast_function/page2.html

with t1 as (
Select 
point, date, sum(inc) inc
from income i
group by point, date
union all
Select 
point, date, sum(-out) inc
from outcome i
group by point, date
)
Select 
 point, CONVERT(char(25), date,103) date,
(SELECT SUM(inc) 
   FROM t1  x2
   WHERE point = t1 .point AND date <= t1 .date) run_tot
from t1
group by point, date



#71
Найти тех производителей ПК, все модели ПК которых имеются в таблице PC.
Реляционное деление http://www.sql-tutorial.ru/ru/book_relational_division.html

Select
 maker
from product p
where type='PC'
group by maker
having count(DISTINCT model) = (SELECT COUNT(DISTINCT product.model) FROM Product join pc on product.model=pc.model where type='PC' and p.maker=Product.maker)


#72
Среди тех, кто пользуется услугами только какой-нибудь одной компании, определить имена разных пассажиров, летавших чаще других.
Вывести: имя пассажира и число полетов.

with t1 as (
	Select 
 		pit.id_psg
	from pass_in_trip pit
	join trip tr on pit.trip_no=tr.trip_no
	group by pit.id_psg
	having count(distinct tr.id_comp) =1
)
, t2 as (
	select p.id_psg, count(*) qnt 
	from pass_in_trip p
	join t1 on t1.id_psg=p.id_psg
	group by p.id_psg
)
, t3 as (
	select max(qnt) as mqnt from t2
)
select 
	name, 
	t2.qnt 
from passenger ps
join t2 on t2.id_psg = ps.id_psg
join t3 on t3.mqnt = t2.qnt



#73
Для каждой страны определить сражения, в которых не участвовали корабли данной страны.
Вывод: страна, сражение

with t1 as (select distinct country, name as battle from classes c, battles b)
select t1.* from t1 left join 
(
Select country, name, battle 
from Classes c
join (
	select ship as class, ship as name, o.battle from Outcomes o where ship not in (select name from ships)
	union all
	select class, name, o.battle from Outcomes o join ships s on 
	o.ship=s.name) a on a.class=c.class) a on t1.country=a.country
and t1.battle=a.battle
where a.battle is null


#74
Вывести все классы кораблей России (Russia). Если в базе данных нет классов кораблей России, вывести классы для всех имеющихся в БД стран.
Вывод: страна, класс

#1 вариант
Select
 country, class
from Classes c
where case when exists (select country from classes where country='Russia') then 'Russia' 
else country end = country

#2 вариант
SELECT  country, class
FROM classes
WHERE country = ALL (SELECT   country
FROM classes
WHERE country = 'Russia')


#75
Для тех производителей, у которых есть продукты с известной ценой хотя бы в одной из таблиц Laptop, PC, Printer найти максимальные цены на каждый из типов продукции.
Вывод: maker, максимальная цена на ноутбуки, максимальная цена на ПК, максимальная цена на принтеры.
Для отсутствующих продуктов/цен использовать NULL.

with p as (select maker, type, model from product),
price_t as (
  Select
   maker, p.type, price as mprice
  from p join pc on pc.model=p.model and p.type='PC'
union all
  Select
   maker, p.type, price as mprice
  from p join Laptop pc on pc.model=p.model and p.type='Laptop'
union all
  Select
   maker, p.type, price as mprice
  from p join Printer pc on pc.model=p.model and p.type='Printer'),
t1 as (
  select maker, case when type='Laptop' then mprice end as mprice_l,
  case when type='PC' then mprice end as mprice_pc,
  case when type='Printer' then mprice end as mprice_pr
  from price_t)
select maker, max(mprice_l) mprice_l, max(mprice_pc) mprice_pc, max(mprice_pr) mprice_pr
from t1
group by maker
having max(mprice_l) is not null or max(mprice_pc) is not null or max(mprice_pr) is not null

