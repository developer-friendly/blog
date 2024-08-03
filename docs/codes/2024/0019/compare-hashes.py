# -*- coding: utf-8 -*-
import hashlib
import os
import subprocess

import redis


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
