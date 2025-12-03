import os
import json
import re

class ProductCleaningPipeline:
#made it so it only cleans the 6 products i need
    PRODUCT_RULES = [
        {
            "name": "full cream long life milk 6 x 1l",
            "keywords": ["milk", "full", "cream", "6", "1l"],
            "file": "cleaned_grocery.json",
            "category": "grocery"
        },
        {
            "name": "eggs 30 pack",
            "keywords": ["eggs", "30"],
            "file": "cleaned_grocery.json",
            "category": "grocery"
        },
        {
            "name": "grandpa 38 pack",
            "keywords": ["grandpa", "38"],
            "file": "cleaned_healthwellness.json",
            "category": "healthwellness"
        },
        {
            "name": "calpol strawberry flavour 100ml",
            "keywords": ["calpol", "strawberry", "100"],
            "file": "cleaned_healthwellness.json",
            "category": "healthwellness"
        },
        {
            "name": "colgate triple action 100ml",
            "keywords": ["colgate", "100"],
            "file": "cleaned_personalcare.json",
            "category": "personalcare"
        },
        {
            "name": "dettol antiseptic liquid 750ml",
            "keywords": ["dettol", "750"],
            "file": "cleaned_personalcare.json",
            "category": "personalcare"
        },
    ]
    def __init__(self):
        self.files = {}
        self.seen = set()

    def normalize(self, text):
        """Lowercase + remove symbols for consistent matching."""
        return re.sub(r"[^a-z0-9 ]+", "", text.lower()).strip()

    def matches_rule(self, normalized_name, rule):
        """Match if all required keywords exist in the product name."""
        return all(k in normalized_name for k in rule["keywords"])

    def open_spider(self, spider):
        out_folder = os.path.join(os.path.dirname(__file__), "cleaned")
        os.makedirs(out_folder, exist_ok=True)

        for fname in [
            "cleaned_grocery.json",
            "cleaned_personalcare.json",
            "cleaned_healthwellness.json"
        ]:
            f = open(os.path.join(out_folder, fname), "w", encoding="utf-8")
            f.write("[")
            self.files[fname] = {"file": f, "first": True}

    def close_spider(self, spider):
        for info in self.files.values():
            info["file"].write("]")
            info["file"].close()
        spider.logger.info("Cleaning complete.")

    def format_item(self, item, rule):
        """Format fields exactly as your DB requires (WITH URL FIXES)."""

        name = item.get("name", "")
        price = item.get("price", "")

        # Shoprite fields
        img = item.get("image_url", item.get("image", ""))
        url = item.get("product_url", item.get("url", ""))

        # Fix price
        if price and not price.startswith("R"):
            price = "R" + price
        # Fix image URL
        if img:
            img = img.strip()

            # Relative path → add Shoprite domain
            if img.startswith("/"):
                img = "https://www.shoprite.co.za" + img

            elif img.startswith("//"):       #fix for missing http:
                img = "https:" + img

            elif not img.startswith(("http://", "https://")):
                img = "https://" + img
        if url:              #fix product url
            url = url.strip()

            if url.startswith("/"):
                url = "https://www.shoprite.co.za" + url

            elif url.startswith("//"):
                url = "https:" + url

            elif not url.startswith(("http://", "https://")):
                url = "https://" + url

        return {
            "productName": name,
            "price": price,
            "productImageURL": img,
            "productURL": url,
            "category": rule["category"]
        }
    def process_item(self, item, spider):
        normalized_name = self.normalize(item.get("name", ""))

        matched_rule = None
        for rule in self.PRODUCT_RULES:
            if self.matches_rule(normalized_name, rule):
                matched_rule = rule
                break
        if not matched_rule: #made this to skips products of the 6 i need
            return item

        if normalized_name in self.seen: # this removes duplicates
            return item
        self.seen.add(normalized_name)

        info = self.files[matched_rule["file"]] #this function is supposed to send the cleaned item to the correct file

        if not info["first"]:
            info["file"].write(",\n")
        else:
            info["first"] = False

        cleaned = self.format_item(item, matched_rule)
        json.dump(cleaned, info["file"], ensure_ascii=False, indent=4)

        return item
