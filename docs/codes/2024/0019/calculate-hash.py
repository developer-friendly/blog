# -*- coding: utf-8 -*-
import hashlib
import subprocess


def caclculate_directory_hash(directory) -> str:
    output = subprocess.check_output(
        ["find", directory, "-type", "f", "-exec", "sha256sum", "{}", ";"],
    )
    return hashlib.sha256(output).hexdigest()
