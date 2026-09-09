import pandas as pd
from brands import brand_mapping

# Load scraped Nykaa product data

df = pd.read_csv("nykaa_master.csv")

# Create brand extraction function

def extract_brand(product_name):

    product_name = str(product_name).strip().lower()

    for brand, aliases in brand_mapping.items():

        for alias in aliases:

            alias = alias.lower()

            if product_name.startswith(alias):
                return brand

    return "Unknown"

# Add brand column

df.insert(
    loc=4,
    column="brand",
    value=df["product_name"].apply(extract_brand)
)

# Clean numeric columns

df["discounted_price"] = df["discounted_price"].str.extract(r'(\d+)').astype(float)
df["original_price"] = df["original_price"].str.extract(r'(\d+)').astype(float)
df["discount_percent"] = df["discount_percent"].str.extract(r'(\d+)').astype(float)
df["reviews"] = (
    df["reviews"]
    .str.replace(",", "", regex=False)
    .str.extract(r'(\d+)')[0]
    .astype(float)
)
df["rating"] = (
    df["rating"]
    .str.extract(r'(\d+\.?\d*)')[0]
    .astype(float)
)

# Standardize column names and index

df = df.rename(columns={"rating": "rating_out_of_5"})

df = df.reset_index(drop=True)

# Save the final Nykaa listing dataset
df.to_csv("nykaa_listing.csv", index=False)

