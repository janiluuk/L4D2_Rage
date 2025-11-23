"""
Download every track for an album from downloads.khinsider.com.

By default this script targets the DOOM/DOOM II gamerip album and grabs MP4 files
into the local music directory. Run with -h for options.
"""
import argparse
import pathlib
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser

AUDIO_EXTS = (".mp4", ".mp3", ".flac", ".ogg", ".m4a")
DEFAULT_ALBUM = "https://downloads.khinsider.com/game-soundtracks/album/doom-doom-ii-ps4-ps5-switch-windows-xbox-one-xbox-series-xs-gamerip-1995"
USER_AGENT = "khinsider-downloader/1.0"


def fetch(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Referer": url})
    with urllib.request.urlopen(request) as response:
        return response.read().decode("utf-8", errors="replace")


class TrackListParser(HTMLParser):
    def __init__(self, album_path: str):
        super().__init__()
        self.album_path = album_path
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        href = dict(attrs).get("href")
        if not href:
            return
        if not href.startswith(self.album_path):
            return
        lowered = href.lower()
        if not lowered.endswith(AUDIO_EXTS):
            return
        if href not in self.links:
            self.links.append(href)


class DownloadLinkParser(HTMLParser):
    def __init__(self, preferred_ext: str):
        super().__init__()
        self.preferred_ext = preferred_ext.lower()
        self.fallback = None
        self.download_url = None

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        href = dict(attrs).get("href")
        if not href:
            return
        lowered = href.lower()
        if lowered.endswith(self.preferred_ext):
            self.download_url = href
        elif lowered.endswith(AUDIO_EXTS) and not self.fallback:
            self.fallback = href


def discover_track_pages(album_url: str) -> list[str]:
    parsed_album = urllib.parse.urlparse(album_url)
    album_path = parsed_album.path
    parser = TrackListParser(album_path)
    parser.feed(fetch(album_url))
    pages = []
    for href in parser.links:
        pages.append(urllib.parse.urljoin(album_url, href))
    return pages


def discover_download_link(track_page: str, preferred_ext: str) -> str | None:
    parser = DownloadLinkParser(preferred_ext)
    parser.feed(fetch(track_page))
    chosen = parser.download_url or parser.fallback
    if chosen:
        return urllib.parse.urljoin(track_page, chosen)
    return None


def download_file(url: str, output_dir: pathlib.Path) -> pathlib.Path:
    filename = pathlib.Path(urllib.parse.urlparse(url).path).name
    target = output_dir / filename
    target.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Referer": url})
    with urllib.request.urlopen(request) as response, target.open("wb") as outfile:
        outfile.write(response.read())
    return target


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Download soundtrack files from downloads.khinsider.com")
    parser.add_argument("album_url", nargs="?", default=DEFAULT_ALBUM, help="Album page URL to fetch")
    parser.add_argument("--ext", dest="ext", default=".mp4", help="Preferred audio extension (default: .mp4)")
    parser.add_argument("--out", dest="out", default=".", help="Output directory for downloaded files")
    args = parser.parse_args(argv)

    album_url = args.album_url
    preferred_ext = args.ext if args.ext.startswith(".") else f".{args.ext}"
    output_dir = pathlib.Path(args.out)

    print(f"Discovering tracks from {album_url} ...")
    track_pages = discover_track_pages(album_url)
    if not track_pages:
        print("No track pages found; check the album URL.")
        return 1

    print(f"Found {len(track_pages)} tracks. Fetching download links (preferring {preferred_ext})...")
    downloaded = 0
    for track_page in track_pages:
        link = discover_download_link(track_page, preferred_ext)
        if not link:
            print(f"  [skip] {track_page} (no downloadable link found)")
            continue
        path = download_file(link, output_dir)
        print(f"  [ok] {path.name}")
        downloaded += 1

    print(f"Finished. Downloaded {downloaded} file(s) into {output_dir.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
