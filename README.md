# Shopwise

A product price comparison app for four major South African retailers.
Built with Flutter (frontend), Python FastAPI (backend), and MongoDB (database).

## Overview

This app lets users compare product prices across multiple South African stores.
It includes four main pages:

### Home Page
- Search bar
- Quick search shortcuts
- Category cards that link to search results

### Search Page
- Search bar
- Filters
- "No result" error state
- Recommended product cards
- Displays product cards when a search is done

### Compare Page
- Shows side-by-side comparison of product prices from all retailers

### Settings Page
- About
- Legal information

## Installation

1. Clone git repo
```bash
git clone https://github.com/Liso2004/price-comparison.git
```

2. Create a virtual environment
```bash
python -m venv venv
venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run backend
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

5. Run frontend
```bash
flutter run
```