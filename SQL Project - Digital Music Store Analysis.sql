
SELECT * FROM[dbo].[album]
SELECT * FROM [dbo].[artist]
SELECT * FROM [dbo].[customer]
SELECT * FROM [dbo].[employee]
SELECT * FROM [dbo].[genre]
SELECT * FROM [dbo].[invoice]
SELECT * FROM [dbo].[invoice_line]
SELECT * FROM [dbo].[media_type]
SELECT * FROM [dbo].[playlist]
SELECT * FROM [dbo].[playlist_track]
SELECT * FROM [dbo].[track]


--1. Who is the senior most employee based on job title?

SELECT * FROM [dbo].[employee]
ORDER BY levels DESC;

--2. Which countries have the most Invoices?

SELECT COUNT(*) AS C, billing_country
FROM [dbo].[invoice]
GROUP BY billing_country
ORDER BY C DESC

--3. What are top 3 values of total invoice?

SELECT*FROM invoice
SELECT TOP 3 TOTAL
FROM [dbo].[invoice]
ORDER BY TOTAL DESC


--4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
--Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

select sum(total) as invoice_total, billing_city
from [dbo].[invoice]
group by billing_city
order by invoice_total desc

--5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--Write a query that returns the person who has spent the most money

select *from customer

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS total
FROM customer
JOIN INVOICE 
ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY total DESC
select *from customer

--6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A

select distinct email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
     select track_id from track
	 join genre on track.genre_id = genre.genre_id
	 where genre.name like 'Rock'
)
order by email;

           'OR'

select distinct Email, first_name, last_name 
from customer
join invoice
on customer.customer_id = invoice.customer_id
join invoice_line
on invoice.invoice_id = invoice_line.invoice_id
join track
on invoice_line.track_id = track.track_id
join genre
on track.genre_id = genre.genre_id
where genre.name like 'Rock'
order by Email;

--7. Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock bands

select artist.name, count(track.track_id) as no_of_songs
from artist
JOIN album ON album.artist_id = artist.artist_id
JOIN track ON track.album_id = album.album_id
JOIN genre ON genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.name
order by no_of_songs desc
offset 0 rows
fetch next 10 rows only;


--8. Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

select [name],[milliseconds] 
from track
where [milliseconds] >(
    select avg([milliseconds]) as average_song_length
	from track
)
order by [milliseconds] desc;


--9. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent

WITH best_sellig_artist AS (
    select artist.artist_id as artistID, artist.name as artist_name,
    sum(invoice_line.unit_price* invoice_line.quantity) as total_spent
    from invoice_line
    join track on track.track_id = invoice_line.track_id
    join album on album.album_id = track.album_id
    join artist on artist.artist_id = album.artist_id
    group by artist.artist_id, artist.name
    order by total_spent desc
	offset 0 rows
	fetch next 275 rows only
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
sum(il.unit_price*il.quantity)as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_sellig_artist bsa on bsa.artistID = alb.artist_id
group by bsa.artist_name, c.customer_id, c.first_name, c.last_name 
order by amount_spent, bsa.artist_name;


--10. We want to find out the most popular music Genre for each country. We determine 
--the most popular genre as the genre with the highest amount of purchases. 
--Write a query that returns each country along with the top Genre. For countries where 
--the maximum number of purchases is shared return all Genres


WITH popular_genre AS
(
   select COUNT(invoice_line.quantity) as Purchases, customer.country, genre.name, genre.genre_id,
   ROW_NUMBER() over (partition by customer.country order by count (invoice_line.quantity) desc) as RowNo
   from invoice_line
   join invoice on invoice.invoice_id = invoice_line.invoice_id
   join customer on customer.customer_id = invoice.customer_id
   join track on track.track_id = invoice_line.track_id
   join genre on genre.genre_id = track.genre_id
   group by customer.country, genre.name, genre.genre_id
   order by customer.country offset 0 rows
)
select * from popular_genre where RowNo <= 1

--11. Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount

with customer_with_country as
(
   select customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spending,
   row_number () over(partition by billing_country order by sum(total) desc ) as RowNo
   from invoice
   join customer on customer.customer_id = invoice.customer_id
   group by customer.customer_id, first_name, last_name, billing_country
   order by billing_country, total_spending desc offset 0 rows
)
select * from customer_with_country  where RowNo <=1

