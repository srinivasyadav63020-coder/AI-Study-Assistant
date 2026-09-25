# 🤖 AI Study Assistant

> An AI-powered Flutter application designed to help students organize their
> learning, create notes, generate quizzes, plan their studies, and track
> quiz performance in one place.

---

## 📌 Overview

AI Study Assistant is a student-focused mobile application developed using
Flutter and Dart.

The application combines AI-assisted learning with productivity features
such as notes, study planning, quiz generation, and quiz history.

The main goal of the project is to provide students with a single platform
where they can:

- Ask AI-based study questions
- Create and manage study notes
- Generate practice quizzes
- Track quiz performance
- Create study plans
- Store study data locally
- Review previous quiz attempts

---

## 🎯 Problem Statement

Students often use multiple applications for studying, taking notes,
planning their study schedule, and practicing questions.

This project aims to bring these activities together into one
student-friendly application.

### Existing Challenges

- Students switch between multiple study applications.
- Creating practice questions manually takes time.
- Study notes can become difficult to organize.
- Students may not track their previous quiz performance.
- Study planning and learning activities are often separated.

### Proposed Solution

AI Study Assistant integrates AI-powered learning features with
notes, study planning, quizzes, and performance history in a single
Flutter application.

---

# ✨ Key Features

## 🤖 AI Study Assistant

The application provides AI-assisted learning functionality that allows
students to interact with an AI system for study-related queries.

Students can use the AI assistant to:

- Ask academic questions
- Get explanations
- Understand difficult concepts
- Receive study assistance
- Interact through a chat-based interface

---

## 📚 Notes Management

The Notes module allows students to create and manage their study notes.

### Features

- Create notes
- View saved notes
- Search notes
- Organize study information
- Store notes locally
- Access notes without requiring cloud storage

---

## 📝 AI Quiz Generator

The application includes an AI-powered quiz generation feature.

Students can generate practice questions based on their learning
requirements.

### Features

- Generate quizzes
- Answer multiple-choice questions
- Display correct/incorrect answers
- Calculate quiz scores
- Review quiz results

---

## 📊 Quiz History

The Quiz History module allows students to review their previous
quiz attempts.

It helps students track:

- Previous quizzes
- Scores
- Performance
- Quiz attempts
- Learning progress

---

## 📅 Study Planner

The Study Planner allows students to organize their study activities.

Students can create study tasks using information such as:

- Subject
- Topic
- Priority
- Completion status
- Created time
- Updated time

This helps students organize their daily learning activities.

---

## 💾 Local Data Storage

The application uses **Hive** for local data persistence.

Local storage is used for application data such as:

- Notes
- Planner tasks
- Quiz history
- Other locally required application data

This allows important study information to remain available when the
application is reopened.

---

# 🛠️ Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Material Design | User interface |
| Hive | Local data persistence |
| Gemini / Google AI | AI-assisted learning functionality |
| Android SDK | Android application development |
| Git | Version control |
| GitHub | Source code hosting |

---

# 🏗️ Application Architecture

The project follows a modular Flutter application structure.

```text
AI Study Assistant
│
├── AI Layer
│   └── AI Service
│
├── Presentation Layer
│   ├── Chat Screen
│   ├── Notes Screen
│   ├── Planner Screen
│   ├── Quiz Screen
│   └── Quiz History Screen
│
├── Data Layer
│   └── Database / Hive
│
└── Application Entry Point
    └── main.dart

🔄 Application Flow 

                        ┌─────────────────────┐
                    │   AI Study Assistant │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        ┌──────────┐      ┌──────────┐    ┌──────────┐
        │ AI Chat  │      │  Notes   │    │ Planner  │
        └────┬─────┘      └────┬─────┘    └────┬─────┘
             │                 │               │
             ▼                 ▼               ▼
        AI Assistance      Local Storage    Study Tasks
             │
             ▼
       ┌──────────────┐
       │ Quiz Generator│
       └───────┬──────┘
               │
               ▼
        ┌──────────────┐
        │ Quiz History │
        └──────────────┘