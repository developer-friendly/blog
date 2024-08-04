import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import core from "@actions/core";
import { createClient } from "redis";

function calculateFileHash(filePath) {
  var fileBuffer = fs.readFileSync(filePath);
  var hashSum = createHash("sha256");
  hashSum.update(fileBuffer);
  return hashSum.digest("hex");
}

function* findFiles(directory) {
  var items = fs.readdirSync(directory);

  for (var item of items) {
    var fullPath = path.join(directory, item);
    if (fs.statSync(fullPath).isDirectory()) {
      yield* findFiles(fullPath);
    } else {
      yield fullPath;
    }
  }
}

function calculateDirectoryHash(directory) {
  var hashSum = createHash("sha256");

  for (var file of findFiles(directory)) {
    var fileHash = calculateFileHash(file);
    hashSum.update(fileHash);
  }

  return hashSum.digest("hex");
}

function calculateAllHashes(appRootPath) {
  var applications = fs.readdirSync(appRootPath).filter(function isDir(file) {
    return fs.statSync(`${appRootPath}/${file}`).isDirectory();
  });

  var directoryHashes = {};

  applications.forEach(function hashDir(appDir) {
    var rootPath = appRootPath.replace(/\/$/, "");
    directoryHashes[`${rootPath}/${appDir}`] = calculateDirectoryHash(
      `${rootPath}/${appDir}`
    );
  });

  return directoryHashes;
}

async function getCurrentAppHashes(store, storeKey) {
  return await store.hGetAll(storeKey);
}

function compareHashes(oldHashes, newHashes) {
  if (!oldHashes) {
    return Object.keys(newHashes);
  }

  var changedApps = [];
  for (var app in newHashes) {
    if (!oldHashes[app] || oldHashes[app] != newHashes[app]) {
      changedApps.push(app);
    }
  }
  return changedApps;
}

async function markChanges(store, newHashes, storeKey) {
  var oldHashes = await getCurrentAppHashes(store, storeKey);
  return compareHashes(oldHashes, newHashes);
}

function githubOutput(changedApps) {
  var numChangedApps = changedApps.length;

  var stringifyApps = JSON.stringify({ directory: changedApps });

  core.info(`Changed apps: ${stringifyApps}`);
  core.info(`Number of changed apps: ${numChangedApps}`);

  // e.g. matrix: '{"directory": ["./auth"]}'
  core.setOutput("matrix", stringifyApps);
  // e.g. length: '1'
  core.setOutput("length", numChangedApps);
}

async function mark(store, newHashes, storeKey) {
  var changedApps = await markChanges(store, newHashes, storeKey);

  githubOutput(changedApps);
}

async function submit(store, newHashes, storeKey) {
  await store.hSet(storeKey, newHashes);
}

try {
  var host = core.getInput("redis-host");
  var port = core.getInput("redis-port");
  var password = core.getInput("redis-password");
  var tls = core.getBooleanInput("redis-ssl");
  var mode = core.getInput("mode");
  var appRootPath = core.getInput("path");
  var exclusions = core.getMultilineInput("exclusions");
  var storeKey = core.getInput("store-key");

  core.info(`Mode: ${mode}`);
  core.info(`App root path: ${appRootPath}`);
  core.info(`Exclusions: ${exclusions}`);
  core.info(`Store key: ${storeKey}`);

  var store = createClient({
    username: "default",
    password,
    socket: {
      host,
      port,
      tls,
    },
  });
  await store.connect();
  var ping = await store.ping();

  core.info(`Redis ping: ${ping}`);

  var newHashes = calculateAllHashes(appRootPath);

  core.info(`New hashes: ${JSON.stringify(newHashes)}`);

  newHashes = Object.fromEntries(
    Object.entries(newHashes).filter(function getInclusions([key]) {
      return !exclusions.some(function isExcluded(exclusion) {
        return key.includes(exclusion);
      });
    })
  );

  core.info(`New hashes after exclusions: ${JSON.stringify(newHashes)}`);

  if (mode == "mark") {
    await mark(store, newHashes, storeKey);
  } else if (mode == "submit") {
    await submit(store, newHashes, storeKey);
  }
} catch (error) {
  core.setFailed(error.message);
  core.setFailed(error.stack);
} finally {
  await store.quit();
}
