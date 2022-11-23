SQL-EX

#32
/*Select
 country,
 cast(avg((bore*bore*bore)/2) AS NUMERIC(6,2)) as mv
from ( select cast (bore AS NUMERIC(6,2)) as bore, country, class from classes) c
join (
 select ship as class from outcomes
 union all
 select class from ships) s on c.class=s.class
group by country

SELECT country, cast(avg((power(bore,3)/2)) AS numeric(6,2)) AS weight 
FROM (SELECT country, classes.class, bore, name FROM classes LEFT JOIN ships ON classes.class=ships.class 
	UNION ALL 
	SELECT DISTINCT country, class, bore, ship FROM classes t1 LEFT JOIN outcomes t2 ON t1.class=t2.ship 
	WHERE ship=class and ship not in (SELECT name FROM ships) 
) a WHERE name IS NOT NULL GROUP BY country*/

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
