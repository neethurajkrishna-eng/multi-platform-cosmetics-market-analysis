from selenium import webdriver
from selenium.webdriver.common.by import By
import pandas as pd
import time

# Get scraping parameters from the user

url_in = input('Enter url: ')
no_pages = int(input('Number of pages: '))
category = input('Enter Category: ')
subcategory = input('Enter Subcategory: ')

# Initialize Chrome WebDriver

driver = webdriver.Chrome()

products=[]

# Scrape products from each page

for page in range(1, no_pages+1):

    url = url_in.replace('page_no=2', f'page_no={page}')

    driver.get(url)

    time.sleep(5)

    cards = driver.find_elements(
        By.CSS_SELECTOR,
        "#product-list-wrap .productWrapper"
    )

    print("Cards Found:", len(cards))

    for card in cards:

        product = {}

        # Product Name
        try:
            product["product_name"] = card.find_element(
                By.TAG_NAME,
                "h2"
            ).text
        except:
            product["product_name"] = None

        # Product URL
        try:
            product["url"] = card.find_element(
                By.TAG_NAME,
                "a"
            ).get_attribute("href")
        except:
            product["url"] = None

        # Product Category
        product["category"] = category
        product["sub_category"] = subcategory

        # Discounted Price
        try:
            product["discounted_price"] = card.find_element(
                By.CSS_SELECTOR,
                "span.css-111z9ua"
            ).text
        except:
            product["discounted_price"] = None

        # Original Price
        try:
            product["original_price"] = card.find_element(
                By.CSS_SELECTOR,
                "span.css-17x46n5 span"
            ).text
        except:
            product["original_price"] = None

        # Discount %
        try:
            product["discount_percent"] = card.find_element(
                By.CSS_SELECTOR,
                "span.css-cjd9an"
            ).text
        except:
            product["discount_percent"] = None

        # Rating
        try:
            product["rating"] = card.find_element(
                By.CSS_SELECTOR,
                "[aria-label*='star rating']"
            ).get_attribute("aria-label")
        except:
            product["rating"] = None

        # Reviews
        try:
            product["reviews"] = card.find_element(
                By.CSS_SELECTOR,
                "span[aria-label*='reviews']"
            ).get_attribute("aria-label")
        except:
            product["reviews"] = None

        product["platform"] = "Nykaa"

        products.append(product)

# Convert scraped products to a DataFrame

df = pd.DataFrame(products)

print(df.head())

# Save scraped data to CSV

df.to_csv('nykaa_master.csv', mode='a', index=False, header=False)

driver.quit()