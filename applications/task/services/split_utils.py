"""
合作艺人拆分 & 重复文件检测
"""
import os
from collections import defaultdict

import music_tag


def split_artists(file_path, separator='/'):
    """
    拆分文件中的合作艺人为多个独立艺人
    例如: "王力宏/毛不易" -> ["王力宏", "毛不易"]
    返回: (success, original_artist, split_artists)
    """
    try:
        f = music_tag.load_file(file_path)
    except Exception as e:
        return False, str(e), []

    artist = f["artist"].value or ""
    if not artist:
        return False, "艺术家标签为空", []

    # 检查是否包含分隔符
    # 支持多种分隔符: / & 、 feat. ft. x
    separators = [separator, '&', '、', ' feat. ', ' feat ', ' ft. ', ' ft ', ' x ']
    artists = [artist]
    for sep in separators:
        if sep in artist:
            artists = [a.strip() for a in artist.split(sep) if a.strip()]
            break

    if len(artists) <= 1:
        return False, f"未检测到合作艺人（当前: {artist}）", []

    # 设置多个艺术家
    try:
        f.set("artist", artists)
        f.save()
        return True, artist, artists
    except Exception as e:
        return False, f"保存失败: {e}", []


def batch_split_artists(file_paths, separator='/'):
    """
    批量拆分合作艺人
    返回: results列表, 每项包含 {path, success, original, artists, error}
    """
    results = []
    for file_path in file_paths:
        if not os.path.exists(file_path):
            results.append({
                "path": file_path,
                "success": False,
                "error": "文件不存在",
                "original": "",
                "artists": [],
            })
            continue

        success, original_or_error, artists = split_artists(file_path, separator)
        results.append({
            "path": file_path,
            "success": success,
            "original": original_or_error if not success else original_or_error,
            "artists": artists,
            "error": original_or_error if not success else "",
        })

    return results


def find_duplicate_songs(file_paths):
    """
    检测重复歌曲
    按 (title, artist) 分组，返回有重复的组
    返回: duplicates列表, 每项包含 {title, artist, count, files}
    """
    # 按 (title, artist) 分组
    groups = defaultdict(list)

    for file_path in file_paths:
        if not os.path.exists(file_path):
            continue
        try:
            f = music_tag.load_file(file_path)
        except Exception:
            continue

        title = (f["title"].value or "").strip()
        artist = (f["artist"].value or "").strip()
        album = (f["album"].value or "").strip()

        if not title:
            # 用文件名作为标题
            title = os.path.basename(file_path).rsplit('.', 1)[0]

        # 规范化用于匹配
        key = (title.lower(), artist.lower())
        groups[key].append({
            "path": file_path,
            "title": title,
            "artist": artist,
            "album": album,
            "size": os.path.getsize(file_path),
            "suffix": file_path.rsplit('.', 1)[-1].lower() if '.' in file_path else '',
        })

    # 筛选出有重复的组
    duplicates = []
    for (title_key, artist_key), files in groups.items():
        if len(files) > 1:
            # 按路径排序
            files.sort(key=lambda x: x["path"])
            duplicates.append({
                "title": files[0]["title"],
                "artist": files[0]["artist"],
                "count": len(files),
                "files": files,
            })

    # 按重复数量降序排列
    duplicates.sort(key=lambda x: x["count"], reverse=True)
    return duplicates
