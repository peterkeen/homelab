import os
import requests
import datetime
import time
import re
import subprocess

from humanfriendly import parse_size
from pydantic import BaseModel
from typing import Optional
from bs4 import BeautifulSoup
from urllib.parse import urlparse, parse_qs
from pathlib import Path

class Node(BaseModel):
    name: str
    parent: Optional['Node'] = None

    def path(self):
        cur = self
        path_parts = []

        while cur is not None:
            path_parts.insert(0, cur.name)
            cur = cur.parent

        return "/".join(path_parts)

class File(Node):
    timestamp: datetime.datetime
    size: int
    download_key: str

class Directory(Node):
    children: Optional[list[Node]] = []

def parse_listing(parent_node, path):
    resp = requests.get(f"http://ezshare.card/dir?dir={path}")
    soup = BeautifulSoup(resp.text, 'html.parser')
    listing = soup.pre

    if listing is None:
        return

    children = listing.find_all('a')

    dir_by_name = {}
    file_by_name = {}
    for child in listing.find_all('a'):
        url = urlparse(child['href'])
        query = parse_qs(url.query)

        if "file" in query:
            file_by_name[child.text.strip()] = query["file"][0]
        else:
            dir_by_name[child.text.strip()] = query["dir"][0]

    lines = listing.text.split("\n")
    for line in lines:
        if len(line.strip()) == 0:
            continue

        line = line.strip().replace("- ", "-0").replace(": ", ":0")
        parts = re.split(r"\s+", line, maxsplit=4)

        if parts[0] == "Total":
            continue

        if parts[3] == "." or parts[3] == "..":
            continue

        date = datetime.datetime.strptime(parts[0], "%Y-%m-%d")
        hour, minute, second = parts[1].split(":")
        date = datetime.datetime(date.year, date.month, date.day, int(hour), int(minute), int(second))

        if parts[2] == "<DIR>":
            node = Directory(
                name=parts[3],
                parent=parent_node
            )
            parent_node.children.append(node)
            #print(f"DIR {parts[3]} {dir_by_name[parts[3]]} {node.path()}")

            parse_listing(node, dir_by_name[parts[3]])
        else:
            size = parse_size(parts[2])
            node = File(
                timestamp=date,
                parent=parent_node,
                name=parts[3],
                size=size,
                download_key=file_by_name[parts[3]]
            )
            parent_node.children.append(node)

def find_downloads(node, data_dir):
    to_download = []

    for child in node.children:
        if isinstance(child, Directory):
            to_download += find_downloads(child, data_dir)
        else:
            path = Path(os.path.join(data_dir, child.path()))
            if not path.exists():
                to_download.append(child)
                continue

            stat = os.stat(path)
            if stat.st_mtime < child.timestamp.timestamp():
                to_download.append(child)

    return to_download

def download_file(download, data_dir):
    print(download.path())
    resp = requests.get(f"http://ezshare.card/download?file={download.download_key}", stream=True)
    path = Path(os.path.join(data_dir, download.path()))    
    tmp_path = path.with_suffix(".tmp")

    path.parent.mkdir(parents=True, exist_ok=True)

    with open(tmp_path, "wb+") as f:
        for chunk in resp.iter_content(chunk_size=128):
            f.write(chunk)

    os.rename(tmp_path, path)

def sync_data():
    data_dir = os.environ.get("DATA_DIR", "/data")

    print("Scanning card...")
    root = Directory(name='.')
    parse_listing(root, "A:")

    to_download = find_downloads(root, data_dir)

    if len(to_download) > 0:
        print(f"Downloading {len(to_download)} files...")
        for download in to_download:
            download_file(download, data_dir)

def main():
    while True:
        sync_data()
        print("Waiting for 1 hour...")
        time.sleep(60*60)

if __name__ == "__main__":
    main()
