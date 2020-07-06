CREATE TABLE "gd" (
  "id"  INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
  "fid" TEXT NOT NULL UNIQUE,
  "info"  TEXT,
  "summary" TEXT,
  "subf"  TEXT,
  "ctime" INTEGER,
  "mtime" INTEGER
);

CREATE UNIQUE INDEX "gd_fid" ON "gd" (
  "fid"
);

CREATE TABLE "task" (
  "id"  INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
  "source"  TEXT NOT NULL,
  "target"  TEXT NOT NULL,
  "status" TEXT,
  "copied"  TEXT DEFAULT '',
  "mapping" TEXT DEFAULT '',
  "ctime" INTEGER,
  "ftime" INTEGER
);

CREATE UNIQUE INDEX "task_source_target" ON "task" (
  "source",
  "target"
);

CREATE TABLE "copied" (
  "taskid"  INTEGER,
  "fileid"  TEXT
);

CREATE INDEX "copied_taskid" ON "copied" ("taskid");

CREATE TABLE "bookmark" (
  "alias"  TEXT,
  "target"  TEXT
);

CREATE UNIQUE INDEX "bookmark_alias" ON "bookmark" (
  "alias"
);
