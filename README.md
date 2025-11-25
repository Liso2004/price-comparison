🛒 Price Comparison App

The Price Comparison App allows users to search, compare, and analyze product prices across major South African retailers.
This repository contains the Flutter frontend, Node.js/Python backend, scraper pipeline, documentation, and infrastructure for the full end-to-end system.

📱 Frontend (Flutter)

Features:

Home page

Search functionality

Compare page

Product results

Location:
/frontend

🔧 Backend (Python)
FastAPI/ python API

Handles:

Product search

Price comparison logic

Retailer endpoints

API integration layer

Python Scraper

Retailer web scraping

Data cleaning + transformation

Safe scraping respecting robots.txt

ETL pipeline

Location:
/backend

📚 Documentation (/docs)

Includes:

Legal compliance (T&Cs, robots.txt audit)

Wireframes

User flows

Architecture diagrams

API specs

Sprint plans

Technical design docs

Location:
/docs

🏗 Infrastructure (/infrastructure)

GitHub Actions CI/CD


Location:
/infrastructure

Tech Stack
Frontend

Flutter (Dart)

Backend

FastAPI (python)

Python (Scraping engine)

MongoDB

Infrastructure

GitHub + GitHub Actions


CI/CD pipelines

Documentation
Slack board

Getting Started
Clone the repository
git clone
cd price-comparison

Install Dependencies
Frontend
cd frontend
flutter pub get

Scraper (Python)
cd backend/scraper
pip install -r requirements.txt

Running the Project
Start Flutter App
flutter run

Start Node.js API
cd backend
npm run dev

Run Python Scraper
cd backend/scraper
python main.py

 Git Workflow

We use a structured branching model:

Main Branches

main → production

dev → integration/test

feature/<ticket-name> → new features

bugfix/<ticket-name> → fixes

Rules

No direct pushes to main

All work must go through PR → dev

Sprint release = PR from dev → main

Legal Compliance

Project includes:

Terms & Conditions analysis

robots.txt restrictions

Ethical scraping guidelines

Final legal summary

See:
/docs/legal

📜 License

MIT License — or replace with your license of choice.

🤝 Contributing

Create a feature branch

Commit changes

Push to remote

Open a Pull Request

Request review

Merge into main 