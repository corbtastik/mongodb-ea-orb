# MongoDB Enterprise Advanced on OrbStack

This repository demonstrates how to run **MongoDB Enterprise Advanced (EA)** locally on **OrbStack** using Docker, with a secure and persistent configuration that mirrors real-world setups.

The goal is not just “MongoDB in a container,” but a setup that supports:
- Authentication
- Replica set mode
- Enterprise security requirements
- Durable data across restarts

---

## What this repo gives you

- **MongoDB Enterprise Advanced 8.0**
- **Single-node replica set (`rs0`)**
  - Enables transactions and change streams
  - Matches production-style startup behavior
- **Persistent storage** via Docker named volumes
- **Replica set keyfile** for internal authentication
- **Multiple users for demos**
  - Root admin
  - Database admin (scoped)
  - Read/write application user
- **Idempotent scripts**
  - Safe to re-run without breaking state

---

## Files

- `.env`  
  Credentials, database name, and demo users.

- `mongodb_ea_run.sh`  
  Starts MongoDB Enterprise with:
  - Named volumes
  - Replica set flags
  - Keyfile-based internal authentication

- `mongodb_ea_setup.sh`  
  One-time (idempotent) initialization:
  - Replica set initiation
  - User creation
  - Demo data + indexes

---

## Why this setup matters

MongoDB behaves differently when:
- Authentication is enabled
- Replica sets are enabled
- Internal node authentication is required

This repo intentionally enables all three so you can:
- Observe real startup behavior
- Avoid common “why won’t MongoDB start?” errors
- Experiment locally with production-style constraints

---

## Getting started

Clone the repo, review `.env`, and follow the step-by-step walkthrough in the blog post:

👉 **Full tutorial:**  
**[MongoDB Enterprise on OrbStack – Complete Walkthrough](LINK_TO_YOUR_BLOG_POST)**

The post covers:
- Keyfile generation and permissions
- Replica set initialization
- User scoping
- Common failure modes and fixes

---

## Not production — but production-aware

This setup is intended for:
- Local experimentation
- Learning MongoDB Enterprise features
- Demos and workshops

It is **not** a replacement for Atlas or a production cluster — but it behaves closely enough to surface real-world MongoDB behaviors.

---

## License / Notes

MongoDB Enterprise Advanced requires a valid MongoDB license for production use.  
This repository is for educational and experimental purposes only.
