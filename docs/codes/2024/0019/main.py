# -*- coding: utf-8 -*-
import hashlib
import os
import subprocess
import sys

import redis

REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
REDIS_SSL = os.getenv("REDIS_SSL", "false") == "true"


def caclculate_directory_hash(directory) -> str:
    output = subprocess.check_output(
        ["find", directory, "-type", "f", "-exec", "sha256sum", "{}", ";"],
    )
    return hashlib.sha256(output).hexdigest()


def calculate_all_hashes(app_root_path) -> dict:
    applications = []
    for app_dir in os.scandir(app_root_path):
        if app_dir.is_dir():
            applications.append(app_dir.path)

    directory_hashes = {}

    for app_dir in applications:
        directory_hashes[app_dir] = caclculate_directory_hash(app_dir)

    return directory_hashes


def get_current_app_hashes(store: redis.Redis, store_key: str) -> dict:
    return store.hgetall(store_key)


def compare_hashes(old_hashes: dict, new_hashes: dict) -> list[str]:
    changed_apps = []
    for app, new_hash in new_hashes.items():
        if old_hashes.get(app) != new_hash:
            changed_apps.append(app)
    return changed_apps


def mark_changes(store: redis.Redis, new_hashes: dict, store_key: str):
    old_hashes = get_current_app_hashes(store, store_key)
    changed_apps = compare_hashes(old_hashes, new_hashes)
    return changed_apps


def github_output(changed_apps: list[str]):
    num_changed_apps = len(changed_apps)

    github_output_file = os.environ["GITHUB_OUTPUT"]

    with open(github_output_file, "a") as f:
        f.write(f"apps={changed_apps}\n")
        f.write(f"length={num_changed_apps}\n")


def write_changed_hashes(store: redis.Redis, new_hashes: dict, store_key: str):
    store.delete(store_key)
    store.hmset(store_key, new_hashes)


if __name__ == "__main__":
    store = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        password=REDIS_PASSWORD,
        ssl=REDIS_SSL,
    )
    store_key = "app_hashes"

    if len(sys.argv) > 2:
        app_root_path = sys.argv[2]
    else:
        app_root_path = "."

    new_hashes = calculate_all_hashes(app_root_path)
    changed_apps = mark_changes(store, new_hashes, store_key)

    match sys.argv[1]:
        case "mark":
            github_output(changed_apps)
        case "submit":
            write_changed_hashes(store, new_hashes, store_key)
        case default:
            raise ValueError(f"Unknown action: {sys.argv[1]}")
