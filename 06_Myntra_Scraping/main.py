from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

import pandas as pd
import time

# Get scraping parameters from the user

url = input("Enter URL: ")
category = input("Enter Category: ")
subcategory = input("Enter Subcategory: ")
no_pages = int(input("Number of pages to scrape: "))

# Initialize Chrome WebDriver

driver = webdriver.Chrome()

products = []

# Scrape products from each page
driver.get(url)

wait = WebDriverWait(driver, 10)

for page in range(no_pages):

    print(f"\nScraping Page {page+1}")

    # Wait until products are visible
    wait.until(
        EC.presence_of_element_located(
            (By.CSS_SELECTOR, ".product-base h4.product-product")
        )
    )

    cards = driver.find_elements(
        By.CSS_SELECTOR,
        ".product-base"
    )

    print("Cards Found:", len(cards))

    for card in cards:

        product = {}

        # Product Name
        try:
            product["product_name"] = card.find_element(
                By.CSS_SELECTOR,
                "h4.product-product"
            ).get_attribute("textContent").strip()
        except:
            product["product_name"] = None

        # URL
        try:
            product["url"] = card.find_element(
                By.TAG_NAME,
                "a"
            ).get_attribute("href")
        except:
            product["url"] = None

        product["category"] = category
        product["sub_category"] = subcategory

        # Brand
        try:
            product["brand"] = card.find_element(
                By.CSS_SELECTOR,
                "h3.product-brand"
            ).text
        except:
            product["brand"] = None

        # Discounted Price & Original Price

        try:
            # Discounted product
            discounted = card.find_element(
                By.CSS_SELECTOR,
                "span.product-discountedPrice"
            ).text

            original = card.find_element(
                By.CSS_SELECTOR,
                "span.product-strike"
            ).text

            product["discounted_price"] = discounted
            product["original_price"] = original

        except:
            try:
                # Non-discounted product
                price = card.find_element(
                    By.CSS_SELECTOR,
                    "div.product-price span"
                ).text

                product["discounted_price"] = price
                product["original_price"] = price

            except:
                product["discounted_price"] = None
                product["original_price"] = None

        # Discount Percentage (Calculated)

        try:
            if product["original_price"] and product["discounted_price"]:

                original = float(
                    product["original_price"]
                    .replace("Rs.", "")
                    .replace(",", "")
                    .strip()
                )

                discounted = float(
                    product["discounted_price"]
                    .replace("Rs.", "")
                    .replace(",", "")
                    .strip()
                )

                discount = round(
                    ((original - discounted) / original) * 100,
                    1
                )

                product["discount_percent"] = discount

            else:
                product["discount_percent"] = None

        except:
            product["discount_percent"] = None

        # Rating
        try:
            product["rating_out_of_5"] = card.find_element(
                By.CSS_SELECTOR,
                "div.product-ratingsContainer > span"
            ).text
        except:
            product["rating_out_of_5"] = None

        # Rating Count
        try:
            product["rating_count"] = card.find_element(
                By.CSS_SELECTOR,
                "div.product-ratingsCount"
            ).get_attribute("textContent")
        except:
            product["rating_count"] = None

        product["platform"] = "Myntra"

        products.append(product)

    # Click Next (except after last page)
    if page != no_pages - 1:

        try:
            old_cards = cards[0]

            next_btn = wait.until(
                EC.element_to_be_clickable(
                    (By.CSS_SELECTOR, "li.pagination-next")
                )
            )

            driver.execute_script(
                "arguments[0].scrollIntoView();",
                next_btn
            )

            print("Clicking Next...")

            driver.execute_script("arguments[0].click();", next_btn)

            time.sleep(5)

            print(driver.current_url)

            # Wait until previous page disappears
            wait.until(
                EC.staleness_of(old_cards)
            )

        except Exception as e:
            print("No more pages found.")
            print(e)
            break

# Convert scraped products to a DataFrame

df = pd.DataFrame(products)

# Save scraped data to CSV

df.to_csv('myntra_listing.csv', mode='a', index=False, header=False)

driver.quit()