import { DatabaseSync } from 'node:sqlite';

const database = new DatabaseSync("/app/config/db/db.sqlite3");
const backup = database.prepare("VACUUM INTO '/app/config/db/db.backup.sqlite3'");
backup.run();
