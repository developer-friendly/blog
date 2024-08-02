# -*- coding: utf-8 -*-
import hashlib
import os
import subprocess


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
