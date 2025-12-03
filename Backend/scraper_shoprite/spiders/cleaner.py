import json
import scrapy
import os


class CleanerSpider(scrapy.Spider):
    name = "cleaner"

    def start_requests(self):
        raw_folder = os.path.join(os.path.dirname(__file__), "..", "raw_data")
        raw_folder = os.path.abspath(raw_folder)

        # Loop over all JSON files inside raw_data/
        for file in os.listdir(raw_folder):
            if file.endswith(".json"):
                path = os.path.join(raw_folder, file)
                yield scrapy.Request(
                    url=f"file:///{path.replace(os.sep, '/')}",
                    callback=self.parse,
                    cb_kwargs={"filename": file}
                )

    def parse(self, response, filename):
        data = json.loads(response.text)
        for entry in data:
            entry["source_file"] = filename
            yield entry
