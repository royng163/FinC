# FinC - Financial Management App
A cross-platform expense tracking application built with Flutter and Firebase, featuring multi-currency support and data synchronization.

<div align="center">
  <div style="display: inline-block; text-align: center; margin: 0 10px;">
    <img src="assets/screenshots/home_page.png" width="300" alt="Home Page">
    <br>
    <em>Home Page with accounts summary</em>
  </div>
  <div style="display: inline-block; text-align: center; margin: 0 10px;">
    <img src="assets/screenshots/account_page.png" width="300" alt="Account Page">
    <br>
    <em>Account Page with individual summary</em>
  </div>
  <div style="display: inline-block; text-align: center; margin: 0 10px;">
    <img src="assets/screenshots/edit_transaction_page.png" width="300" alt="Edit Transaction Page">
    <br>
    <em>Edit transaction page</em>
  </div>
</div>

## Key Features
- **Financial Tracking**: Manage expenses, income, and transfers between accounts
- **Multi-Currency Support**: Handle transactions in different currencies via CoinGecko API
- **Cross-Device Sync**: Seamless synchronization across devices with offline capability
- **Modern UI/UX**: Material 3 design with dark/light theme support and responsive layout
- **Data Visualization**: Financial summaries and transaction history

## Tech Stack
- **Frontend**: Flutter
- **Backend**: Firebase (Authentication and more), CoinGecko API for currency exchange rates
- **Storage**: Hive(local caching), Firestore(data syncing)
