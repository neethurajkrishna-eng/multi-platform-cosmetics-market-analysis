USE cosmetic_market;
SELECT * FROM nykaa_products limit 10;

-- =====================================================
-- I. Categories and Subcategories Analysis
-- =====================================================

-- Business Question:
-- 1. How is Nykaa's product assortment distributed across categories and subcategories?

-- Purpose:
-- Identify the categories and subcategories with the largest product assortment on Nykaa.


SELECT 
	category,
    SUM(COUNT(*)) OVER(PARTITION BY category) AS total_products_in_category,
    sub_category,
    COUNT(*) AS total_products_in_subcategory
FROM nykaa_products
GROUP BY 
	category,
    sub_category
ORDER BY 
		total_products_in_category DESC,
		category,
        total_products_in_subcategory DESC,
        sub_category
;

-- Key Observations:
-- Skin Care has the largest product assortment, followed by Hair Care, Body Care, and Makeup.
-- Within Skin Care, Face Moisturizer and Serum are among the leading subcategories.
-- Shampoo is the most represented subcategory within Hair Care.


-- =====================================================
-- II. Brand Analysis
-- =====================================================

-- Business Question:
-- 1. Which brands have the largest product assortment on Nykaa?

-- Purpose:
-- Identify the brands with the largest number of product listings on Nykaa.


SELECT 
    brand,
    COUNT(*) AS product_count
FROM nykaa_products
WHERE brand <> 'Unknown'
GROUP BY brand
ORDER BY product_count DESC
LIMIT 15;

-- Key Observations:
-- Nykaa Cosmetics has the largest product assortment in the dataset with 329 products, making it the most represented brand.
-- The top-ranked brands have relatively similar product counts, suggesting that the assortment is distributed across multiple leading brands rather than dominated by a single brand.
-- The leading brands include Nykaa's private label, established Indian brands, and international cosmetic brands, reflecting a diverse product portfolio.


-- Business Question:
-- 2. Which brands have the largest product presence within each category?

-- Purpose:
-- Identify the leading brands within each category based on product assortment.



WITH category_brand AS(
	SELECT 
		category,
		SUM(COUNT(*)) OVER(PARTITION BY category) AS category_total,
		brand,
		COUNT(*) AS brand_products,
		round(COUNT(*)/SUM(COUNT(*)) OVER(PARTITION BY category)*100,2) AS brand_share_percent,
		DENSE_RANK() OVER(PARTITION BY category ORDER BY COUNT(*) DESC) AS row_num
	FROM nykaa_products
	GROUP BY category,brand
)
SELECT
	category,
    category_total,
    brand,
    brand_products,
    brand_share_percent
FROM category_brand
WHERE row_num <= 10
ORDER BY 
	category_total DESC,
    category,
    brand_products DESC,
    brand;
    
-- Key Observations:

-- No single brand dominates every category. Different brands lead different product categories, indicating a competitive and diverse marketplace.
-- Lotus Herbals has the highest product count in the Skin Care category with 195 products, representing approximately 2.44% of the category assortment.
-- Schwarzkopf Professional leads the Hair Care category, closely followed by Wella Professionals and Aveda, reflecting strong competition among professional haircare brands.
-- Bath & Body Works is the most represented brand in Body Care, with 184 products (5.78% share), significantly ahead of the next-ranked brands.
-- PAC and Makeup Revolution are the leading brands in Face Makeup and Eye Makeup, indicating a strong presence in decorative cosmetics.
-- Makeup Revolution and M.A.C lead the Lip Makeup category, while Shills Professional dominates Nail Makeup, accounting for over one-fifth of all products in that category (20.24%).
-- Some smaller categories show higher brand concentration. For example, VOESH accounts for more than 10% of the Hands & Feet Care assortment.
-- Shills Professional dominates the Nail Makeup category, accounting for approximately 20.24% of the category assortment.

-- =====================================================
-- III. Price Analysis
-- =====================================================

-- Business Question:
-- 1. Which premium-priced products are available within each subcategory?

-- Purpose:
-- Identify premium-priced, well-rated products within each subcategory and understand the high-end product offerings on Nykaa.

-- Assumptions:
/*
   1. Premium products are identified within each subcategory based on original price.
   2. Original price is used because discounts may vary over time and across promotional periods.
   3. Only products with ratings of 4.0 or above are included to focus on well-rated premium products.
   4. The "Combo" subcategory is excluded from the comparison.
*/


WITH price_ranking AS(
	SELECT 
		category,
		sub_category,
		product_name,
		brand,
		original_price AS price,
		DENSE_RANK() OVER (
            PARTITION BY category, sub_category 
            ORDER BY original_price DESC, rating_out_of_5 DESC
        ) AS price_rank,
        rating_out_of_5
	FROM nykaa_products
    WHERE rating_out_of_5 >= 4.0
    AND sub_category != "Combo"
            )
SELECT 
    category, 
    sub_category, 
    product_name, 
    brand, 
    price,
    rating_out_of_5
FROM 
    price_ranking 
WHERE 
    price_rank <= 10 
ORDER BY 
    category, 
    sub_category, 
    price_rank, 
    rating_out_of_5 DESC;
    
-- Key Observations:
-- Premium-priced products are available across a wide range of subcategories, indicating that Nykaa offers products across different price points.
-- Higher-priced offerings are particularly visible in skincare and professional haircare categories.
-- The analysis focuses on products with ratings of 4 stars or above to identify well-rated premium-priced products.      

-- Business Question:
-- 2. Which budget-friendly products are available within each subcategory?

-- Purpose:
-- Identify affordable, well-rated products within each subcategory and understand the lower-priced product offerings on Nykaa.

-- Assumptions:
/*
   1. Affordable products are identified within each subcategory based on original price.
   2. Original price is used because discounts may vary over time and across promotional periods.
   3. Only products with ratings of 4.0 or above are included to focus on well-rated affordable products.
   4. The "Combo" subcategory is excluded from the comparison.
*/

    
WITH price_ranking AS(
	SELECT 
		category,
		sub_category,
		product_name,
		brand,
		original_price AS price,
		DENSE_RANK() OVER (
            PARTITION BY category, sub_category 
            ORDER BY original_price ASC, rating_out_of_5 DESC
        ) AS price_rank,
        rating_out_of_5
	FROM nykaa_products
    WHERE rating_out_of_5 >= 4.0
    AND sub_category != "Combo"
            )
SELECT 
    category, 
    sub_category, 
    product_name, 
    brand, 
    price,
    rating_out_of_5
FROM 
    price_ranking 
WHERE 
    price_rank <= 10 
ORDER BY 
    category, 
    sub_category, 
    price_rank, 
    rating_out_of_5 DESC;  
    
-- Key Observations:

-- Budget-friendly alternatives are available in almost every subcategory, making beauty and personal care products accessible across different price ranges.
-- Many low-priced products also have ratings of 4 stars or above, indicating that affordable products in the dataset are not necessarily associated with lower customer ratings.

-- Business Question:
-- 3. How are products distributed across different discount tiers?

-- Purpose:
-- Analyze Nykaa's discount structure by examining the proportion of products across different discount tiers and identifying representative products within each tier.

-- Discount tiers:
-- No Discount: 0%
-- Low Discount: 1–19%
-- Medium Discount: 20–39%
-- High Discount: 40% and above

WITH discount_category AS (
    SELECT
        product_name,
        original_price,
        discounted_price,
        discount_percent,

        CASE
            WHEN discount_percent = 0 THEN 'No Discount'
            WHEN discount_percent >= 40 THEN 'High Discount (40-100%)'
            WHEN discount_percent < 20 THEN 'Low Discount (1-19%)'
            ELSE 'Medium Discount (20-39%)'
        END AS discount_tier,

        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN discount_percent = 0 THEN 'No Discount'
                    WHEN discount_percent >= 40 THEN 'High Discount (40-100%)'
                    WHEN discount_percent < 20 THEN 'Low Discount (1-19%)'
                    ELSE 'Medium Discount (20-39%)'
                END
            ORDER BY
                CASE
                    WHEN discount_percent = 0 THEN original_price
                    WHEN discount_percent >= 40 THEN -discount_percent
                    WHEN discount_percent < 20 THEN discount_percent
                    ELSE discount_percent
                END
        ) AS product_rank,

        COUNT(*) OVER (
            PARTITION BY
                CASE
                    WHEN discount_percent = 0 THEN 'No Discount'
                    WHEN discount_percent >= 40 THEN 'High Discount (40-100%)'
                    WHEN discount_percent < 20 THEN 'Low Discount (1-19%)'
                    ELSE 'Medium Discount (20-39%)'
                END
        ) AS tier_total

    FROM nykaa_products
),

total_products AS (
    SELECT COUNT(*) AS total_products
    FROM nykaa_products
)

SELECT
    dc.discount_tier,
    dc.tier_total,
    ROUND(dc.tier_total * 100.0 / tp.total_products, 2) AS tier_share_percent,
    dc.product_name,
    dc.original_price,
    dc.discounted_price,
    dc.discount_percent
FROM discount_category dc
CROSS JOIN total_products tp
WHERE dc.product_rank <= 10
ORDER BY
    CASE dc.discount_tier
        WHEN 'High Discount (40-100%)' THEN 1
        WHEN 'Medium Discount (20-39%)' THEN 2
        WHEN 'Low Discount (1-19%)' THEN 3
        ELSE 4
    END,
    dc.product_rank;
 
-- Key Observations:
-- Low discounts (1–19%) are the most common pricing strategy, accounting for 42.36% of all products.
-- Approximately 27.04% of products are listed without a discount.
-- Medium discounts (20–39%) account for 25.42% of the catalog, while high discounts (40% and above) represent only 5.18%.
-- The maximum discount observed in the dataset is 83%, indicating that very high discounts exist but are limited to a small proportion of products.
-- Discount values represent the pricing observed at the time of data collection and may change during promotional campaigns or seasonal sales.
 
-- =====================================================
-- IV. Rating analysis
-- =====================================================

-- Business Question:
-- 1. How do customer ratings differ among brands?

-- Purpose:
-- Compare rating tiers across brands and identify brands with higher proportions of highly, moderately, and low-rated products.

-- Assumptions:

/*
1. Only products with more than 100 customer ratings are included.
2. The analysis therefore focuses on products with a relatively larger volume of customer feedback.
3. Product ratings are based on the rounded star ratings displayed on the Nykaa listing page. Since exact decimal ratings from individual product pages were not scraped, products are classified using the displayed star ratings.
4. Products are classified into:
   - High: 4.0–5.0 stars
   - Medium: 2.0–3.9 stars
   - Low: below 2.0 stars
*/


WITH brand_rating AS (
	SELECT
		brand,
        COUNT(*) 
			OVER( 
				PARTITION BY brand
				) AS eligible_products,
		product_key,
		product_name,
		rating_out_of_5,
		rating_count,
		CASE 
			WHEN rating_out_of_5 >=4 THEN 'Highly rated(4-5)'
			WHEN rating_out_of_5 <2 THEN 'Low rated(0-1.9)'
			ELSE 'Medium_rated(2-3.9)'
		END AS rating_tier
		
FROM nykaa_products
WHERE rating_count > 100
	)
SELECT
	brand,
    MAX(eligible_products) AS eligible_products,
    rating_tier,
    COUNT(*) AS total_tier_products,
    ROUND(
        COUNT(*) * 100.0 / MAX(eligible_products),
        2
    ) AS tier_percentage
FROM brand_rating
GROUP BY
    brand,
    rating_tier;

-- Key Observations:

-- Most eligible products fall into the 4–5 star category across almost all brands. 
-- Since the scraped dataset contains only the rounded star ratings displayed on the listing page (rather than precise decimal ratings), the rating variable provides limited differentiation between brands.
-- Therefore, rating count provides a more useful measure of customer engagement than the rounded star rating for this dataset.




-- Business Question:
-- 2. How does customer engagement vary across brands?

-- Purpose:
-- Compare customer engagement across brands using total rating count, average ratings per product, and product assortment.

SELECT
    brand,
    COUNT(*) AS total_products,
    SUM(rating_count) AS total_reviews,
    ROUND(AVG(rating_count),0) AS avg_reviews_per_product
FROM nykaa_products
WHERE brand <> 'Unknown'
GROUP BY brand
HAVING COUNT(*) >= 20
ORDER BY avg_reviews_per_product DESC;

-- Key Observtions:
-- Elle 18 records the highest average rating count per product in the filtered brand set, followed by Maybelline New York and Nykaa Cosmetics.
-- Nykaa Cosmetics not only has the largest product assortment on the platform but also accumulates the highest total review count, suggesting that its private-label products enjoy both broad availability and strong customer engagement.
-- Several established mass-market brands, including Maybelline New York, Lakme, POND'S, Faces Canada, Neutrogena, and Kay Beauty, also rank highly by average rating count per product.
-- Several brands with large product assortments, including Vaadi Herbals, Makeup Revolution, Nat Habit, and Shills Professional, receive comparatively lower average reviews per product. This suggests that a larger catalog does not necessarily translate into higher customer engagement.
-- Overall, the results show that product assortment size does not necessarily correspond to higher average rating counts per product.

-- Note: Rating count is used as a proxy for customer engagement and reflects the cumulative number of customer ratings available at the time of data collection. It should not be interpreted as a direct measure of sales volume or market share.


-- Business Question: 
-- 3. Which categories generate the highest customer engagement?

SELECT 
	category,
    SUM(rating_count) AS total_rating_count
FROM 
	nykaa_products
GROUP BY 
	category
ORDER BY 
	total_rating_count DESC
;


-- Key Observations:

-- Skin Care has the highest total rating count, with more than 261 million ratings, making it the category with the highest observed customer engagement proxy in the dataset.
-- Lip Makeup, Nail Makeup, and Face Makeup follow Skin Care in total customer engagement, indicating strong customer interest in makeup products.
-- Categories with larger product assortments generally tend to have higher total rating counts, although this comparison does not measure the relationship statistically.


-- Business Question:
-- Which subcategories have the highest customer engagement based on total rating count?

SELECT 
	sub_category,
    SUM(rating_count) AS total_rating_count
FROM 
	nykaa_products
WHERE 
	sub_category <> "Combo"
GROUP BY 
	sub_category
ORDER BY 
	total_rating_count DESC
;

-- Key Observations:
-- Face Masks have the highest total rating count, with more than 167 million customer ratings, making them the leading subcategory by the customer engagement proxy used in this analysis.
-- Nail Polish and Lipstick rank second and third, followed by Liquid Lipstick and Foundation, indicating strong customer engagement across several color-cosmetics subcategories.
-- Everyday skincare products such as Face Wash, Face Moisturizer, and Face Sunscreen also record substantial rating volumes.
-- Haircare essentials, particularly Shampoo, show higher rating volumes than several other haircare subcategories.
-- Specialized products such as Eye Primer, Lip Plumper, Bath Salts, Hand & Foot Masks, and Eyeshadow have comparatively lower total rating counts.
-- Face Masks do not necessarily have the largest product assortment, suggesting that total customer engagement is not determined solely by the number of products available.