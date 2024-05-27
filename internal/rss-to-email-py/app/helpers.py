# -*- coding: utf-8 -*-

from datetime import datetime, timedelta


def next_monday():
    today = datetime.now()
    if today.weekday() != 0:
        next_monday = today + timedelta(days=(7 - today.weekday()))
    else:
        next_monday = today
    send_at = next_monday.replace(hour=8, minute=0, second=0)

    return send_at
