# MongoDB Enterprise Advanced on OrbStack

This repository demonstrates how to run **MongoDB Enterprise Advanced (EA)** locally on **OrbStack** using Docker, with a secure and persistent configuration that mirrors real-world setups.

The goal is not just “MongoDB in a container,” but a setup that supports:
- Authentication
- Replica set mode
- Enterprise security requirements
- Durable data across restarts

---

## 📘 Helpful Links & Context

If you want the full background, rationale, and a guided walkthrough, start here:

- **Blog Post (Full Tutorial):**  
  https://corbs.io/posts/mongodb-ea-on-orbstack/

- **Author Blog:**  
  https://corbs.io

### Core Technologies
- **MongoDB:** https://www.mongodb.com  
- **MongoDB Enterprise Advanced:**  
  https://www.mongodb.com/products/enterprise-advanced
- **MongoDB Replica Sets:**  
  https://www.mongodb.com/docs/manual/replication/
- **MongoDB Security & Authentication:**  
  https://www.mongodb.com/docs/manual/core/security/

### Local Runtime & Tooling
- **OrbStack (Docker & Linux on macOS):**  
  https://orbstack.dev
- **Docker:**  
  https://www.docker.com
- **Docker Volumes:**  
  https://docs.docker.com/storage/volumes/

These resources help explain *why* this setup looks the way it does and how it maps to production MongoDB behavior.

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
**MongoDB Enterprise Advanced on OrbStack**  
https://corbs.io/posts/mongodb-ea-on-orbstack/

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

It is **not** a replacement for MongoDB Atlas or a production cluster — but it behaves closely enough to surface real-world MongoDB behaviors.

If you are looking for a managed production deployment, see:
- **MongoDB Atlas:** https://www.mongodb.com/atlas

---

## License / Notes

MongoDB Enterprise Advanced requires a valid MongoDB license for production use.  
This repository is for educational and experimental purposes only.
