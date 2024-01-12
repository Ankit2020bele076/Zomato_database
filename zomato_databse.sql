CREATE DATABASE zomato_database;
USE zomato_database;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;




-- 1. what is the total amount each customer spend on zomato?
select sales.userid, sum(product.price) as total_amount_spend from sales inner join product on sales.product_id = product.product_id
group by sales.userid
order by sales.userid;


-- 2. How many days has each customer visited zomato?
select userid, count(distinct created_date) as total_days_visited from sales
group by userid;


-- 3. What was the first product purchased by each customer?
select userid, product_id from (select *, rank() over (partition by userid order by created_date) as rnk from sales) as a where rnk = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select userid, count(product_id) from sales 
where product_id = (select product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid;


-- 5. Which item was the most popular for each customer?
select userid, product_id from
(select *, rank()over(partition by userid order by cnt desc) as rnk from (select userid, product_id, count(product_id) as cnt from sales group by product_id, userid)as a)as b
where rnk = 1;


-- 6. Which item was first purchased by the customer after they become a member?
select userid, product_id from
(select *, rank() over (partition by userid order by created_date) as rnk from
(select sales.userid, sales.created_date, sales.product_id from sales inner join goldusers_signup on sales.userid = goldusers_signup.userid where sales.created_date >= goldusers_signup.gold_signup_date) as a) as b 
where rnk = 1;


-- 7. Which item was purchased just before the customer became a member?
select userid, product_id from
(select *, rank() over (partition by userid order by created_date desc) as rnk from
(select sales.userid, sales.created_date, sales.product_id from sales inner join goldusers_signup on sales.userid = goldusers_signup.userid where sales.created_date < goldusers_signup.gold_signup_date) as a) as b 
where rnk = 1;


-- 8. What is the total orders and amount spent for each member before they became a member?
select userid, count(created_date) as total_orders, sum(price) as total_amount_spent from
(select a.*, product.price from
(select sales.userid, sales.created_date, sales.product_id, goldusers_signup.gold_signup_date from sales inner join goldusers_signup on sales.userid = goldusers_signup.userid 
where sales.created_date < goldusers_signup.gold_signup_date) as a inner join product on a.product_id = product.product_id)as c
group by userid;


-- 9. If buying each product generates points for eg 5rs = 2 zomato point and each product has different purchasing points
--    for eg for p1 5rs=1 zomato point, for p2 10rs=5 zomato point and p3 5rs=1 zomato point.
--    Calculate points collected by each customers and for which product most points have been given till now.
select userid, sum(total_points) as total_points from
(select *, round((case when product_id = 2 then prod_price/2 else prod_price/5 end),0) as total_points from
(select sales.userid, sales.product_id, sum(product.price) as prod_price from sales inner join product on sales.product_id = product.product_id
group by sales.userid, sales.product_id
order by sales.userid, sales.product_id) as a) as b
group by userid;

select product_id, sum(total_points) as total_points from
(select *, round((case when product_id = 2 then prod_price/2 else prod_price/5 end),0) as total_points from
(select sales.userid, sales.product_id, sum(product.price) as prod_price from sales inner join product on sales.product_id = product.product_id
group by sales.userid, sales.product_id
order by sales.userid, sales.product_id) as a) as b
group by product_id
order by total_points desc
limit 1;


-- 10. In the first one year after a customer joins the gold program (including their join date) irrespective of what customer has purchased 
--     they earn 5 zomato points for every 10rs spent who earned more more 1 or 3 and what was their points earnings in their first year?
select userid, sum(price) as total_amount_spent, sum(price) * 0.5 as total_points_earned from
(select a.*, product.price from
(select sales.userid, sales.created_date, sales.product_id, goldusers_signup.gold_signup_date from sales inner join goldusers_signup on sales.userid = goldusers_signup.userid 
where sales.created_date >= goldusers_signup.gold_signup_date and year(sales.created_date) <= (year(goldusers_signup.gold_signup_date)+1)) as a
inner join product
on a.product_id = product.product_id)as b
group by userid;


-- 11. Rank all the transactions of the customer.
select *, rank() over(partition by userid order by created_date) as rnk from sales;


-- 12. Rank all the transactions for each member whenever they are a zomato gold member, for every non gold member transaction mark as na.
select *, case when gold_signup_date is not null then rank() over (partition by userid order by created_date desc) else 'na' end as rnk from
(select sales.userid, sales.created_date, sales.product_id, goldusers_signup.gold_signup_date from sales left join goldusers_signup on sales.userid = goldusers_signup.userid 
and created_date >= gold_signup_date) as a;