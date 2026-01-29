# NOTU - A Minimalist Note-Taking App

## Overview

NOTU is a minimalist note-taking application designed for simplicity and ease of use. It allows users to create and organize their notes into books and chapters, with support for both Markdown and HTML content. The app features a clean, modern interface with a focus on readability and a distraction-free writing experience.

## Features

### Core Functionality

*   **Book and Chapter Organization:** Users can create books to group their notes and add chapters within each book.
*   **Markdown and HTML Support:** Chapters can be written in either Markdown or HTML, providing flexibility for different types of content.
*   **Rich Text Editing:** The app includes a rich text editor for a seamless writing experience.
*   **Image Support:** Users can add images to their notes.
*   **Local Storage:** All data is stored locally on the device for privacy and offline access.
*   **Todo List:** Users can create and manage a simple to-do list.

### Design and Theming

*   **Minimalist UI:** The user interface is designed to be clean and intuitive, with a focus on content.
*   **Light and Dark Themes:** The app includes both light and dark themes to suit user preferences.
*   **Customizable Fonts:** Users can choose from a selection of fonts to personalize their reading experience.

### Import and Export

*   **Book Export:** Users can export individual books as JSON files, including all chapters and content.
*   **Book Import:** Users can import books from JSON files, allowing for easy backup and sharing.
*   **PDF Export:** Chapters can be saved as PDF files for printing or sharing.
*   **Printing:** Chapters can be printed directly from the app.

## Current Plan

This is the first version of the application, and the following features have been implemented:

*   Created the basic project structure.
*   Implemented the main screen with a grid view of books.
*   Added the ability to add, edit, and delete books.
*   Implemented the book details screen with a list of chapters.
*   Added the ability to add, edit, and delete chapters.
*   Implemented the chapter details screen with support for Markdown and HTML content.
*   Added a settings screen with a theme toggle.
*   Implemented book import and export functionality.
*   Implemented chapter PDF export and printing.
*   Added a to-do list feature with search functionality.

## Troubleshooting and Solutions

This section documents issues encountered and the solutions implemented to resolve them.

### 1. Backup/Export/Import/Restore Failures

*   **Problem:** The backup, export, import, and restore functionalities were failing due to a combination of issues related to modern Android security features, platform-specific file handling, and incorrect database ID management.
*   **Solution:**
    1.  **Scoped Storage Compatibility:** Replaced the outdated file-saving logic with `FilePicker.platform.saveFile()`. This method uses the system's file picker, which respects platform-specific permissions and allows the user to choose the save location.
    2.  **Platform-Specific File Reading:** Implemented platform-aware logic using `kIsWeb` to handle file reading. For web, the file is read from memory (`result.files.single.bytes`). For mobile (Android/iOS), the file is read from the path provided by the file picker (`File(result.files.single.path!).readAsString()`).
    3.  **Database ID Management:** Modified the import and restore logic to treat imported data as new entries. Instead of using the IDs from the backup file, the app now removes the old IDs and lets the database assign new, auto-incremented IDs. A map is used to maintain the relationship between the old and new book IDs, ensuring that chapters are correctly associated with their parent books.

### 2. Home Screen Not Refreshing After Restore

*   **Problem:** After restoring a backup from the settings screen, the home screen did not automatically update to display the restored books.
*   **Solution:** Modified the navigation to the settings screen to be an `async` operation. By using `await Navigator.push(...)`, the app now waits for the settings screen to be closed. After it's closed, a function is called to refresh the book list from the database, which updates the UI.
