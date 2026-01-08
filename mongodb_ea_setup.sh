#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/.env"

# Your names
CONTAINER_NAME="${CONTAINER_NAME:-mongodb-ea}"
REPLSET="${REPLSET:-rs0}"

log() { printf "\n==> %s\n" "$*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }
}

need docker

log "Checking container is running: $CONTAINER_NAME"
docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME" || {
  echo "Container '$CONTAINER_NAME' is not running. Start it first." >&2
  echo "Hint: docker start $CONTAINER_NAME" >&2
  exit 1
}

# Run mongosh inside the container
mongosh_in() {
  docker exec -i "$CONTAINER_NAME" mongosh "$@"
}

log "Waiting for mongod to accept connections..."
for i in {1..75}; do
  if mongosh_in --quiet \
    "mongodb://127.0.0.1:27017/admin" \
    -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PWD" \
    --authenticationDatabase admin \
    --eval 'db.runCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    echo "MongoDB is up."
    break
  fi
  sleep 1
  if [[ "$i" == "75" ]]; then
    echo "MongoDB did not become ready in time." >&2
    exit 1
  fi
done

log "Ensuring replica set '$REPLSET' is initialized (idempotent)..."
mongosh_in --quiet \
  "mongodb://127.0.0.1:27017/admin" \
  -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PWD" \
  --authenticationDatabase admin <<'JS'
try {
  const st = rs.status()
  if (st.ok === 1) {
    print("Replica set already initialized.")
  }
} catch (e) {
  print("Initializing replica set...")
  rs.initiate({ _id: "rs0", members: [{ _id: 0, host: "localhost:27017" }] })

  // Wait until PRIMARY
  for (let i = 0; i < 60; i++) {
    try {
      const s = rs.status()
      const me = s.members.find(m => m.self)
      if (me && me.stateStr === "PRIMARY") {
        print("Replica set is PRIMARY.")
        break
      }
    } catch (_) {}
    sleep(1000)
    if (i === 59) throw new Error("Replica set did not reach PRIMARY in time.")
  }
}
JS

log "Creating scoped users (idempotent)..."
mongosh_in --quiet \
  "mongodb://127.0.0.1:27017/admin?replicaSet=$REPLSET" \
  -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PWD" \
  --authenticationDatabase admin \
  --eval '
const demoDb = "'"$DEMO_DB"'";

function ensureUser(user, pwd, roles) {
  const existing = db.getUser(user);
  if (existing) {
    print(`User already exists: ${user}`);
    return;
  }
  print(`Creating user: ${user}`);
  db.createUser({ user, pwd, roles });
}

ensureUser("'"$DEMO_DBADMIN_USER"'", "'"$DEMO_DBADMIN_PWD"'", [
  { role: "dbAdmin", db: demoDb },
  { role: "readWrite", db: demoDb }
]);

ensureUser("'"$DEMO_POWER_USER"'", "'"$DEMO_POWER_PWD"'", [
  { role: "readWrite", db: demoDb }
]);
'

log "Seeding demo data (idempotent if already seeded)..."
mongosh_in --quiet \
  "mongodb://127.0.0.1:27017/$DEMO_DB?replicaSet=$REPLSET" \
  -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PWD" \
  --authenticationDatabase admin <<'JS'
const demo = db;

function seeded() {
  try {
    return demo.products.estimatedDocumentCount() > 0 &&
           demo.customers.estimatedDocumentCount() > 0 &&
           demo.orders.estimatedDocumentCount() > 0;
  } catch (e) {
    return false;
  }
}

if (seeded()) {
  print("Demo data already present. Skipping seed.")
} else {
  print("Seeding customers/products/orders...");

  demo.customers.drop();
  demo.products.drop();
  demo.orders.drop();

  demo.customers.insertMany([
    { _id: ObjectId(), name: "Acme Telecom", tier: "enterprise", region: "US", createdAt: new Date() },
    { _id: ObjectId(), name: "Northwind Retail", tier: "midmarket", region: "US", createdAt: new Date() },
    { _id: ObjectId(), name: "Globex Labs", tier: "startup", region: "EU", createdAt: new Date() }
  ]);

  const customers = demo.customers.find().toArray();

  const categories = ["networking", "storage", "compute", "observability", "security"];
  const tags = ["edge", "5g", "ai", "k8s", "backup", "ssd", "nvme", "fiber", "zero-trust", "metrics"];

  const products = [];
  for (let i = 1; i <= 75; i++) {
    products.push({
      _id: ObjectId(),
      sku: `GAD-${String(i).padStart(4, "0")}`,
      name: `Demo Gadget ${i}`,
      category: categories[i % categories.length],
      price: Math.round((49 + (i * 3.25)) * 100) / 100,
      rating: Math.round(((i % 5) + 1) * 10) / 10,
      inStock: (i % 7) !== 0,
      tags: [tags[i % tags.length], tags[(i + 3) % tags.length]],
      createdAt: new Date(Date.now() - (i * 86400000))
    });
  }
  demo.products.insertMany(products);

  const statuses = ["new", "paid", "shipped", "delivered", "returned"];
  const prodList = demo.products.find({}, { _id: 1, sku: 1, price: 1 }).toArray();

  const orders = [];
  for (let i = 1; i <= 120; i++) {
    const c = customers[i % customers.length];
    const a = prodList[i % prodList.length];
    const b = prodList[(i + 11) % prodList.length];

    const qtyA = (i % 3) + 1;
    const qtyB = ((i + 1) % 2) + 1;
    const total = Math.round(((a.price * qtyA) + (b.price * qtyB)) * 100) / 100;

    orders.push({
      _id: ObjectId(),
      customerId: c._id,
      status: statuses[i % statuses.length],
      items: [
        { sku: a.sku, qty: qtyA, unitPrice: a.price },
        { sku: b.sku, qty: qtyB, unitPrice: b.price }
      ],
      total,
      createdAt: new Date(Date.now() - (i * 3600000))
    });
  }
  demo.orders.insertMany(orders);

  print("Seed complete.");
}

print("Ensuring indexes...");
demo.products.createIndex({ sku: 1 }, { unique: true });
demo.products.createIndex({ category: 1, price: 1 });
demo.products.createIndex({ name: "text", category: "text", tags: "text" });

demo.orders.createIndex({ customerId: 1, createdAt: -1 });
demo.orders.createIndex({ status: 1, createdAt: -1 });

print("Setup complete.");
JS

log "Done."
log "Connect strings:"
echo "  Root admin: mongosh \"mongodb://localhost:27017/?replicaSet=$REPLSET\" -u \"$MONGO_ROOT_USER\" -p \"***\" --authenticationDatabase admin"
echo "  DB admin:   mongosh \"mongodb://localhost:27017/$DEMO_DB?replicaSet=$REPLSET\" -u \"$DEMO_DBADMIN_USER\" -p \"***\" --authenticationDatabase admin"
echo "  Power user: mongosh \"mongodb://localhost:27017/$DEMO_DB?replicaSet=$REPLSET\" -u \"$DEMO_POWER_USER\" -p \"***\" --authenticationDatabase admin"
