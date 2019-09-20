import functools
import urllib.parse
import random

from flask import (
    app, abort, Blueprint, flash, jsonify, g, redirect, session, url_for
)

@app.route("/login")
def login():
    if "user_id" not in session:
        session["user_id"] = random.getrandbits(128)

    return jsonify({
        id: session["user_id"]
    })


@app.before_app_request
def load_logged_in_user():
    g.user = session.get("user_id")


def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if "user_id" not in session:
            return redirect(url_for("login"))

        return view(**kwargs)

    return wrapped_view
