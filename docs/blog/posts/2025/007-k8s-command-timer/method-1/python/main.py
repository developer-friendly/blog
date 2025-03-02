import http.client
import os
import socket
import time
import urllib.parse


def get_hostname():
    try:
        return socket.gethostname()
    except:
        return "unknown"


def init_defaults():
    global PUSHGATEWAY_URL, JOB_NAME, INSTANCE_NAME

    PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "http://localhost:9091")
    JOB_NAME = os.getenv("JOB_NAME", "my_job")
    INSTANCE_NAME = os.getenv("INSTANCE_NAME", get_hostname())


def the_main_job():
    time.sleep(1)


def main():
    init_defaults()

    print("Starting the job...")
    start_time = time.time()

    the_main_job()

    duration = time.time() - start_time

    print("Job execution finished, push the metrics...")

    url = urllib.parse.urlparse(PUSHGATEWAY_URL)
    push_path = f"/metrics/job/{JOB_NAME}/instance/{INSTANCE_NAME}/lang/python"

    payload = f"""
# TYPE job_duration_seconds gauge
# HELP job_duration_seconds Duration of the job in seconds
job_duration_seconds {duration}
"""

    try:
        if url.scheme == "https":
            conn = http.client.HTTPSConnection(url.netloc)
        else:
            conn = http.client.HTTPConnection(url.netloc)

        headers = {"Content-Type": "text/plain"}
        conn.request("POST", push_path, payload, headers)

        response = conn.getresponse()
        if response.status < 400:
            print(f"Execution time pushed successfully: {duration}")
        else:
            print(f"Error pushing metrics: {response.status} {response.reason}")

    except Exception as e:
        print(f"Error pushing to Pushgateway: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
