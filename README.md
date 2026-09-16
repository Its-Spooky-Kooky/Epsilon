# Epsilon ⏱️

A distraction-free, minimalist mobile reminder application built on a modular plugin architecture.

---

## 📌 Concept
Epsilon aggregates event streams into a unified, distraction-free timeline powered by modular **Plugins**.

- **Core Navigation**:
  - **Home**: Active plugins, upcoming countdown, and aggregated 3-week event timeline.
  - **Plugins Marketplace**: Discover, download, configure, and toggle plugins.
- **Initial Plugin**: **Competitive Programming (CP) Contest Plugin** (LeetCode, Codeforces, CodeChef, AtCoder).
- **Future Plugins**: Hackathons (Unstop, Devpost, Devfolio), Academic Schedules, Tech Meetups.

---

## ✨ Features
- **Modular Plugin Engine**: Extensible interface for event data providers.
- **Clean 2-Level Toggle Controls**:
  - **Platform-level toggle**: `LEETCODE [on/off]`, `CODEFORCES [on/off]`, `CODECHEF [on/off]`, etc.
  - **Series-level toggle**: `WEEKLY CONTEST [on/off]`, `BIWEEKLY CONTEST [on/off]`, `Div. 2 [on/off]`, etc. (controls reminders for all upcoming instances of that series). No individual contest clutter.
- **3-Week Horizon**: Fetches schedules 3 weeks in advance with automatic local caching.
- **Alarm & Notification System**: Exact alarms scheduled in advance for all active contests.
- **Native Calendar Sync**: One-tap synchronization with device calendars (Google / Apple Calendar).
- **Home Screen Widgets**: Compact widget support displaying the next upcoming contest countdown.

---

## 🛠️ Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Storage**: Hive / Isar
- **Alarms & Notifications**: `flutter_local_notifications` + `android_alarm_manager_plus`
- **Calendar**: `device_calendar`
- **Widgets**: `home_widget` (Android AppWidget / iOS WidgetKit)
- **API**: Kontests API (`kontests.net/api`)

---

## 🗺️ Roadmap
- [x] Architecture & Project Specification
- [x] Core App Shell & Two-Tab Navigation (Home & Plugins Store)
- [x] CP Contest Plugin (3-week fetch, series parser, clean 2-level toggles)
- [x] Exact Alarm Engine & Device Calendar Sync
- [x] Home Screen Widget Integration Service
- [ ] Hackathon Plugin (Unstop, Devpost, Devfolio)
