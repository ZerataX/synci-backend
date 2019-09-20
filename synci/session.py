import random
import time

from flask import (
    Blueprint, g, jsonify
)
from synci.auth import login_required

bp = Blueprint("session", __name__, url_prefix="/session")
sessions = []


class Session:
    def __init__(self, name, host):
        self.name = name
        self.host = host
        self.followers = set()
        self.time = -1
        self.duration = -1
        self.media = None

    def json(self):
        result = {
            "host": str(self.host),
            "media": self.media.json() if self.media else None,
            "time": self.time,
            "duration": self.duration
        }
        return result

    def __str__(self):
        return self.name


class User:
    def __init__(self, id, name, image, href):
        self.id = id
        self.name = name
        self.image = image
        self.href = href
    
    def json(self):
        result = {
            "id": id,
            "name": name,
            "image": image,
            "href": href
        }
        return result


class Media:
    def __init__(self, uri, mediaType, props = {}):
        self.uri = uri
        self.mediaType = mediaType
        self.props = props
    
    def json(self):
        result = {
            "uri": uri,
            "type": self.mediaType,
            **self.props
        }
        return result

def get_session(name):
    for session in sessions:
        if name == session.name:
            return session
